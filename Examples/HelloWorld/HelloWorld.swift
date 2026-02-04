import Raven

/// A simple "Hello World" example demonstrating basic Raven usage
@main
struct HelloWorldApp {
    static func main() async {
        await RavenApp(rootView: ContentView()).run()
    }
}

struct ContentView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, Raven! 👋")
                .font(.largeTitle)
                .foregroundColor(.blue)

            Text("You've clicked \(count) times")
                .font(.headline)

            Button("Click Me!") {
                count += 1
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
