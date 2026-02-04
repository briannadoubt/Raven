import XCTest
@testable import RavenCLI

@available(macOS 13.0, *)
final class WasmOptimizerTests: XCTestCase {
    var tempDir: URL!
    var wasmFile: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        wasmFile = tempDir.appendingPathComponent("test.wasm")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }

    func testOptimizeNonExistentFile() async throws {
        let optimizer = WasmOptimizer(verbose: false)

        do {
            _ = try await optimizer.optimize(wasmPath: wasmFile.path)
            XCTFail("Should throw error for non-existent file")
        } catch {
            // Expected to throw
            XCTAssertTrue(error is WasmOptimizer.OptimizerError)
        }
    }

    func testOptimizeWithoutWasmOpt() async throws {
        // Create a dummy WASM file
        let dummyContent = Data(repeating: 0, count: 1024)
        try dummyContent.write(to: wasmFile)

        let optimizer = WasmOptimizer(verbose: false)
        let result = try await optimizer.optimize(wasmPath: wasmFile.path)

        // If wasm-opt is not available, should return unoptimized result
        if result.wasOptimized {
            // wasm-opt is available - verify optimization
            XCTAssertNotNil(result.toolUsed)
            XCTAssertEqual(result.originalSize, 1024)
        } else {
            // wasm-opt not available - verify skipped
            XCTAssertNil(result.toolUsed)
            XCTAssertEqual(result.originalSize, result.optimizedSize)
            XCTAssertEqual(result.reductionPercentage, 0.0)
        }
    }

    func testOptimizationLevels() async throws {
        let levels: [WasmOptimizer.OptimizationLevel] = [.o0, .o1, .o2, .o3, .oz]

        for level in levels {
            XCTAssertNotNil(level.rawValue)
            XCTAssertFalse(level.description.isEmpty)
        }

        XCTAssertEqual(WasmOptimizer.OptimizationLevel.o3.rawValue, "-O3")
        XCTAssertEqual(WasmOptimizer.OptimizationLevel.oz.rawValue, "-Oz")
    }

    func testResultStructure() async throws {
        let result = WasmOptimizer.OptimizationResult(
            originalSize: 1000,
            optimizedSize: 800,
            reductionPercentage: 20.0,
            toolUsed: "wasm-opt -O3"
        )

        XCTAssertTrue(result.wasOptimized)
        XCTAssertEqual(result.savedBytes, 200)
        XCTAssertEqual(result.originalSize, 1000)
        XCTAssertEqual(result.optimizedSize, 800)

        let noOptResult = WasmOptimizer.OptimizationResult(
            originalSize: 1000,
            optimizedSize: 1000,
            reductionPercentage: 0.0,
            toolUsed: nil
        )

        XCTAssertFalse(noOptResult.wasOptimized)
        XCTAssertEqual(noOptResult.savedBytes, 0)
    }
}
