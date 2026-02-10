# Path Implementation for Raven

## Overview

The `Path` type provides a complete implementation for creating custom 2D shapes using drawing commands. Paths are rendered as SVG path elements, providing resolution-independent vector graphics.

## Features Implemented

### Core Path Structure
- Value type (struct) that is `Sendable` and `Hashable`
- Internal storage using an array of drawing elements
- Support for multiple subpaths in a single path

### Drawing Commands
- `move(to:)` - Move to a point without drawing (M command)
- `addLine(to:)` - Draw a straight line (L command)
- `addQuadCurve(to:control:)` - Draw a quadratic Bezier curve (Q command)
- `addCurve(to:control1:control2:)` - Draw a cubic Bezier curve (C command)
- `addArc(center:radius:startAngle:endAngle:clockwise:)` - Draw an arc (A command)
- `closeSubpath()` - Close the current subpath (Z command)

### Convenience Methods
- `addRect(_:)` - Add a rectangle to the path
- `addRoundedRect(in:cornerRadius:)` - Add a rounded rectangle with uniform corners
- `addRoundedRect(in:cornerSize:)` - Add a rounded rectangle with custom corner sizes
- `addEllipse(in:)` - Add an ellipse using Bezier curve approximation
- `addLines(_:)` - Connect multiple points with straight lines
- `addPath(_:)` - Combine paths together

### Convenience Initializers
- `init()` - Create an empty path
- `init(_:)` - Create a path from a CGRect (rectangle)
- `init(roundedRect:cornerRadius:)` - Create a rounded rectangle path
- `init(roundedRect:cornerSize:)` - Create a rounded rectangle with custom corners
- `init(ellipseIn:)` - Create an ellipse path

### Transformations
- `applying(_:)` - Apply a CGAffineTransform to the path
- `offsetBy(x:y:)` - Translate the path by specified offsets
- Support for translation, scaling, and rotation transforms

### SVG Generation
- `svgPathData` - Generates SVG path data (d attribute)
- Optimized number formatting (removes unnecessary decimals)
- Proper conversion of all drawing commands to SVG syntax
- Support for complex paths with multiple subpaths

### Path Information
- `isEmpty` - Check if path has any elements
- `copy()` - Create a copy of the path

## CGAffineTransform

Implemented a complete 2D affine transformation matrix:
- `identity` - No transformation
- `init(translationX:y:)` - Translation transform
- `init(scaleX:y:)` - Scale transform
- `init(rotationAngle:)` - Rotation transform
- Full 2x3 matrix with a, b, c, d, tx, ty components

## CGPoint Extension

Added transform support to CGPoint:
- `applying(_:)` - Apply an affine transform to a point

## SVG Path Specification Compliance

The implementation follows the SVG Path specification:
- **M** (moveto) - Absolute move command
- **L** (lineto) - Absolute line command
- **Q** (quadratic curve) - Quadratic Bezier curve
- **C** (cubic curve) - Cubic Bezier curve
- **A** (arc) - Elliptical arc with proper flag calculation
- **Z** (closepath) - Close the current subpath

## Coordinate System

Paths use the standard SVG/web coordinate system:
- Origin (0,0) at top-left
- X increases to the right
- Y increases downward
- Angles measured clockwise from positive X-axis

This matches SwiftUI's coordinate system when rendering in the DOM.

## Testing

Comprehensive test coverage with 30 tests in `PathTests.swift`:

### Basic Commands (7 tests)
- Empty path creation
- Move command SVG generation
- Line command SVG generation
- Quadratic curve command
- Cubic curve command
- Close subpath command
- Arc command

### Complex Paths (2 tests)
- Triangle path creation
- Multiple subpaths in one path

### Convenience Methods (6 tests)
- Add rectangle
- Add rounded rectangle
- Add ellipse
- Add circle (via ellipse)
- Add lines from array
- Add path to path

### Convenience Initializers (3 tests)
- Init with rectangle
- Init with rounded rect
- Init with ellipse

### Transformations (3 tests)
- Translation transform
- Scale transform
- Offset by

### SVG Generation (2 tests)
- Whole numbers formatted without decimals
- Decimal numbers properly formatted

### Utilities (7 tests)
- Copy creates equal path
- Empty array handling in addLines
- Identity transform
- Point applying transform
- Rounded rect with corner size
- Init rounded rect with corner size

All tests pass successfully!

## Documentation

Full DocC documentation including:
- Comprehensive overview with multiple examples
- Topics organized by functionality
- Examples for simple shapes, curves, custom icons
- SVG coordinate system explanation
- Performance notes
- Transformation examples
- Path combining examples

## Integration with Shape Protocol

Paths work seamlessly with the Shape protocol:
- Used as the return type of `path(in:)` method
- Rendered as SVG path elements
- Compatible with fill and stroke modifiers
- Integrates with the existing shape rendering system

## Example Usage

```swift
// Create a custom star shape
struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4

        for i in 0..<10 {
            let angle = Angle.degrees(Double(i) * 36 - 90)
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + radius * cos(angle.radians),
                y: center.y + radius * sin(angle.radians)
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// Use it in a view
Star()
    .fill(Color.yellow)
    .frame(width: 100, height: 100)
```

## Files Created/Modified

### Created
- `Sources/Raven/Drawing/Path.swift` - Complete Path implementation (550+ lines)
- `Tests/RavenTests/PathTests.swift` - Comprehensive tests (30 tests)
- `Sources/Raven/Drawing/PATH_README.md` - This documentation

### Modified
- `Sources/Raven/Views/Layout/GeometryReader.swift` - Added midX and midY to CGRect
- `Sources/Raven/Drawing/Shape.swift` - Removed duplicate type definitions
- `Sources/Raven/Drawing/InsettableShape.swift` - Fixed CGRect extension

## Future Enhancements

Potential future improvements:
- Path trimming (for animations)
- Path stroking with custom line cap/join styles
- Path intersection and union operations
- Simplified path generation (removing redundant points)
- Path bounding box calculation
- Path contains point testing
