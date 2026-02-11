import Testing
@testable import RavenCLI

@Suite struct BrowserTabURLMatcherTests {
    @Test func normalizeRemovesTrailingSlash() {
        #expect(BrowserTabURLMatcher.normalize("http://localhost:3000/") == "http://localhost:3000")
    }

    @Test func normalizeKeepsRootSlash() {
        #expect(BrowserTabURLMatcher.normalize("/") == "/")
    }

    @Test func exactURLMatches() {
        #expect(
            BrowserTabURLMatcher.matches(
                candidateURL: "http://localhost:3000",
                targetURL: "http://localhost:3000"
            )
        )
    }

    @Test func trailingSlashVariantsMatch() {
        #expect(
            BrowserTabURLMatcher.matches(
                candidateURL: "http://localhost:3000/",
                targetURL: "http://localhost:3000"
            )
        )
        #expect(
            BrowserTabURLMatcher.matches(
                candidateURL: "http://localhost:3000",
                targetURL: "http://localhost:3000/"
            )
        )
    }

    @Test func subpathMatchesBaseURL() {
        #expect(
            BrowserTabURLMatcher.matches(
                candidateURL: "http://localhost:3000/todos/1",
                targetURL: "http://localhost:3000"
            )
        )
    }

    @Test func differentHostDoesNotMatch() {
        #expect(
            !BrowserTabURLMatcher.matches(
                candidateURL: "http://127.0.0.1:3000",
                targetURL: "http://localhost:3000"
            )
        )
    }

    @Test func differentPortDoesNotMatch() {
        #expect(
            !BrowserTabURLMatcher.matches(
                candidateURL: "http://localhost:3001",
                targetURL: "http://localhost:3000"
            )
        )
    }

    @Test func nilCandidateDoesNotMatch() {
        #expect(
            !BrowserTabURLMatcher.matches(
                candidateURL: nil,
                targetURL: "http://localhost:3000"
            )
        )
    }
}
