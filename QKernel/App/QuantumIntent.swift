import AppIntents

struct RunQuantumEngineIntent: AppIntent {
    static var title: LocalizedStringResource = "Run Quantum Matrix"
    static var description = IntentDescription("Run 24-qubit quantum matrix on iPhone GPU")
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
