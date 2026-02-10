import Foundation

/// Utility for ensuring a SwiftWasm app exports an entrypoint that Raven's generated HTML loader can invoke.
///
/// SwiftWasm SDK builds (and JavaScriptKit) typically export only a small set of symbols by default
/// (`_initialize`, `memory`, `swjs_*`). The user's `@main` entrypoint often exists in the module, but
/// isn't exported, which means the loader can't call `instance.exports.main()`.
///
/// Rather than requiring fragile linker flags (which break host-side macro plugin tooling that SwiftPM
/// may build as part of the same graph), we patch the `.wasm` export section post-link by looking up
/// the function index via the `name` custom section and injecting an export if missing.
enum WasmExportPatcher {
    struct PatchResult: Sendable {
        var addedExports: [String]
    }

    static func ensureEntrypointExports(
        at wasmURL: URL,
        exportNames: [String] = ["main", "__main_argc_argv"],
        verbose: Bool
    ) throws -> PatchResult? {
        var data = try Data(contentsOf: wasmURL)

        guard data.count >= 8, data.prefix(4) == Data([0x00, 0x61, 0x73, 0x6D]) else {
            return nil
        }

        // Find function indices for requested export names by reading the `name` custom section.
        var nameToFuncIndex: [String: UInt32] = [:]
        for exportName in exportNames {
            if let idx = try findFunctionIndex(named: exportName, in: data) {
                nameToFuncIndex[exportName] = idx
            }
        }

        // Nothing to do if none of the requested symbols exist.
        if nameToFuncIndex.isEmpty {
            return nil
        }

        guard let exportSection = try findSection(id: 7, in: data) else {
            // Unusual for our builds, but don't try to insert a whole new section right now.
            return nil
        }

        let payload = data.subdata(in: exportSection.payloadStart..<exportSection.payloadEnd)
        let (existingCount, existingEntriesStart, existingExportNames) = try parseExportSectionPayload(payload)

        var toAdd: [(name: String, index: UInt32)] = []
        for (name, idx) in nameToFuncIndex {
            if !existingExportNames.contains(name) {
                toAdd.append((name: name, index: idx))
            }
        }
        toAdd.sort { $0.name < $1.name }

        if toAdd.isEmpty {
            return nil
        }

        var newPayload = Data()
        newPayload.append(encodeULEB128(UInt32(existingCount) + UInt32(toAdd.count)))
        newPayload.append(payload.subdata(in: existingEntriesStart..<payload.count))

        for item in toAdd {
            newPayload.append(encodeName(item.name))
            newPayload.append(0) // kind: func
            newPayload.append(encodeULEB128(item.index))
        }

        var newData = Data()
        newData.append(data.subdata(in: 0..<exportSection.idOffset + 1)) // include section id
        newData.append(encodeULEB128(UInt32(newPayload.count))) // new size
        newData.append(newPayload)
        newData.append(data.subdata(in: exportSection.payloadEnd..<data.count))

        try newData.write(to: wasmURL, options: .atomic)

        if verbose {
            let added = toAdd.map { "\($0.name)=\($0.index)" }.joined(separator: ", ")
            print("Patched WASM exports: added \(added)")
        }

        return PatchResult(addedExports: toAdd.map(\.name))
    }

    // MARK: - WASM Parsing

    private struct SectionRange {
        var idOffset: Int
        var payloadStart: Int
        var payloadEnd: Int
    }

    private static func findSection(id: UInt8, in data: Data) throws -> SectionRange? {
        var i = 8 // skip magic + version
        while i < data.count {
            let idOffset = i
            let secId = data[i]
            i += 1

            let (size, sizeEnd) = try decodeULEB128(from: data, start: i)
            let payloadStart = sizeEnd
            let payloadEnd = payloadStart + Int(size)

            if payloadEnd > data.count {
                return nil
            }

            if secId == id {
                return SectionRange(idOffset: idOffset, payloadStart: payloadStart, payloadEnd: payloadEnd)
            }

            i = payloadEnd
        }
        return nil
    }

    private static func findFunctionIndex(named name: String, in data: Data) throws -> UInt32? {
        // Locate custom section named "name".
        var i = 8
        while i < data.count {
            let secId = data[i]
            i += 1

            let (size, sizeEnd) = try decodeULEB128(from: data, start: i)
            let payloadStart = sizeEnd
            let payloadEnd = payloadStart + Int(size)
            if payloadEnd > data.count {
                return nil
            }

            if secId == 0 {
                var j = payloadStart
                let (sectionName, afterName) = try decodeName(from: data, start: j)
                j = afterName

                if sectionName == "name" {
                    // Parse name subsections.
                    while j < payloadEnd {
                        let subId = data[j]
                        j += 1
                        let (subSize, subSizeEnd) = try decodeULEB128(from: data, start: j)
                        let subStart = subSizeEnd
                        let subEnd = subStart + Int(subSize)
                        if subEnd > payloadEnd { return nil }

                        if subId == 1 {
                            // Function names subsection.
                            var k = subStart
                            let (count, countEnd) = try decodeULEB128(from: data, start: k)
                            k = countEnd

                            for _ in 0..<count {
                                let (funcIdx, funcIdxEnd) = try decodeULEB128(from: data, start: k)
                                k = funcIdxEnd
                                let (funcName, funcNameEnd) = try decodeName(from: data, start: k)
                                k = funcNameEnd

                                if funcName == name {
                                    return funcIdx
                                }
                            }
                        }

                        j = subEnd
                    }
                    return nil
                }
            }

            i = payloadEnd
        }
        return nil
    }

    private static func parseExportSectionPayload(_ payload: Data) throws -> (count: Int, entriesStart: Int, names: Set<String>) {
        var i = 0
        let (countU32, countEnd) = try decodeULEB128(from: payload, start: i)
        i = countEnd
        let count = Int(countU32)

        var names = Set<String>()
        var scan = i
        for _ in 0..<count {
            let (name, nameEnd) = try decodeName(from: payload, start: scan)
            scan = nameEnd
            names.insert(name)
            // kind (1 byte)
            guard scan < payload.count else { break }
            scan += 1
            // index (uleb)
            let (_, idxEnd) = try decodeULEB128(from: payload, start: scan)
            scan = idxEnd
        }

        return (count: count, entriesStart: i, names: names)
    }

    // MARK: - LEB128 + String Encoding/Decoding

    private static func decodeULEB128(from data: Data, start: Int) throws -> (UInt32, Int) {
        var result: UInt32 = 0
        var shift: UInt32 = 0
        var i = start

        while i < data.count {
            let byte = UInt32(data[i])
            i += 1
            result |= (byte & 0x7F) << shift

            if (byte & 0x80) == 0 {
                return (result, i)
            }

            shift += 7
            if shift >= 35 {
                break
            }
        }

        throw NSError(domain: "WasmExportPatcher", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid ULEB128 sequence"])
    }

    private static func encodeULEB128(_ value: UInt32) -> Data {
        var value = value
        var out = Data()
        while true {
            var byte = UInt8(value & 0x7F)
            value >>= 7
            if value != 0 {
                byte |= 0x80
            }
            out.append(byte)
            if value == 0 { break }
        }
        return out
    }

    private static func decodeName(from data: Data, start: Int) throws -> (String, Int) {
        let (len, lenEnd) = try decodeULEB128(from: data, start: start)
        let strStart = lenEnd
        let strEnd = strStart + Int(len)
        guard strEnd <= data.count else {
            throw NSError(domain: "WasmExportPatcher", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid name length"])
        }
        let s = String(decoding: data[strStart..<strEnd], as: UTF8.self)
        return (s, strEnd)
    }

    private static func encodeName(_ s: String) -> Data {
        let bytes = Array(s.utf8)
        var out = Data()
        out.append(encodeULEB128(UInt32(bytes.count)))
        out.append(contentsOf: bytes)
        return out
    }
}
