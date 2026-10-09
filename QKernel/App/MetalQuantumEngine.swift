import Foundation
import Metal

final class MetalQuantumEngine {
    static let shared = MetalQuantumEngine()

    let device: MTLDevice
    let queue: MTLCommandQueue
    let hPipeline: MTLComputePipelineState
    let cnotPipeline: MTLComputePipelineState
    let zeroPipeline: MTLComputePipelineState

    private init() {
        guard let d = MTLCreateSystemDefaultDevice(),
              let q = d.makeCommandQueue(),
              let lib = d.makeDefaultLibrary(),
              let hf = lib.makeFunction(name: "h_gate_float"),
              let cf = lib.makeFunction(name: "cnot_float"),
              let zf = lib.makeFunction(name: "init_zero")
        else { fatalError("Metal init failed") }
        self.device = d
        self.queue = q
        self.hPipeline = try! d.makeComputePipelineState(function: hf)
        self.cnotPipeline = try! d.makeComputePipelineState(function: cf)
        self.zeroPipeline = try! d.makeComputePipelineState(function: zf)
    }

    func runHSequence(nQubits: Int = 24) -> String {
        let elementCount = 1 << nQubits
        let bufferSize = elementCount * 8  // float2 = 8 bytes
        guard let state = device.makeBuffer(length: bufferSize,
                                            options: .storageModeShared)
        else {
            return "FAIL: buffer alloc (\(bufferSize >> 20) MB)"
        }

        // init |0...0>
        if let cmd = queue.makeCommandBuffer(),
           let enc = cmd.makeComputeCommandEncoder() {
            enc.setComputePipelineState(zeroPipeline)
            enc.setBuffer(state, offset: 0, index: 0)
            let tg = MTLSize(width: 256, height: 1, depth: 1)
            let grid = MTLSize(width: elementCount, height: 1, depth: 1)
            enc.dispatchThreads(grid, threadsPerThreadgroup: tg)
            enc.endEncoding()
            cmd.commit()
            cmd.waitUntilCompleted()
        }

        let ptr = state.contents().bindMemory(to: Float.self,
                                              capacity: elementCount * 2)
        ptr[0] = 1.0  // |0> amplitude

        let start = Date()
        for q in 0..<nQubits {
            applyH(state, qubit: q, nQubits: nQubits)
        }
        let elapsed = Date().timeIntervalSince(start)

        let a0re = ptr[0]
        let a0im = ptr[1]
        let ms = elapsed * 1000.0
        return String(format: "24q H×24: %.2f ms, amp[0]=(%.6f, %.6f)", ms, a0re, a0im)
    }

    private func applyH(_ buffer: MTLBuffer, qubit: Int, nQubits: Int) {
        guard let cmd = queue.makeCommandBuffer(),
              let enc = cmd.makeComputeCommandEncoder() else { return }
        enc.setComputePipelineState(hPipeline)
        enc.setBuffer(buffer, offset: 0, index: 0)
        var q = UInt32(qubit); var n = UInt32(nQubits)
        enc.setBytes(&q, length: 4, index: 1)
        enc.setBytes(&n, length: 4, index: 2)
        let dim = 1 << nQubits
        let tg = MTLSize(width: 256, height: 1, depth: 1)
        let grid = MTLSize(width: dim, height: 1, depth: 1)
        enc.dispatchThreads(grid, threadsPerThreadgroup: tg)
        enc.endEncoding()
        cmd.commit()
        cmd.waitUntilCompleted()
    }
}
