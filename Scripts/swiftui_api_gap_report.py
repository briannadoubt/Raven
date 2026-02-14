#!/usr/bin/env python3
"""Generate a deterministic SwiftUI API inventory and Raven parity gap report.

This script uses Apple SDK metadata (`swift-api-digester`) as the canonical source for
SwiftUI's public API, then compares that inventory against Raven's public declarations.

Outputs:
- swiftui_inventory.json
- raven_inventory.json
- gap_report.json
- gap_report.md
"""

from __future__ import annotations

import argparse
import dataclasses
import json
import pathlib
import re
import subprocess
import sys
import tempfile
from collections import Counter
from collections import deque
from datetime import datetime, timezone
from typing import Any


TYPE_DECL_KINDS = {"Struct", "Class", "Enum", "Protocol", "TypeAlias"}
API_DECL_KINDS = {"Func", "Var", "Subscript", "Constructor", "Macro"}
TARGET_DECL_KINDS = TYPE_DECL_KINDS | API_DECL_KINDS
SCORABLE_DECL_KINDS = TARGET_DECL_KINDS

NOISE_TYPEALIASES = {
    "Body",
    "AnimatableData",
    "ArrayLiteralElement",
    "RawValue",
    "Element",
    "Iterator",
    "AllCases",
}

NOISE_MEMBERS = {
    "body",
    "hash",
    "hashValue",
    "rawValue",
}


@dataclasses.dataclass(frozen=True)
class SwiftUISymbol:
    usr: str
    decl_kind: str
    name: str
    printed_name: str
    module_name: str
    path: tuple[str, ...]


def owner_context(sym: SwiftUISymbol) -> str:
    # Path contains nested context from digester root down to symbol.
    # The owner is typically the declaration just before the symbol name.
    if len(sym.path) >= 2:
        return sym.path[-2]
    return sym.module_name


def is_named_api(sym: SwiftUISymbol) -> bool:
    # Keep identifiers that are easy to map to implementation tasks.
    return bool(re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", sym.name))


def qualified_member(owner: str, member: str) -> str:
    return f"{owner}.{member}" if owner else member


def is_actionable_symbol(sym: SwiftUISymbol) -> bool:
    """Exclude known noisy protocol/synthesis symbols from parity scoring."""
    if sym.decl_kind not in SCORABLE_DECL_KINDS:
        return False
    if sym.decl_kind == "TypeAlias" and sym.name in NOISE_TYPEALIASES:
        return False
    if sym.decl_kind in {"Func", "Var"} and sym.name in NOISE_MEMBERS:
        return False
    # Operator-like overloads are rarely actionable in parity planning.
    if sym.decl_kind == "Func" and not is_named_api(sym):
        return False
    return True


def run(cmd: list[str], cwd: pathlib.Path | None = None) -> str:
    proc = subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        text=True,
        capture_output=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"Command failed ({proc.returncode}): {' '.join(cmd)}\n"
            f"stdout:\n{proc.stdout}\n"
            f"stderr:\n{proc.stderr}"
        )
    return proc.stdout.strip()


def detect_sdk(sdk: str) -> tuple[str, str]:
    sdk_path = run(["xcrun", "--show-sdk-path", "--sdk", sdk])
    sdk_version = run(["xcrun", "--show-sdk-version", "--sdk", sdk])
    return sdk_path, sdk_version


def normalize_version(version: str) -> str:
    # Keep major.minor for stable target triples
    m = re.match(r"^(\d+)(?:\.(\d+))?", version.strip())
    if not m:
        return "18.0"
    major = m.group(1)
    minor = m.group(2) or "0"
    return f"{major}.{minor}"


def infer_target(sdk: str, sdk_version: str) -> str:
    version = normalize_version(sdk_version)
    if sdk == "iphoneos":
        return f"arm64-apple-ios{version}"
    if sdk == "iphonesimulator":
        return f"arm64-apple-ios{version}-simulator"
    if sdk == "appletvos":
        return f"arm64-apple-tvos{version}"
    if sdk == "watchos":
        return f"arm64-apple-watchos{version}"
    if sdk == "xros":
        return f"arm64-apple-xros{version}"
    return f"arm64-apple-ios{version}"


def dump_swiftui_api(sdk: str, target: str, out_file: pathlib.Path) -> None:
    sdk_path, _ = detect_sdk(sdk)
    module_cache_dir = pathlib.Path(tempfile.mkdtemp(prefix="swiftui-digester-cache-"))
    cmd = [
        "swift-api-digester",
        "-dump-sdk",
        "-module",
        "SwiftUI",
        "-sdk",
        sdk_path,
        "-target",
        target,
        "-module-cache-path",
        str(module_cache_dir),
        "-o",
        str(out_file),
    ]
    run(cmd)


def walk_swiftui_nodes(node: dict[str, Any], parents: tuple[str, ...] = ()):
    name = node.get("name", "")
    next_parents = parents
    if name:
        next_parents = parents + (name,)

    decl_kind = node.get("declKind")
    if decl_kind in TARGET_DECL_KINDS:
        usr = node.get("usr") or ""
        if usr and not name.startswith("_"):
            # Filter most SPI/internal-ish declarations by convention.
            if "._" not in ".".join(next_parents):
                yield SwiftUISymbol(
                    usr=usr,
                    decl_kind=decl_kind,
                    name=name,
                    printed_name=node.get("printedName", name),
                    module_name=node.get("moduleName", "SwiftUI"),
                    path=next_parents,
                )

    for child in node.get("children", []):
        yield from walk_swiftui_nodes(child, next_parents)


def load_swiftui_symbols(swiftui_json: pathlib.Path) -> list[SwiftUISymbol]:
    data = json.loads(swiftui_json.read_text())
    root = data.get("ABIRoot")
    if not isinstance(root, dict):
        raise RuntimeError(f"Unexpected digester JSON shape in {swiftui_json}")

    symbols: dict[str, SwiftUISymbol] = {}
    for sym in walk_swiftui_nodes(root):
        symbols[sym.usr] = sym
    return sorted(symbols.values(), key=lambda s: (s.decl_kind, s.name, s.usr))


def extract_manifest_call_bodies(manifest: str, call_name: str) -> list[str]:
    pattern = re.compile(rf"\.{re.escape(call_name)}\s*\(")
    bodies: list[str] = []

    for match in pattern.finditer(manifest):
        open_paren = manifest.find("(", match.start())
        if open_paren == -1:
            continue

        depth = 1
        i = open_paren + 1
        in_string = False
        escaping = False
        while i < len(manifest):
            ch = manifest[i]
            if in_string:
                if escaping:
                    escaping = False
                elif ch == "\\":
                    escaping = True
                elif ch == '"':
                    in_string = False
            else:
                if ch == '"':
                    in_string = True
                elif ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0:
                        bodies.append(manifest[open_paren + 1 : i])
                        break
            i += 1

    return bodies


def parse_target_manifest(repo_root: pathlib.Path) -> dict[str, dict[str, Any]]:
    package_swift = repo_root / "Package.swift"
    if not package_swift.exists():
        return {}

    manifest = package_swift.read_text(encoding="utf-8")
    entries: dict[str, dict[str, Any]] = {}
    call_kinds = ("target", "executableTarget", "testTarget", "macro")

    for kind in call_kinds:
        for body in extract_manifest_call_bodies(manifest, kind):
            name_match = re.search(r'\bname\s*:\s*"([^"]+)"', body)
            if not name_match:
                continue
            name = name_match.group(1)

            path_match = re.search(r'\bpath\s*:\s*"([^"]+)"', body)
            path = path_match.group(1) if path_match else f"Sources/{name}"

            deps: list[str] = []
            deps_match = re.search(r"\bdependencies\s*:\s*\[(.*?)\]", body, flags=re.DOTALL)
            if deps_match:
                deps = re.findall(r'"([^"]+)"', deps_match.group(1))

            entries[name] = {
                "kind": kind,
                "path": path,
                "dependencies": deps,
            }

    return entries


def discover_scannable_target_names(repo_root: pathlib.Path, targets: dict[str, dict[str, Any]]) -> list[str]:
    package_swift = repo_root / "Package.swift"
    if not package_swift.exists():
        return sorted(name for name, meta in targets.items() if meta["kind"] == "target")

    manifest = package_swift.read_text(encoding="utf-8")
    initial: list[str] = []
    for body in extract_manifest_call_bodies(manifest, "library"):
        target_list_match = re.search(r"\btargets\s*:\s*\[(.*?)\]", body, flags=re.DOTALL)
        if not target_list_match:
            continue
        initial.extend(re.findall(r'"([^"]+)"', target_list_match.group(1)))

    if not initial:
        return sorted(name for name, meta in targets.items() if meta["kind"] == "target")

    included: set[str] = set()
    queue: deque[str] = deque(initial)
    while queue:
        name = queue.popleft()
        meta = targets.get(name)
        if not meta or meta["kind"] != "target" or name in included:
            continue
        included.add(name)
        for dep in meta["dependencies"]:
            if dep in targets and targets[dep]["kind"] == "target":
                queue.append(dep)

    return sorted(included)


def scan_raven_sources(root: pathlib.Path) -> dict[str, Any]:
    public_type_pat = re.compile(r"\bpublic\s+(?:final\s+)?(?:struct|class|enum|protocol|actor|typealias)\s+([A-Za-z_][A-Za-z0-9_]*)")
    type_or_extension_pat = re.compile(r"\b((?:public\s+)?(?:final\s+)?(?:struct|class|enum|protocol|actor|extension))\s+([A-Za-z_][A-Za-z0-9_]*)")
    public_typealias_pat = re.compile(r"\bpublic\s+typealias\s+([A-Za-z_][A-Za-z0-9_]*)\b")
    # Capture public function names regardless of generic clauses or multiline parameter lists.
    func_pat = re.compile(r"\bpublic\s+(?:static\s+|class\s+|mutating\s+|nonmutating\s+|override\s+|convenience\s+|required\s+|final\s+)*func\s+`?([A-Za-z_][A-Za-z0-9_]*)`?\b")
    protocol_func_pat = re.compile(r"\b(?:static\s+|class\s+|mutating\s+|nonmutating\s+)*func\s+`?([A-Za-z_][A-Za-z0-9_]*)`?\b")
    var_pat = re.compile(r"\bpublic\s+(?:static\s+|class\s+|private\(set\)\s+|internal\(set\)\s+)*var\s+`?([A-Za-z_][A-Za-z0-9_]*)`?\b")
    let_pat = re.compile(r"\bpublic\s+(?:static\s+|class\s+)*let\s+`?([A-Za-z_][A-Za-z0-9_]*)`?\b")
    protocol_var_pat = re.compile(r"\b(?:static\s+|class\s+)?var\s+`?([A-Za-z_][A-Za-z0-9_]*)`?\s*:")
    enum_case_pat = re.compile(r"^\s*(?:public\s+)?(?:indirect\s+)?case\s+(.+)$")
    subscript_pat = re.compile(r"\bpublic\s+(?:static\s+|class\s+|final\s+)*subscript\b")
    init_pat = re.compile(r"\bpublic\s+(?:convenience\s+|required\s+|override\s+)*init\b")

    type_names: set[str] = set()
    qualified_type_names: set[str] = set()
    func_names: set[str] = set()
    var_names: set[str] = set()
    qualified_func_names: set[str] = set()
    qualified_var_names: set[str] = set()
    constructor_owners: set[str] = set()

    def owner_from_stack(stack: list[tuple[str, int, bool, bool]]) -> str:
        if not stack:
            return ""
        return ".".join(name for name, _, _, _ in stack)

    targets = parse_target_manifest(root)
    target_names = discover_scannable_target_names(root, targets)
    source_roots = [root / targets[name]["path"] for name in target_names if name in targets]
    source_roots = sorted(path for path in source_roots if path.exists())

    if not source_roots:
        fallback = root / "Sources" / "RavenCore"
        if fallback.exists():
            source_roots = [fallback]

    swift_files: list[pathlib.Path] = []
    seen_files: set[pathlib.Path] = set()
    for source_root in source_roots:
        for swift_file in source_root.rglob("*.swift"):
            resolved = swift_file.resolve()
            if resolved not in seen_files:
                seen_files.add(resolved)
                swift_files.append(swift_file)

    for swift_file in sorted(swift_files):
        text = swift_file.read_text(encoding="utf-8")
        lines = text.splitlines()

        # Track type/extension lexical scopes with brace depth.
        brace_depth = 0
        type_stack: list[tuple[str, int, bool, bool]] = []
        pending_scope_name: str | None = None
        pending_scope_is_public_type = False
        pending_scope_is_public_protocol = False
        pending_scope_is_public_enum = False

        for raw_line in lines:
            line = raw_line.split("//", 1)[0]
            # Normalize away leading attributes (e.g. `@MainActor public func ...`),
            # since our declaration regexes operate on the remaining tokens.
            line = re.sub(r"^\s*(?:@\w+(?:\([^)]*\))?\s*)+", "", line)

            # Track declaration-scoped owner context.
            decl = type_or_extension_pat.search(line)
            if decl:
                decl_head = decl.group(1)
                scope_name = decl.group(2)
                is_public_type = public_type_pat.search(line) is not None
                is_public_protocol = bool(re.search(r"\bpublic\s+protocol\b", decl_head))
                is_public_enum = bool(re.search(r"\bpublic\s+enum\b", decl_head))
                if "{" in line:
                    future_depth = brace_depth + line.count("{") - line.count("}")
                    if future_depth > brace_depth:
                        type_stack.append((scope_name, future_depth, is_public_protocol, is_public_enum))
                    if is_public_type and not scope_name.startswith("_"):
                        type_names.add(scope_name)
                        qualified_type_names.add(owner_from_stack(type_stack))
                    pending_scope_name = None
                    pending_scope_is_public_type = False
                    pending_scope_is_public_protocol = False
                    pending_scope_is_public_enum = False
                else:
                    pending_scope_name = scope_name
                    pending_scope_is_public_type = is_public_type
                    pending_scope_is_public_protocol = is_public_protocol
                    pending_scope_is_public_enum = is_public_enum

            owner = owner_from_stack(type_stack)
            in_public_protocol = bool(type_stack and type_stack[-1][2])
            in_public_enum = bool(type_stack and type_stack[-1][3])

            # `typealias` declarations are not lexical scopes, so capture them explicitly.
            # This ensures nested aliases like `DatePicker.Components` are represented.
            for m in public_typealias_pat.finditer(line):
                name = m.group(1)
                if not name.startswith("_"):
                    type_names.add(name)
                    if owner:
                        qualified_type_names.add(qualified_member(owner, name))

            for m in func_pat.finditer(line):
                name = m.group(1)
                if not name.startswith("_"):
                    func_names.add(name)
                    qualified_func_names.add(qualified_member(owner or "GLOBAL", name))
            if in_public_protocol:
                for m in protocol_func_pat.finditer(line):
                    name = m.group(1)
                    if not name.startswith("_"):
                        func_names.add(name)
                        qualified_func_names.add(qualified_member(owner or "GLOBAL", name))

            for m in var_pat.finditer(line):
                name = m.group(1)
                if not name.startswith("_"):
                    var_names.add(name)
                    qualified_var_names.add(qualified_member(owner or "GLOBAL", name))
            for m in let_pat.finditer(line):
                name = m.group(1)
                if not name.startswith("_"):
                    var_names.add(name)
                    qualified_var_names.add(qualified_member(owner or "GLOBAL", name))
            if in_public_protocol:
                for m in protocol_var_pat.finditer(line):
                    name = m.group(1)
                    if not name.startswith("_"):
                        var_names.add(name)
                        qualified_var_names.add(qualified_member(owner or "GLOBAL", name))
            if in_public_enum:
                enum_case_match = enum_case_pat.search(line)
                if enum_case_match:
                    case_clause = enum_case_match.group(1)
                    for piece in case_clause.split(","):
                        candidate = piece.strip()
                        if candidate.startswith("indirect "):
                            candidate = candidate[len("indirect "):].strip()
                        m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)", candidate)
                        if m:
                            name = m.group(1)
                            if not name.startswith("_"):
                                var_names.add(name)
                                qualified_var_names.add(qualified_member(owner or "GLOBAL", name))

            if init_pat.search(line) and owner:
                constructor_owners.add(owner)

            opens = line.count("{")
            closes = line.count("}")

            if pending_scope_name and opens > 0:
                future_depth = brace_depth + opens - closes
                if future_depth > brace_depth:
                    type_stack.append((pending_scope_name, future_depth, pending_scope_is_public_protocol, pending_scope_is_public_enum))
                if pending_scope_is_public_type and not pending_scope_name.startswith("_"):
                    type_names.add(pending_scope_name)
                    qualified_type_names.add(owner_from_stack(type_stack))
                pending_scope_name = None
                pending_scope_is_public_type = False
                pending_scope_is_public_protocol = False
                pending_scope_is_public_enum = False

            brace_depth += opens - closes
            while type_stack and brace_depth < type_stack[-1][1]:
                type_stack.pop()

            if subscript_pat.search(line):
                var_names.add("subscript")
                qualified_var_names.add(qualified_member(owner or "GLOBAL", "subscript"))

    return {
        "scanned_targets": target_names,
        "source_roots": [str(path.relative_to(root)) for path in source_roots],
        "swift_file_count": len(swift_files),
        "type_names": sorted(type_names),
        "qualified_type_names": sorted(qualified_type_names),
        "func_names": sorted(func_names),
        "var_names": sorted(var_names),
        "qualified_func_names": sorted(qualified_func_names),
        "qualified_var_names": sorted(qualified_var_names),
        "constructor_owners": sorted(constructor_owners),
    }


def owner_match_candidates(owner: str) -> list[str]:
    """Return owner candidates for matching extension methods that project through wrappers."""
    candidates = [owner]
    # SwiftUI often reports extension methods on ModifiedContent/TabContent that are
    # effectively surfaced from View extensions.
    owner_aliases: dict[str, tuple[str, ...]] = {
        "ModifiedContent": ("View",),
        "TabContent": ("View",),
    }
    candidates.extend(owner_aliases.get(owner, ()))
    return candidates


def should_allow_name_only_fallback(sym: SwiftUISymbol, owner: str) -> bool:
    """Allow name-only fallback only for global-ish APIs, not all member APIs."""
    global_owners = {"", "GLOBAL", "SwiftUI", sym.module_name}
    return owner in global_owners


def is_component_candidate_type(sym: SwiftUISymbol, owner: str) -> bool:
    """Heuristic filter for top-level SwiftUI component-like types."""
    if sym.decl_kind not in {"Struct", "Class", "Protocol"}:
        return False
    if owner not in {"SwiftUI", sym.module_name}:
        return False
    if not sym.name or not sym.name[0].isupper() or sym.name.startswith("_"):
        return False

    suffixes = (
        "View",
        "Button",
        "Picker",
        "Field",
        "Editor",
        "Stack",
        "Grid",
        "List",
        "Form",
        "Section",
        "Group",
        "Link",
        "Toggle",
        "Slider",
        "Gauge",
        "Divider",
        "Label",
        "Menu",
        "Sheet",
        "Alert",
        "Dialog",
        "Popover",
        "Tab",
        "Navigation",
        "ScrollView",
        "Table",
    )
    exact = {
        "Text",
        "Image",
        "Color",
        "Spacer",
        "Canvas",
        "AnyView",
        "EmptyView",
        "ForEach",
        "Group",
        "Section",
        "TimelineView",
        "GeometryReader",
    }
    return sym.name in exact or sym.name.endswith(suffixes)


def match_symbol(sym: SwiftUISymbol, raven: dict[str, Any]) -> bool | None:
    if not is_actionable_symbol(sym):
        return None
    owner = owner_context(sym)
    if sym.decl_kind in TYPE_DECL_KINDS:
        if owner and owner not in {"SwiftUI", sym.module_name}:
            qualified = qualified_member(owner, sym.name)
            if qualified in raven["qualified_type_names"]:
                return True
        return sym.name in raven["type_names"]
    if sym.decl_kind == "Func" or sym.decl_kind == "Macro":
        for candidate_owner in owner_match_candidates(owner or "GLOBAL"):
            qualified = qualified_member(candidate_owner, sym.name)
            if qualified in raven["qualified_func_names"]:
                return True
        if should_allow_name_only_fallback(sym, owner):
            return sym.name in raven["func_names"]
        return False
    if sym.decl_kind == "Var" or sym.decl_kind == "Subscript":
        for candidate_owner in owner_match_candidates(owner or "GLOBAL"):
            qualified = qualified_member(candidate_owner, sym.name)
            if qualified in raven["qualified_var_names"]:
                return True
        if should_allow_name_only_fallback(sym, owner):
            return sym.name in raven["var_names"]
        return False
    if sym.decl_kind == "Constructor":
        # Constructor parity is tracked per owning type context.
        return owner in raven["constructor_owners"]
    return False


def write_json(path: pathlib.Path, payload: Any) -> None:
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def build_report(
    swiftui_symbols: list[SwiftUISymbol],
    raven: dict[str, Any],
    sdk: str,
    target: str,
) -> dict[str, Any]:
    matched: list[SwiftUISymbol] = []
    missing: list[SwiftUISymbol] = []
    skipped: list[SwiftUISymbol] = []

    for sym in swiftui_symbols:
        result = match_symbol(sym, raven)
        if result is None:
            skipped.append(sym)
        elif result:
            matched.append(sym)
        else:
            missing.append(sym)

    by_kind_total = Counter(sym.decl_kind for sym in swiftui_symbols)
    by_kind_missing = Counter(sym.decl_kind for sym in missing)
    by_kind_skipped = Counter(sym.decl_kind for sym in skipped)
    scoreable_total = len(swiftui_symbols) - len(skipped)

    # High-signal list: public type-like symbols likely to be user-facing components.
    # Deduplicate by (name, decl kind, owner) to avoid noisy repeats with same short names.
    type_seen: set[tuple[str, str, str]] = set()
    missing_types: list[dict[str, str]] = []
    for s in missing:
        if s.decl_kind not in TYPE_DECL_KINDS:
            continue
        if not s.name or not s.name[0].isupper() or s.name.startswith("_"):
            continue
        owner = owner_context(s)
        key = (s.name, s.decl_kind, owner)
        if key in type_seen:
            continue
        type_seen.add(key)
        missing_types.append(
            {
                "name": s.name,
                "printed_name": s.printed_name,
                "decl_kind": s.decl_kind,
                "owner": owner,
                "usr": s.usr,
            }
        )
    missing_types.sort(key=lambda x: (x["name"], x["owner"], x["decl_kind"]))

    # Actionable API list: named funcs/vars/subscripts only (operator overloads excluded).
    api_seen: set[tuple[str, str, str, str]] = set()
    missing_apis_actionable: list[dict[str, str]] = []
    operator_like: list[SwiftUISymbol] = []
    for s in missing:
        if s.decl_kind not in {"Func", "Var", "Subscript"}:
            continue
        if is_named_api(s):
            owner = owner_context(s)
            key = (s.name, s.printed_name, s.decl_kind, owner)
            if key in api_seen:
                continue
            api_seen.add(key)
            missing_apis_actionable.append(
                {
                    "name": s.name,
                    "printed_name": s.printed_name,
                    "decl_kind": s.decl_kind,
                    "owner": owner,
                    "usr": s.usr,
                }
            )
        else:
            operator_like.append(s)
    missing_apis_actionable.sort(key=lambda x: (x["name"], x["owner"], x["printed_name"]))

    missing_components: list[dict[str, str]] = []
    component_seen: set[tuple[str, str, str]] = set()
    for s in missing:
        owner = owner_context(s)
        if not is_component_candidate_type(s, owner):
            continue
        key = (s.name, s.decl_kind, owner)
        if key in component_seen:
            continue
        component_seen.add(key)
        missing_components.append(
            {
                "name": s.name,
                "printed_name": s.printed_name,
                "decl_kind": s.decl_kind,
                "owner": owner,
                "usr": s.usr,
            }
        )
    missing_components.sort(key=lambda x: (x["name"], x["owner"], x["decl_kind"]))

    op_counts = Counter(s.printed_name for s in operator_like)
    operator_like_top = [
        {"signature": sig, "count": count}
        for sig, count in sorted(op_counts.items(), key=lambda item: (-item[1], item[0]))[:50]
    ]

    return {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "source_of_truth": {
            "swiftui_module": "SwiftUI",
            "extraction_tool": "swift-api-digester",
            "sdk": sdk,
            "target": target,
            "matching_note": "Name-based parity check (types/functions/properties) against Raven public declarations.",
            "matching_note_detail": "Member matching prefers owner-qualified keys (e.g., Type.func, Type.var, Type.init) with name-only fallback for globals/extensions.",
        },
        "summary": {
            "swiftui_symbol_count": len(swiftui_symbols),
            "scoreable_symbol_count": scoreable_total,
            "skipped_symbol_count": len(skipped),
            "matched_symbol_count": len(matched),
            "missing_symbol_count": len(missing),
            "coverage_percent": round((len(matched) / max(1, scoreable_total)) * 100, 2),
            "by_decl_kind_total": dict(sorted(by_kind_total.items())),
            "by_decl_kind_missing": dict(sorted(by_kind_missing.items())),
            "by_decl_kind_skipped": dict(sorted(by_kind_skipped.items())),
        },
        "missing": {
            "components_high_signal": missing_components,
            "types_high_signal": missing_types,
            "apis_high_signal": missing_apis_actionable,
            "operator_like": {
                "count": len(operator_like),
                "top_signatures": operator_like_top,
            },
            "all": [
                {
                    "decl_kind": s.decl_kind,
                    "name": s.name,
                    "printed_name": s.printed_name,
                    "usr": s.usr,
                    "module_name": s.module_name,
                    "path": list(s.path),
                }
                for s in missing
            ],
        },
    }


def write_markdown(report: dict[str, Any], out_path: pathlib.Path) -> None:
    summary = report["summary"]
    missing_components = report["missing"]["components_high_signal"]
    missing_types = report["missing"]["types_high_signal"]
    missing_apis = report["missing"]["apis_high_signal"]
    operator_like = report["missing"]["operator_like"]
    src = report["source_of_truth"]

    lines: list[str] = []
    lines.append("# SwiftUI API Gap Report")
    lines.append("")
    lines.append(f"Generated: `{report['generated_at_utc']}`")
    lines.append(f"Source module: `{src['swiftui_module']}` via `{src['extraction_tool']}`")
    lines.append(f"SDK: `{src['sdk']}`")
    lines.append(f"Target: `{src['target']}`")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append(f"- SwiftUI symbols analyzed: **{summary['swiftui_symbol_count']}**")
    lines.append(f"- Scoreable symbols: **{summary['scoreable_symbol_count']}**")
    lines.append(f"- Skipped symbols (currently unscored): **{summary['skipped_symbol_count']}**")
    lines.append(f"- Matched by Raven: **{summary['matched_symbol_count']}**")
    lines.append(f"- Missing in Raven: **{summary['missing_symbol_count']}**")
    lines.append(f"- Name-based coverage: **{summary['coverage_percent']}%**")
    lines.append("")
    lines.append("### Missing by Declaration Kind")
    lines.append("")
    lines.append("| Decl Kind | Missing | Skipped | Total |")
    lines.append("| --- | ---: | ---: | ---: |")

    for kind, total in summary["by_decl_kind_total"].items():
        miss = summary["by_decl_kind_missing"].get(kind, 0)
        skipped = summary["by_decl_kind_skipped"].get(kind, 0)
        lines.append(f"| `{kind}` | {miss} | {skipped} | {total} |")

    lines.append("")
    lines.append("## Missing High-Signal UI Components (first 200)")
    lines.append("")
    for item in missing_components[:200]:
        lines.append(f"- `{item['name']}` ({item['decl_kind']}, owner: `{item['owner']}`)")

    lines.append("")
    lines.append("## Missing High-Signal Types (first 200)")
    lines.append("")
    for item in missing_types[:200]:
        lines.append(f"- `{item['name']}` ({item['decl_kind']}, owner: `{item['owner']}`)")

    lines.append("")
    lines.append("## Missing High-Signal Named APIs (first 300)")
    lines.append("")
    for item in missing_apis[:300]:
        lines.append(f"- `{item['printed_name']}` (owner: `{item['owner']}`)")

    lines.append("")
    lines.append("## Operator-Like API Gap Summary")
    lines.append("")
    lines.append(f"- Total operator-like missing APIs: **{operator_like['count']}**")
    lines.append("")
    lines.append("### Top Operator-Like Signatures (first 50)")
    lines.append("")
    for item in operator_like["top_signatures"][:50]:
        lines.append(f"- `{item['signature']}` (x{item['count']})")

    lines.append("")
    lines.append("## Notes")
    lines.append("")
    lines.append(f"- {src['matching_note']}")
    lines.append(f"- {src['matching_note_detail']}")
    lines.append("- This report is deterministic for a given Xcode + SDK version and target triple.")

    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".", help="Path to repository root")
    parser.add_argument("--sdk", default="iphoneos", help="Apple SDK identifier (default: iphoneos)")
    parser.add_argument("--target", default="", help="Swift target triple; auto-derived if omitted")
    parser.add_argument(
        "--output-dir",
        default="Reports/swiftui-api-gap",
        help="Directory for report artifacts",
    )
    parser.add_argument(
        "--swiftui-json",
        default="",
        help="Use an existing swift-api-digester JSON dump instead of extracting",
    )
    args = parser.parse_args()

    repo_root = pathlib.Path(args.repo_root).resolve()
    out_dir = (repo_root / args.output_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    sdk_path, sdk_version = detect_sdk(args.sdk)
    target = args.target or infer_target(args.sdk, sdk_version)

    if args.swiftui_json:
        swiftui_json = pathlib.Path(args.swiftui_json).resolve()
        if not swiftui_json.exists():
            raise FileNotFoundError(f"Provided --swiftui-json does not exist: {swiftui_json}")
    else:
        tmp_dir = pathlib.Path(tempfile.mkdtemp(prefix="swiftui-digester-"))
        swiftui_json = tmp_dir / "SwiftUI.json"
        dump_swiftui_api(args.sdk, target, swiftui_json)

    swiftui_symbols = load_swiftui_symbols(swiftui_json)
    raven_inventory = scan_raven_sources(repo_root)

    report = build_report(swiftui_symbols, raven_inventory, sdk=args.sdk, target=target)

    swiftui_payload = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "sdk": args.sdk,
        "sdk_path": sdk_path,
        "sdk_version": sdk_version,
        "target": target,
        "symbol_count": len(swiftui_symbols),
        "symbols": [dataclasses.asdict(s) for s in swiftui_symbols],
    }

    raven_payload = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "source": "Library products + transitive target dependencies",
        **raven_inventory,
    }

    write_json(out_dir / "swiftui_inventory.json", swiftui_payload)
    write_json(out_dir / "raven_inventory.json", raven_payload)
    write_json(out_dir / "gap_report.json", report)
    write_markdown(report, out_dir / "gap_report.md")

    print(f"Wrote report artifacts to {out_dir}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        raise
