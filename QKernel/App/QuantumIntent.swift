import AppIntents

struct RunQuantumEngineIntent: AppIntent {
    static var title: LocalizedStringResource = "執行量子矩陣運算"
    static var description = IntentDescription("在 iPhone GPU 上執行 24-qubit 量子矩陣")
    static var openAppWhenRun: Bool = false

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
            intent: RunQuantumEngineIntent(),
            phrases: [
                "跑量子",
                "量子矩陣",
                "在 \(.applicationName) 跑量子"
            ],
            shortTitle: "跑量子矩陣",
            systemImageName: "atom"
        )
    }
}
