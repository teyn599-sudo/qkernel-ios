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

kernel void cnot_float(device float2 *state [[buffer(0)]],
                       constant uint &ctrl [[buffer(1)]],
                       constant uint &tgt  [[buffer(2)]],
                       constant uint &nQubits [[buffer(3)]],
                       uint gid [[thread_position_in_grid]]) {
    uint dim = 1u << nQubits;
    if (gid >= dim) return;
    uint cm = 1u << ctrl;
    uint tm = 1u << tgt;
    if (!(gid & cm) || (gid & tm)) return;
    uint j = gid | tm;
    float2 a = state[gid];
    state[gid] = state[j];
    state[j]   = a;
}

kernel void init_zero(device float2 *state [[buffer(0)]],
                      uint gid [[thread_position_in_grid]]) {
    state[gid] = float2(0.0f, 0.0f);
}
