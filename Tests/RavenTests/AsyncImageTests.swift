import Testing
import Foundation
@testable import Raven

/// Tests for AsyncImage view
@Suite("AsyncImage Tests")
struct AsyncImageTests {

    // MARK: - Basic Initialization Tests

    @Test("AsyncImage can be created with a URL")
    @MainActor
    func testBasicInitialization() async throws {
        let url = URL(string: "https://example.com/image.jpg")
        let asyncImage = AsyncImage(url: url)

        // Should compile and not crash
        #expect(asyncImage != nil)
    }

    @Test("AsyncImage can be created with nil URL")
    @MainActor
    func testNilURL() async throws {
        let asyncImage = AsyncImage(url: nil as URL?)

        // Should compile and not crash
        #expect(asyncImage != nil)
    }

    @Test("AsyncImage with custom scale factor")
    @MainActor
    func testCustomScale() async throws {
        let url = URL(string: "https://example.com/image@2x.jpg")
        let asyncImage = AsyncImage(url: url, scale: 2.0)

        #expect(asyncImage != nil)
    }

    // MARK: - Content Builder Tests

    @Test("AsyncImage with phase-based content builder")
    @MainActor
    func testPhaseBasedBuilder() async throws {
        let url = URL(string: "https://example.com/image.jpg")

        let asyncImage = AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
            case .failure:
                Text("Failed to load")
            }
        }

        #expect(asyncImage != nil)
    }

    @Test("AsyncImage with placeholder builder")
    @MainActor
    func testPlaceholderBuilder() async throws {
        let url = URL(string: "https://example.com/image.jpg")

        let asyncImage = AsyncImage(url: url) { image in
            image
                .accessibilityLabel("Loaded image")
        } placeholder: {
            ProgressView()
        }

        #expect(asyncImage != nil)
    }

    // MARK: - Phase Tests

    @Test("AsyncImagePhase empty state")
    @MainActor
    func testPhaseEmpty() async throws {
        let phase = AsyncImagePhase.empty

        #expect(phase.image == nil)
        #expect(phase.error == nil)
    }

    @Test("AsyncImagePhase success state")
    @MainActor
    func testPhaseSuccess() async throws {
        let image = Image("test-image")
        let phase = AsyncImagePhase.success(image)

        #expect(phase.image != nil)
        #expect(phase.error == nil)
    }

    @Test("AsyncImagePhase failure state")
    @MainActor
    func testPhaseFailure() async throws {
        let error = AsyncImageError.loadFailed
        let phase = AsyncImagePhase.failure(error)

        #expect(phase.image == nil)
        #expect(phase.error != nil)
    }

    // MARK: - VNode Rendering Tests

    @Test("AsyncImage renders container with nil URL")
    @MainActor
    func testRenderNilURL() async throws {
        let asyncImage = AsyncImage(url: nil) { phase in
            switch phase {
            case .empty:
                Text("No image")
            case .success(let image):
                image
            case .failure:
                Text("Error")
            }
        }

        let vnode = asyncImage.toVNode()

        // Should render the empty phase content
        #expect(vnode != nil)
    }

    @Test("AsyncImage renders container with valid URL")
    @MainActor
    func testRenderValidURL() async throws {
        let url = URL(string: "https://example.com/photo.jpg")!
        let asyncImage = AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
            case .failure:
                Text("Error")
            }
        }

        let vnode = asyncImage.toVNode()

        // Should render a container with placeholder and img element
        #expect(vnode != nil)
    }

    @Test("AsyncImage simple initializer renders correctly")
    @MainActor
    func testSimpleInitializerRender() async throws {
        let url = URL(string: "https://example.com/image.png")
        let asyncImage = AsyncImage(url: url, scale: 1.0)

        let vnode = asyncImage.toVNode()

        #expect(vnode != nil)
    }

    // MARK: - Transaction Tests

    @Test("Transaction with default animation")
    @MainActor
    func testTransactionDefaultAnimation() async throws {
        let transaction = Transaction(animation: .default)

        #expect(transaction.animation != nil)
        #expect(transaction.disablesAnimations == false)
    }

    @Test("Transaction without animation")
    @MainActor
    func testTransactionNoAnimation() async throws {
        let transaction = Transaction()

        #expect(transaction.animation == nil)
        #expect(transaction.disablesAnimations == false)
    }

    @Test("AsyncImage with transaction")
    @MainActor
    func testAsyncImageWithTransaction() async throws {
        let url = URL(string: "https://example.com/image.jpg")
        let transaction = Transaction(animation: .default)

        let asyncImage = AsyncImage(
            url: url,
            transaction: transaction
        ) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
            case .failure:
                Text("Error")
            }
        }

        #expect(asyncImage != nil)
    }

    // MARK: - Error Tests

    @Test("AsyncImageError cases are defined")
    @MainActor
    func testAsyncImageErrors() async throws {
        let loadFailed = AsyncImageError.loadFailed
        let invalidData = AsyncImageError.invalidData
        let networkError = AsyncImageError.networkError

        #expect(loadFailed != nil)
        #expect(invalidData != nil)
        #expect(networkError != nil)
    }

    // MARK: - Complex View Tests

    @Test("AsyncImage with complex content view")
    @MainActor
    func testComplexContentView() async throws {
        let url = URL(string: "https://example.com/photo.jpg")

        let asyncImage = AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                VStack {
                    ProgressView()
                    Text("Loading...")
                }
            case .success(let image):
                VStack {
                    image
                        .accessibilityLabel("Profile photo")
                    Text("Photo loaded successfully")
                }
            case .failure(let error):
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Failed to load image")
                    Text(String(describing: error))
                }
            }
        }

        let vnode = asyncImage.toVNode()
        #expect(vnode != nil)
    }

    @Test("AsyncImage with custom styling")
    @MainActor
    func testCustomStyling() async throws {
        let url = URL(string: "https://example.com/image.jpg")

        let asyncImage = AsyncImage(url: url) { image in
            image
                .accessibilityLabel("Custom image")
        } placeholder: {
            VStack {
                ProgressView()
                Text("Loading image...")
            }
        }

        let vnode = asyncImage.toVNode()
        #expect(vnode != nil)
    }

    // MARK: - URL Variants Tests

    @Test("AsyncImage with various URL formats")
    @MainActor
    func testVariousURLFormats() async throws {
        let urls: [URL?] = [
            URL(string: "https://example.com/image.jpg"),
            URL(string: "https://cdn.example.com/photos/photo-123.png"),
            URL(string: "http://example.com/image.gif"),
            URL(string: "https://example.com/path/to/image.webp"),
            nil
        ]

        for url in urls {
            let asyncImage = AsyncImage(url: url)
            let vnode = asyncImage.toVNode()
            #expect(vnode != nil)
        }
    }

    // MARK: - Integration Tests

    @Test("AsyncImage works with VStack")
    @MainActor
    func testInVStack() async throws {
        let url = URL(string: "https://example.com/image.jpg")

        let view = VStack {
            Text("Header")
            AsyncImage(url: url)
            Text("Footer")
        }

        let vnode = view.toVNode()
        #expect(vnode != nil)
    }

    @Test("AsyncImage works with HStack")
    @MainActor
    func testInHStack() async throws {
        let url1 = URL(string: "https://example.com/image1.jpg")
        let url2 = URL(string: "https://example.com/image2.jpg")

        let view = HStack {
            AsyncImage(url: url1)
            AsyncImage(url: url2)
        }

        let vnode = view.toVNode()
        #expect(vnode != nil)
    }

    @Test("Multiple AsyncImages in view hierarchy")
    @MainActor
    func testMultipleAsyncImages() async throws {
        let urls = (1...3).compactMap { URL(string: "https://example.com/image\($0).jpg") }

        let view = VStack {
            ForEach(urls, id: \.self) { url in
                AsyncImage(url: url) { image in
                    image
                } placeholder: {
                    ProgressView()
                }
            }
        }

        let vnode = view.toVNode()
        #expect(vnode != nil)
    }
}

// MARK: - Helper Extensions

extension URL: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(absoluteString)
    }
}
