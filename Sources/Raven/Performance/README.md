# Performance Profiling Infrastructure

Comprehensive performance monitoring and profiling system for the Raven rendering pipeline.

## Overview

The Performance module provides detailed insights into rendering performance, including:

- **VNode Diffing** - Time spent computing tree differences
- **DOM Patching** - Time spent applying DOM updates
- **Component Metrics** - Per-component render times and call counts
- **Memory Tracking** - JavaScript heap and estimated VNode/DOM memory
- **Frame Rate Monitoring** - FPS tracking and dropped frame detection
- **DevTools Integration** - Browser console API access via `window.__RAVEN_PERF__`

## Architecture

### Core Components

1. **RenderProfiler** - Main profiling coordinator
   - Manages profiling sessions
   - Coordinates subsystems (memory, FPS, components)
   - Generates comprehensive reports
   - Exposes DevTools API

2. **ComponentMetrics** - Per-component performance tracking
   - Measures individual component render times
   - Identifies slow components (>16ms)
   - Tracks call counts and statistics

3. **MemoryMonitor** - Memory usage tracking
   - Samples JavaScript heap memory
   - Estimates VNode and DOM memory
   - Detects potential memory leaks

4. **FrameRateMonitor** - FPS and frame timing
   - Tracks frame rate (target: 60 FPS)
   - Detects dropped frames (>16.67ms)
   - Calculates performance ratings

5. **PerformanceReport** - Report generation and export
   - Aggregates all metrics
   - Identifies performance issues
   - Exports as JSON for analysis

## Usage

### Basic Profiling Session

```swift
import Raven

// Get shared profiler instance
let profiler = RenderProfiler.shared

// Start profiling
profiler.startProfiling(label: "App Launch")

// Your rendering code...
profiler.measureRender {
    await renderCoordinator.render(view: MyApp())
}

// Generate report
let report = profiler.generateReport()
print(report.summary)

// Stop profiling
profiler.stopProfiling()
```

### Measuring Diffing and Patching

```swift
// Measure VNode diffing
let patches = profiler.measureDiffing(label: "HomePage") {
    differ.diff(old: oldTree, new: newTree)
}

// Measure DOM patching
await profiler.measurePatching(label: "HomePage") {
    await domBridge.applyPatches(patches)
}
```

### Component-Level Profiling

```swift
// Measure specific component
profiler.measureComponent("UserProfile") {
    return UserProfileView().body
}

// Get top slow components
let slowComponents = profiler.componentMetrics.getSlowComponents(thresholdMs: 16.0)
for (name, metric) in slowComponents {
    print("\(name): \(metric.averageDuration)ms avg")
}
```

### Integrating with RenderCoordinator

The profiler should be integrated into the main render loop:

```swift
@MainActor
public final class RenderCoordinator {
    private let profiler = RenderProfiler.shared

    public func render<V: View>(view: V) async {
        await profiler.measureRender(label: "\(V.self)") {
            // Measure diffing
            let patches = profiler.measureDiffing {
                differ.diff(old: currentTree, new: newTree)
            }

            // Update tree metrics
            profiler.updateVNodeCount(newTree.nodeCount())

            // Measure patching
            await profiler.measurePatching {
                await applyPatches(patches)
            }

            // Update DOM node count
            let domNodeCount = DOMBridge.shared.getRegisteredNodeIDs().count
            profiler.updateDOMNodeCount(domNodeCount)
        }
    }
}
```

### Memory Monitoring

```swift
let memoryMonitor = MemoryMonitor()

// Start monitoring (samples every 500ms)
memoryMonitor.start()

// Get current metrics
let metrics = memoryMonitor.getMetrics()
print("Memory: \(metrics.currentUsageMB) MB")
print("Peak: \(metrics.peakUsageMB) MB")

// Check for memory leaks
if let warning = memoryMonitor.detectMemoryLeaks() {
    print("⚠️ Memory leak warning: \(warning.message)")
}

// Stop monitoring
memoryMonitor.stop()
```

### Frame Rate Monitoring

```swift
let frameMonitor = FrameRateMonitor()

// Start monitoring
frameMonitor.start()

// Record frame times (in milliseconds)
frameMonitor.recordFrame(duration: 12.5)
frameMonitor.recordFrame(duration: 15.8)
frameMonitor.recordFrame(duration: 18.2) // Dropped frame!

// Get metrics
let metrics = frameMonitor.getMetrics()
print("FPS: \(metrics.averageFPS)")
print("Dropped: \(metrics.droppedFramePercentage)%")
print("Grade: \(metrics.performanceGrade)")

// Stop monitoring
frameMonitor.stop()
```

### Generating Reports

```swift
// Generate comprehensive report
let report = profiler.generateReport()

// Print summary
print(report.summary)

// Check for issues
if report.hasPerformanceIssues {
    print("Performance issues detected:")
    for issue in report.performanceIssues {
        print("- \(issue.description)")
    }
}

// Export as JSON
let json = report.toJSON()
// Send to analytics or save to file
```

### DevTools Integration

The profiler exposes a JavaScript API at `window.__RAVEN_PERF__`:

```javascript
// In browser console:

// Start profiling
window.__RAVEN_PERF__.startProfiling()

// Stop profiling
window.__RAVEN_PERF__.stopProfiling()

// Get report as JSON
const report = window.__RAVEN_PERF__.getReport()
console.log(JSON.parse(report))

// Reset profiling data
window.__RAVEN_PERF__.reset()
```

## Performance Metrics

### Operation Metrics

For each operation type (diffing, patching, rendering), the following metrics are collected:

- **Count** - Number of operations
- **Total Duration** - Sum of all operation durations
- **Average Duration** - Mean operation time
- **Min/Max Duration** - Range of operation times
- **P50/P95/P99** - Percentile distributions

### Component Metrics

Per-component metrics include:

- **Call Count** - Number of times rendered
- **Total Duration** - Total time spent in component
- **Average Duration** - Mean render time
- **Is Slow** - Whether average exceeds 16ms threshold

### Memory Metrics

Memory tracking includes:

- **Current Usage** - Current heap size
- **Peak Usage** - Maximum heap size observed
- **Average Usage** - Mean heap size over session
- **Trend** - Growing/stable/shrinking
- **Leak Detection** - Automatic leak detection

### Frame Rate Metrics

Frame rate monitoring includes:

- **Current/Average FPS** - Frame rate measurements
- **Dropped Frame Count** - Frames exceeding 16.67ms
- **Dropped Frame Percentage** - Ratio of dropped frames
- **Performance Grade** - A/B/C/D/F rating

## Performance Targets

### Frame Budget

- **Target Frame Time**: 16.67ms (60 FPS)
- **Acceptable FPS**: >= 55 FPS
- **Max Dropped Frames**: < 5%

### Operation Targets

- **VNode Diffing**: < 10ms (P95)
- **DOM Patching**: < 10ms (P95)
- **Complete Render**: < 16.67ms (average)
- **Component Render**: < 16ms (individual)

## Best Practices

### 1. Profile in Production Mode

Always profile with optimizations enabled:

```bash
swift build -c release --triple wasm32-unknown-wasi
```

### 2. Long Profiling Sessions

Run profiling for at least 30 seconds to collect meaningful statistics:

```swift
profiler.startProfiling(label: "30s stress test")
// ... run app for 30 seconds ...
profiler.stopProfiling()
```

### 3. Component-Level Optimization

Identify and optimize slow components:

```swift
let slowComponents = profiler.componentMetrics.getTopComponentsByDuration(limit: 5)
// Optimize the top 5 slowest components
```

### 4. Memory Leak Detection

Regularly check for memory leaks during development:

```swift
if let leak = memoryMonitor.detectMemoryLeaks() {
    // Investigate memory leak
    print("Leak severity: \(leak.severity)")
    print("Growth rate: \(leak.growthRate * 100)%")
}
```

### 5. Continuous Monitoring

Enable profiling in development builds:

```swift
#if DEBUG
RenderProfiler.shared.startProfiling()
#endif
```

## Integration with CI/CD

Export performance reports for regression tracking:

```swift
// In test suite
let report = profiler.generateReport()
let json = report.toJSON()

// Write to file for CI analysis
try json.write(to: URL(fileURLWithPath: "performance-report.json"))

// Fail build if performance degrades
XCTAssertGreaterThan(report.performanceScore, 0.8, "Performance regression detected")
```

## Example Performance Report

```
=== Raven Performance Report ===
Timestamp: 2026-02-04T01:30:00Z
Performance Grade: A (Score: 0.92)

Frame Rate:
  - Current: 59.8 FPS
  - Average: 58.5 FPS
  - Dropped: 12 (2.1%)

Render Cycles:
  - Count: 543
  - Average: 12.35ms
  - P95: 15.20ms
  - P99: 16.85ms

VNode Diffing:
  - Count: 543
  - Average: 4.20ms
  - P95: 7.80ms

DOM Patching:
  - Count: 543
  - Average: 8.15ms
  - P95: 12.40ms

Tree Size:
  - VNodes: 1,234
  - DOM Nodes: 1,189

Memory:
  - Current: 12.45 MB
  - Peak: 15.80 MB

Top Components by Duration:
  - UserDashboard: 8.50ms avg (45 calls)
  - ProductList: 6.20ms avg (120 calls)
  - ChartWidget: 5.80ms avg (60 calls)
  - ImageGallery: 4.90ms avg (30 calls)
  - CommentThread: 3.20ms avg (200 calls)

✅ No performance issues detected
```

## Future Enhancements

- **Flame Graph Generation** - Visual call stack profiling
- **Network Request Tracking** - API call performance
- **Custom Metrics** - User-defined performance markers
- **Performance Budgets** - Automatic alerts on threshold violations
- **Historical Tracking** - Long-term performance trends
- **Chrome DevTools Integration** - Native profiler integration

## API Reference

See individual source files for detailed API documentation:

- [RenderProfiler.swift](./RenderProfiler.swift) - Main profiling coordinator
- [ComponentMetrics.swift](./ComponentMetrics.swift) - Component-level tracking
- [MemoryMonitor.swift](./MemoryMonitor.swift) - Memory monitoring
- [FrameRateMonitor.swift](./FrameRateMonitor.swift) - FPS tracking
- [PerformanceReport.swift](./PerformanceReport.swift) - Report generation
