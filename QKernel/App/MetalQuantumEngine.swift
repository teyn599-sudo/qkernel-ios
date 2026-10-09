import Foundation
import Metal

let kQuantumMSL = """
#include <metal_stdlib>
using namespace metal;

kernel void h_gate_float(device float2 *state [[buffer(0)]],
                         constant uint &qubit [[buffer(1)]],
                         constant uint &nQubits [[buffer(2)]],
                         uint gid [[thread_position_in_grid]]) {
    uint dim = 1u << nQubits;
    if (gid >= dim) return;
    uint mask = 1u << qubit;
    if (gid & mask) return;
    uint j = gid | mask;
    float2 a = state[gid];
    float2 b = state[j];
    const float inv_sqrt2 = 0.7071067811865476f;
    state[gid] = (a + b) * inv_sqrt2;
    state[j]   = (a - b) * inv_sqrt2;
}

kernel void init_zero(device float2 *state [[buffer(0)]],
                      uint gid [[thread_position_in_grid]]) {
    state[gid] = float2(0.0f, 0.0f);
}
"""

final class MetalQuantumEngine {
    static let shared = MetalQuantumEngine()

    let device: MTLDevice
    let queue: MTLCommandQueue
    let hPipeline: MTLComputePipelineState
    let zeroPipeline: MTLComputePipelineState

    private init() {
        guard let d = MTLCreateSystemDefaultDevice(),
              let q = d.makeCommandQueue()
        else { fatalError("Metal device init failed") }
        self.device = d
        self.queue = q

        let lib: MTLLibrary
        do {
            lib = try d.makeLibrary(source: kQuantumMSL, options: nil)
        } catch {
            fatalError("Metal shader compile failed: \(error)")
        }
        self.hPipeline = try! d.makeComputePipelineState(
            function: lib.makeFunction(name: "h_gate_float")!)
        self.zeroPipeline = try! d.makeComputePipelineState(
            function: lib.makeFunction(name: "init_zero")!)
    }

    func runHSequence(nQubits: Int = 24) -> String {
        let elementCount = 1 << nQubits
        let bufferSize = elementCount * 8
        guard let state = device.makeBuffer(length: bufferSize,
                                            options: .storageModeShared)
        else {
            return "FAIL: buffer alloc (\(bufferSize >> 20) MB)"
        }

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
        ptr[0] = 1.0

        let start = Date()
        for q in 0..<nQubits {
            applyH(state, qubit: q, nQubits: nQubits)
        }
        let elapsed = Date().timeIntervalSince(start)

        let a0re = ptr[0]
        let ms = elapsed * 1000.0
        return String(format: "24q Hx24: %.2f ms, amp[0].re=%.6f", ms, a0re)
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
