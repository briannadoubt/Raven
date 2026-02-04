# Router Tests Documentation

## Overview

Comprehensive test suite for Track C.1: URL-Based Routing System with **46 test cases** covering all major routing functionality.

## File Location

```
Tests/RavenTests/Navigation/RouterTests.swift
```

## Test Statistics

- **Total Tests**: 46
- **Lines of Code**: 715
- **Test Sections**: 11

## Running Tests

```bash
# Run all router tests
swift test --filter RouterTests

# Run specific test
swift test --filter RouterTests/testStaticRouteMatching
```

## Test Categories

### 1. Route Pattern Matching (6 tests)
Tests for URL pattern matching with various route types:
- Static routes (`/about`)
- Dynamic parameters (`/products/:id`)
- Multiple parameters (`/users/:userId/posts/:postId`)
- Wildcard routes (`/files/*path`)
- Route priority and matching order
- Trailing slash handling

### 2. Parameter Extraction (5 tests)
Type-safe parameter extraction and conversion:
- String parameters
- Integer conversion
- Boolean conversion (true/false, 1/0, yes/no, on/off)
- Double/floating-point conversion
- Invalid type conversion handling

### 3. Query String Parsing (4 tests)
Query parameter handling:
- Basic query string parsing
- Multiple values for same key
- URL-encoded special characters
- Empty query strings

### 4. Navigation Operations (6 tests)
Browser history integration:
- Push navigation (new history entry)
- Replace navigation (modify current entry)
- Back button functionality
- Forward button functionality
- Go to specific position (delta navigation)
- Navigation state tracking

### 5. Deep Link Handling (3 tests)
URL-based app entry:
- Initial URL processing
- Deep link validation
- Redirect handling

### 6. History State Preservation (3 tests)
Browser history state management:
- State persistence with pushState
- State handling with replaceState
- Popstate event handling

### 7. Multiple Router Instances (2 tests)
Concurrent router usage:
- Multiple routers with same routes
- Independent state management

### 8. Route Guards & Interceptors (3 tests)
Navigation control:
- Interceptor registration
- Interceptor removal
- Authentication-based guards

### 9. 404 Handling (3 tests)
Unmatched route handling:
- Default 404 view
- Custom 404 view
- History updates for 404s

### 10. Edge Cases (11 tests)
Robust error handling:
- Empty/root path
- Paths without leading slash
- Special characters in paths
- Numeric path segments
- Very long paths
- Route registration/unregistration
- Route listing
- Navigation capability checks
- Empty parameter handling
- Concurrent navigation

## Test Design

### Architecture
- Uses XCTest framework
- `@MainActor` isolation for thread safety
- Works with actual `NavigationHistory.shared` instance
- Focus on Router's state management and behavior

### Assertions
Each test verifies:
- Router state updates correctly
- Views are created/updated
- Parameters are extracted properly
- Navigation doesn't crash
- Error conditions are handled

### Limitations
- `NavigationHistory` is a final class with private init (cannot be mocked)
- Some tests verify behavior that requires browser APIs
- Tests focus on Router logic rather than browser history API calls

## Example Tests

### Route Matching
```swift
func testDynamicRouteMatchingWithSingleParameter() {
    router.register(path: "/products/:id") { params in
        Text("Product \(params.string("id") ?? "")")
    }

    router.navigate(to: "/products/123")

    XCTAssertEqual(router.currentPath, "/products/123")
    XCTAssertEqual(router.currentParameters.string("id"), "123")
}
```

### Type Conversion
```swift
func testIntParameterExtraction() {
    router.register(path: "/products/:id") { params in
        let id = params.int("id") ?? 0
        Text("Product \(id)")
    }

    router.navigate(to: "/products/12345")

    XCTAssertEqual(router.currentParameters.int("id"), 12345)
}
```

### Route Guards
```swift
func testRouteGuardForAuthentication() {
    var isAuthenticated = false

    router.setNavigationInterceptor { path in
        if path.hasPrefix("/admin") {
            return isAuthenticated
        }
        return true
    }

    router.register(path: "/admin/dashboard") {
        Text("Admin Dashboard")
    }

    // Unauthenticated - blocked
    router.navigate(to: "/admin/dashboard")
    XCTAssertNotEqual(router.currentPath, "/admin/dashboard")

    // Authenticated - allowed
    isAuthenticated = true
    router.navigate(to: "/admin/dashboard")
    XCTAssertEqual(router.currentPath, "/admin/dashboard")
}
```

## Coverage Summary

✅ **Complete Coverage** of Router public API:
- Route registration/unregistration
- Navigation (push, replace, back, forward, go)
- Parameter extraction (all types)
- Query string parsing
- Deep link handling
- History integration
- Route guards
- 404 handling
- Multiple router instances
- Edge cases and error conditions

## Notes

1. Tests are designed to run in both native and WASM contexts
2. Some browser-specific behaviors may differ in test vs production
3. All tests verify Router's state management correctness
4. Tests cover both success and failure scenarios
5. Comprehensive edge case coverage ensures robustness

## Future Enhancements

Potential additions when Router evolves:
- Route middleware/pipeline tests
- Nested router tests
- Route caching tests
- Performance benchmarks
- Integration tests with NavigationView
- Animation during navigation tests
