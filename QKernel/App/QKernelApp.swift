import SwiftUI

struct ContentView: View {
    @State private var log = "按按鈕試試"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("QKernel on iPhone")
                    .font(.title).bold()
                Text(log)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Button("貝爾態") { log = QEngine.bell() }
                    .buttonStyle(.borderedProminent)
                Button("Grover (12q)") { log = QEngine.grover(nq: 12) }
                    .buttonStyle(.borderedProminent)
                Button("20q 單門 H") { log = QEngine.hOne(nq: 20) }
                    .buttonStyle(.borderedProminent)
                Button("20q 全 H") { log = QEngine.hAll(nq: 20) }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

@main
struct QKernelApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
