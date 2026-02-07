import Testing
@testable import RavenCLI
import Foundation

@Suite struct WasmOptimizerTests {
    let tempDir: URL
    let wasmFile: URL

    init() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        wasmFile = tempDir.appendingPathComponent("test.wasm")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    @Test func optimizeNonExistentFile() async throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let optimizer = WasmOptimizer(verbose: false)

        do {
            _ = try await optimizer.optimize(wasmPath: wasmFile.path)
            Issue.record("Should throw error for non-existent file")
        } catch {
            // Expected to throw
            #expect(error is WasmOptimizer.OptimizerError)
        }
    }

    @Test func optimizeWithoutWasmOpt() async throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }
        // Create a dummy WASM file
        let dummyContent = Data(repeating: 0, count: 1024)
        try dummyContent.write(to: wasmFile)

        let optimizer = WasmOptimizer(verbose: false)
        let result = try await optimizer.optimize(wasmPath: wasmFile.path)

        // If wasm-opt is not available, should return unoptimized result
        if result.wasOptimized {
            // wasm-opt is available - verify optimization
            #expect(result.toolUsed != nil)
            #expect(result.originalSize == 1024)
        } else {
            // wasm-opt not available - verify skipped
            #expect(result.toolUsed == nil)
            #expect(result.originalSize == result.optimizedSize)
            #expect(result.reductionPercentage == 0.0)
        }
    }

    @Test func optimizationLevels() async throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let levels: [WasmOptimizer.OptimizationLevel] = [.o0, .o1, .o2, .o3, .oz]

        for level in levels {
            #expect(level.rawValue != nil)
            #expect(!level.description.isEmpty)
        }

        #expect(WasmOptimizer.OptimizationLevel.o3.rawValue == "-O3")
        #expect(WasmOptimizer.OptimizationLevel.oz.rawValue == "-Oz")
    }

    @Test func resultStructure() async throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let result = WasmOptimizer.OptimizationResult(
            originalSize: 1000,
            optimizedSize: 800,
            reductionPercentage: 20.0,
            toolUsed: "wasm-opt -O3"
        )

        #expect(result.wasOptimized)
        #expect(result.savedBytes == 200)
        #expect(result.originalSize == 1000)
        #expect(result.optimizedSize == 800)

        let noOptResult = WasmOptimizer.OptimizationResult(
            originalSize: 1000,
            optimizedSize: 1000,
            reductionPercentage: 0.0,
            toolUsed: nil
        )

        #expect(!noOptResult.wasOptimized)
        #expect(noOptResult.savedBytes == 0)
    }
}
