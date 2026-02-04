import Raven

/// Interactive animation examples demonstrating Raven's animation capabilities
@main
struct AnimationDemoApp {
    static func main() async {
        await RavenApp(rootView: AnimationGalleryView()).run()
    }
}

struct AnimationGalleryView: View {
    @State private var selectedDemo = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Animation Gallery")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            // Demo selector
            Picker("Demo", selection: $selectedDemo) {
                Text("Basic").tag(0)
                Text("Spring").tag(1)
                Text("Rotation").tag(2)
                Text("Scale").tag(3)
                Text("Combined").tag(4)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // Demo content
            Group {
                switch selectedDemo {
                case 0: BasicAnimationDemo()
                case 1: SpringAnimationDemo()
                case 2: RotationAnimationDemo()
                case 3: ScaleAnimationDemo()
                case 4: CombinedAnimationDemo()
                default: BasicAnimationDemo()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .frame(maxWidth: 800)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Basic Animation

struct BasicAnimationDemo: View {
    @State private var isMovedRight = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Basic Linear Animation")
                .font(.headline)

            Circle()
                .fill(Color.blue)
                .frame(width: 60, height: 60)
                .offset(x: isMovedRight ? 200 : -200)
                .animation(.linear(duration: 1), value: isMovedRight)

            Button("Toggle") {
                isMovedRight.toggle()
            }
            .buttonStyle(.bordered)

            Text("Uses .linear(duration: 1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Spring Animation

struct SpringAnimationDemo: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Spring Animation")
                .font(.headline)

            RoundedRectangle(cornerRadius: isExpanded ? 40 : 10)
                .fill(Color.green)
                .frame(
                    width: isExpanded ? 200 : 100,
                    height: isExpanded ? 200 : 100
                )
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isExpanded)

            Button("Toggle") {
                isExpanded.toggle()
            }
            .buttonStyle(.bordered)

            Text("Uses .spring(response: 0.6, dampingFraction: 0.7)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Rotation Animation

struct RotationAnimationDemo: View {
    @State private var rotationAngle: Double = 0

    var body: some View {
        VStack(spacing: 30) {
            Text("Rotation Animation")
                .font(.headline)

            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(rotationAngle))
                .animation(.easeInOut(duration: 0.8), value: rotationAngle)

            Button("Rotate 90°") {
                rotationAngle += 90
            }
            .buttonStyle(.bordered)

            Button("Reset") {
                rotationAngle = 0
            }
            .buttonStyle(.borderless)

            Text("Rotation: \(Int(rotationAngle))°")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Scale Animation

struct ScaleAnimationDemo: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 30) {
            Text("Scale Animation")
                .font(.headline)

            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 0.3), value: scale)

            HStack(spacing: 12) {
                Button("Small") {
                    scale = 0.5
                }
                .buttonStyle(.bordered)

                Button("Normal") {
                    scale = 1.0
                }
                .buttonStyle(.bordered)

                Button("Large") {
                    scale = 2.0
                }
                .buttonStyle(.bordered)
            }

            Text("Scale: \(String(format: "%.1f", scale))x")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Combined Animation

struct CombinedAnimationDemo: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Combined Animations")
                .font(.headline)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.orange, .red],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(isAnimating ? 1.3 : 1.0)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .offset(y: isAnimating ? -50 : 50)
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.6),
                    value: isAnimating
                )

            Button(isAnimating ? "Stop" : "Animate") {
                isAnimating.toggle()
            }
            .buttonStyle(.borderedProminent)

            Text("Combines scale, rotation, and position")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
