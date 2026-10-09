import SwiftUI

@main
struct QKernelApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var result: String = "點擊執行"
    @State private var running = false

    var body: some View {
        VStack(spacing: 24) {
            Text("QKernel").font(.largeTitle).bold()
            Text("24-Qubit GPU Quantum Engine").font(.headline)

            Button("執行 H 閘序列") {
                Task {
                    running = true
                    result = await Task.detached {
                        MetalQuantumEngine.shared.runHSequence(nQubits: 24)
                    }.value
                    running = false
                }
            }
            .disabled(running)
            .buttonStyle(.borderedProminent)

            if running { ProgressView() }

            Text(result)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
    }
}
