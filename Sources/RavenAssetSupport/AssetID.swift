import Foundation

/// Shared deterministic asset ID + normalization used by RavenCLI and Raven runtime.
///
/// The goal is stable, ASCII-only identifiers that can be used for file names and CSS variables.
public enum AssetID {
    /// Computes a stable ID string for the given asset name.
    ///
    /// Output format: `<slug>-<fnv64hex>` where slug is lowercase and dash-separated.
    public static func fromName(_ name: String) -> String {
        let slug = Self.slugify(name)
        let hash = Self.fnv1a64Hex(name)
        if slug.isEmpty {
            return "asset-\(hash)"
        }
        return "\(slug)-\(hash)"
    }

    /// Produces a stable slug suitable for file names and CSS variable suffixes.
    public static func slugify(_ name: String) -> String {
        // Keep ASCII alphanumerics, map whitespace/underscore/dash to a single dash, drop everything else.
        var out: [UInt8] = []
        out.reserveCapacity(name.utf8.count)

        var lastWasDash = false
        for scalar in name.unicodeScalars {
            let v = scalar.value
            let ascii: UInt8?
            switch v {
            case 0x30...0x39: ascii = UInt8(v) // 0-9
            case 0x41...0x5A: ascii = UInt8(v + 0x20) // A-Z -> a-z
            case 0x61...0x7A: ascii = UInt8(v) // a-z
            case 0x20, 0x09, 0x0A, 0x0D, 0x5F, 0x2D: ascii = 0x2D // whitespace, _, - -> -
            default: ascii = nil
            }

            guard let a = ascii else { continue }
            if a == 0x2D {
                if lastWasDash { continue }
                // Avoid leading dashes.
                if out.isEmpty { continue }
                out.append(a)
                lastWasDash = true
            } else {
                out.append(a)
                lastWasDash = false
            }
        }

        // Trim trailing dash.
        while out.last == 0x2D { out.removeLast() }

        return String(bytes: out, encoding: .utf8) ?? ""
    }

    /// Computes FNV-1a 64-bit hash of the input string and returns lowercase hex (16 chars).
    public static func fnv1a64Hex(_ input: String) -> String {
        let hash = Self.fnv1a64(input.utf8)
        return String(format: "%016llx", hash)
    }

    /// Computes FNV-1a 64-bit hash over the given bytes.
    public static func fnv1a64<S: Sequence>(_ bytes: S) -> UInt64 where S.Element == UInt8 {
        var hash: UInt64 = 0xcbf29ce484222325 // offset basis
        let prime: UInt64 = 0x100000001b3
        for b in bytes {
            hash ^= UInt64(b)
            hash &*= prime
        }
        return hash
    }
}

