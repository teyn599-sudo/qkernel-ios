import AppIntents
import Metal

struct WriteQuantumStateIntent: AppIntent {
    static var title: LocalizedStringResource = "寫入量子態矩陣"
    static var description = IntentDescription("在 iPhone GPU 上建立並演化 24-qubit 量子態")

    // 必須開啟 App：512MB 分配 + 演化，超過背景時間限制
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = await Task.detached {
            MetalQuantumEngine.shared.runHSequence(nQubits: 24)
        }.value
        return .result(value: result)
    }
}

struct QKernelShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WriteQuantumStateIntent(),
            phrases: [
                "Run quantum in \(.applicationName)",
                "Quantum matrix in \(.applicationName)",
                "Start \(.applicationName)",
                "在 \(.applicationName) 跑量子",
                "\(.applicationName) 量子矩陣"
            ],
            shortTitle: "Run Quantum Matrix",
            systemImageName: "atom"
        )
    }
}
