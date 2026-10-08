import Foundation

let QSHIFT: Int64 = 30
let QONE: Int32 = Int32(1 << 30)
let QINV_SQRT2: Int32 = 759250125

@inline(__always)
func qmul(_ a: Int32, _ b: Int32) -> Int32 {
    return Int32((Int64(a) * Int64(b)) >> QSHIFT)
}

final class QState {
    let nq: Int
    let dim: Int
    var re: [Int32]
    var im: [Int32]

    init(nq: Int) {
        self.nq = nq
        self.dim = 1 << nq
        self.re = [Int32](repeating: 0, count: dim)
        self.im = [Int32](repeating: 0, count: dim)
        self.re[0] = QONE
    }

    func applyH(_ q: Int) {
        let mask = 1 << q
        let inv = QINV_SQRT2
        for i in 0..<dim {
            if (i & mask) != 0 { continue }
            let j = i | mask
            let ar = re[i], ai = im[i]
            let br = re[j], bi = im[j]
            re[i] = qmul(ar &+ br, inv)
            im[i] = qmul(ai &+ bi, inv)
            re[j] = qmul(ar &- br, inv)
            im[j] = qmul(ai &- bi, inv)
        }
    }

    func applyCNOT(_ c: Int, _ t: Int) {
        let cm = 1 << c, tm = 1 << t
        for i in 0..<dim {
            if (i & cm) != 0 && (i & tm) == 0 {
                let j = i | tm
                re.swapAt(i, j)
                im.swapAt(i, j)
            }
        }
    }

    func amp(_ i: Int) -> (Int32, Int32) { (re[i], im[i]) }
}

enum QEngine {
    static func bell() -> String {
        let s = QState(nq: 2)
        s.applyH(0); s.applyCNOT(0, 1)
        let (a0, _) = s.amp(0); let (a1, _) = s.amp(1)
        let (a2, _) = s.amp(2); let (a3, _) = s.amp(3)
        return "貝爾態。a0=\(a0) a1=\(a1) a2=\(a2) a3=\(a3)"
    }

    static func hOne(nq: Int) -> String {
        let s = QState(nq: nq)
        let t0 = Date()
        s.applyH(0)
        let ms = Date().timeIntervalSince(t0) * 1000
        let (a0, _) = s.amp(0)
        let (a1, _) = s.amp(1)
        return String(format: "%d qubit 單門 H。%.1f ms，a0=%d a1=%d", nq, ms, a0, a1)
    }

    static func hAll(nq: Int) -> String {
        let s = QState(nq: nq)
        let t0 = Date()
        for q in 0..<nq { s.applyH(q) }
        let ms = Date().timeIntervalSince(t0) * 1000
        let (a0, _) = s.amp(0)
        return String(format: "%d qubit 全 H。%.1f ms，a0=%d", nq, ms, a0)
    }

    static func grover(nq: Int) -> String {
        let N = 1 << nq
        let target = N / 2 + 3
        let s = QState(nq: nq)
        for q in 0..<nq { s.applyH(q) }
        let iters = max(1, Int(Double.pi / 4.0 * sqrt(Double(N))))
        for _ in 0..<iters {
            s.re[target] = -s.re[target]
            s.im[target] = -s.im[target]
            for q in 0..<nq { s.applyH(q) }
            var sum: Int64 = 0
            for i in 0..<N { sum += Int64(s.re[i]) }
            let avg = Int32(sum / Int64(N))
            for i in 0..<N {
                s.re[i] = 2 * avg - s.re[i]
                s.im[i] = -s.im[i]
            }
            for q in 0..<nq { s.applyH(q) }
        }
        let amp = s.re[target]
        let pct = Double(amp) / Double(QONE) * 100
        return String(format: "%d qubit Grover。目標振幅=%d（%.1f%%）", nq, amp, pct)
    }
}
