import SwiftUI

// MARK: - Trazos a mano
// Todo lo que se dibuja en «Mi día» sale de aquí: círculos que no cierran del todo, marcos con esquinas
// temblorosas, iconos de líneas dobles y caminos de puntos irregulares. Son formas, no imágenes: escalan con el texto.

private func hash(_ x: Double) -> CGFloat {
    let v = sin(x * 12.9898) * 43758.5453
    return CGFloat(v - floor(v)) - 0.5          // -0.5 ... 0.5
}

/// Círculo dibujado de un trazo: radio que respira y un pequeño cruce al cerrar.
struct RoughCircle: Shape {
    var seed: Double = 0
    func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY)
        let rad = min(r.width, r.height) / 2 * 0.97
        let n = 40.0
        func pt(_ k: Double) -> CGPoint {
            let a = k / n * 2 * .pi + seed * 0.7 - .pi / 2
            let wob = 1 + 0.022 * sin(k * 0.9 + seed) + 0.016 * sin(k * 2.3 + seed * 1.7) + 0.01 * sin(k * 5.1 + seed * 3)
            let drift = 1 - 0.035 * (k / n)                   // la espiral se encoge: los extremos no se encuentran
            let rr = rad * CGFloat(wob * drift)
            return CGPoint(x: c.x + rr * CGFloat(cos(a)), y: c.y + rr * CGFloat(sin(a)))
        }
        var p = Path()
        var prev = pt(0)
        p.move(to: prev)
        var k = 1.0
        while k <= n + 5 {                                    // +5: el trazo se pasa un poco al cerrar
            let cur = pt(k)
            p.addQuadCurve(to: CGPoint(x: (prev.x + cur.x) / 2, y: (prev.y + cur.y) / 2), control: prev)
            prev = cur; k += 1
        }
        return p
    }
}

/// Marco / pastilla dibujado: lados con ligera curva, esquinas que no coinciden y un trazo que se pasa.
struct RoughRect: Shape {
    var radius: CGFloat = 14
    var seed: Double = 0
    func path(in r: CGRect) -> Path {
        func j(_ i: Double, _ m: CGFloat) -> CGFloat { hash(i * 3.1 + seed * 7.7) * 2 * m }
        let rr = min(radius, min(r.width, r.height) / 2)
        var p = Path()
        let start = CGPoint(x: r.minX + rr + j(1, 1.5), y: r.minY + j(2, 1.5))
        p.move(to: start)
        p.addQuadCurve(to: CGPoint(x: r.maxX - rr, y: r.minY + j(3, 1.5)), control: CGPoint(x: r.midX, y: r.minY + j(4, 3)))
        p.addQuadCurve(to: CGPoint(x: r.maxX + j(5, 1.5), y: r.minY + rr), control: CGPoint(x: r.maxX + j(6, 1.5), y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX + j(7, 1.5), y: r.maxY - rr), control: CGPoint(x: r.maxX + j(8, 3), y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - rr, y: r.maxY + j(9, 1.5)), control: CGPoint(x: r.maxX + j(10, 1.5), y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX + rr, y: r.maxY + j(11, 1.5)), control: CGPoint(x: r.midX, y: r.maxY + j(12, 3)))
        p.addQuadCurve(to: CGPoint(x: r.minX + j(13, 1.5), y: r.maxY - rr), control: CGPoint(x: r.minX + j(14, 1.5), y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX + j(15, 1.5), y: r.minY + rr), control: CGPoint(x: r.minX + j(16, 3), y: r.midY))
        p.addQuadCurve(to: CGPoint(x: start.x + 9, y: start.y + j(17, 1.5)), control: CGPoint(x: r.minX + j(18, 1.5), y: r.minY))
        return p
    }
}

/// Línea trazada a mano alzada (subrayados, borde de la barra inferior).
struct WobbleLine: Shape {
    var seed: Double = 0
    func path(in r: CGRect) -> Path {
        var p = Path()
        var x = r.minX
        p.move(to: CGPoint(x: x, y: r.midY))
        while x < r.maxX {
            x = min(r.maxX, x + 14)
            let y = r.midY + 2.2 * CGFloat(sin(Double(x) * 0.045 + seed)) + hash(Double(x) + seed) * 1.6
            p.addLine(to: CGPoint(x: x, y: y))
        }
        return p
    }
}

/// Camino de puntitos irregulares siguiendo una curva (distinto tamaño y pulso en cada punto).
struct DotTrail: Shape {
    let start: CGPoint, c1: CGPoint, c2: CGPoint, end: CGPoint
    var spacing: CGFloat = 17
    var seed: Double = 0

    func path(in rect: CGRect) -> Path {
        func at(_ t: CGFloat) -> CGPoint {
            let u = 1 - t
            let x = u*u*u*start.x + 3*u*u*t*c1.x + 3*u*t*t*c2.x + t*t*t*end.x
            let y = u*u*u*start.y + 3*u*u*t*c1.y + 3*u*t*t*c2.y + t*t*t*end.y
            return CGPoint(x: x, y: y)
        }
        var p = Path()
        var last = at(0), acc: CGFloat = 0, i = 0
        let steps = 160
        for s in 1...steps {
            let cur = at(CGFloat(s) / CGFloat(steps))
            acc += hypot(cur.x - last.x, cur.y - last.y)
            last = cur
            if acc >= spacing {
                acc = 0; i += 1
                let rad = 2.6 + (hash(Double(i) + seed) + 0.5) * 2.0
                let ox = hash(Double(i) * 1.7 + seed) * 3, oy = hash(Double(i) * 2.3 + seed) * 3
                p.addEllipse(in: CGRect(x: cur.x + ox - rad, y: cur.y + oy - rad, width: rad * 2, height: rad * 2 * 0.9))
            }
        }
        return p
    }
}

/// Rayado a lápiz en diagonal, recortado a un círculo.
struct HatchLines: Shape {
    var spacing: CGFloat = 9
    func path(in r: CGRect) -> Path {
        var p = Path()
        var x = r.minX - r.height
        var i = 0
        while x < r.maxX {
            let w = hash(Double(i) * 1.3) * 2
            p.move(to: CGPoint(x: x, y: r.maxY + w))
            p.addLine(to: CGPoint(x: x + r.height, y: r.minY - w))
            x += spacing; i += 1
        }
        return p
    }
}

// MARK: - Iconos de línea

enum SketchKind { case calendar, cross, gift, arrowL, arrowR, mic, sun, pill, cup, video, fork, tree, book, thought, signpost, person, house, check, dots }

struct SketchIconShape: Shape {
    let kind: SketchKind
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * w, y: r.minY + y * h) }
        func circle(_ x: CGFloat, _ y: CGFloat, _ rad: CGFloat) -> CGRect {
            CGRect(x: r.minX + (x - rad) * w, y: r.minY + (y - rad) * h, width: rad * 2 * w, height: rad * 2 * h)
        }
        /// Nube de un solo contorno con 5 bultos; `box` es el rectángulo (0...1) donde se coloca.
        func cloud(_ box: CGRect) -> Path {
            func q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { p(box.minX + x * box.width, box.minY + y * box.height) }
            var c = Path()
            c.move(to: q(0.24, 0.9))
            c.addCurve(to: q(0.12, 0.58), control1: q(0.0, 0.9), control2: q(-0.02, 0.6))
            c.addCurve(to: q(0.34, 0.34), control1: q(0.06, 0.34), control2: q(0.22, 0.28))
            c.addCurve(to: q(0.62, 0.22), control1: q(0.36, 0.06), control2: q(0.58, 0.0))
            c.addCurve(to: q(0.86, 0.5), control1: q(0.86, 0.0), control2: q(1.02, 0.3))
            c.addCurve(to: q(0.78, 0.9), control1: q(1.04, 0.62), control2: q(0.98, 0.92))
            c.addQuadCurve(to: q(0.24, 0.9), control: q(0.52, 1.02))
            return c
        }
        var s = Path()
        switch kind {
        case .calendar:
            s.addRoundedRect(in: CGRect(x: r.minX + 0.12 * w, y: r.minY + 0.2 * h, width: 0.76 * w, height: 0.68 * h),
                             cornerSize: CGSize(width: 0.08 * w, height: 0.08 * w))
            s.move(to: p(0.12, 0.4)); s.addLine(to: p(0.88, 0.4))
            s.move(to: p(0.32, 0.1)); s.addLine(to: p(0.32, 0.28))
            s.move(to: p(0.68, 0.1)); s.addLine(to: p(0.68, 0.28))
            for yy in [0.54, 0.7] as [CGFloat] { for xx in [0.28, 0.48, 0.68] as [CGFloat] {
                s.move(to: p(xx, yy)); s.addLine(to: p(xx + 0.07, yy))
            } }
        case .cross:
            let pts: [(CGFloat, CGFloat)] = [(0.38, 0.12), (0.62, 0.12), (0.62, 0.38), (0.88, 0.38), (0.88, 0.62), (0.62, 0.62),
                                             (0.62, 0.88), (0.38, 0.88), (0.38, 0.62), (0.12, 0.62), (0.12, 0.38), (0.38, 0.38)]
            s.move(to: p(pts[0].0, pts[0].1))
            for q in pts.dropFirst() { s.addLine(to: p(q.0, q.1)) }
            s.closeSubpath()
        case .gift:
            s.addRect(CGRect(x: r.minX + 0.16 * w, y: r.minY + 0.46 * h, width: 0.68 * w, height: 0.4 * h))
            s.addRect(CGRect(x: r.minX + 0.12 * w, y: r.minY + 0.34 * h, width: 0.76 * w, height: 0.12 * h))
            s.move(to: p(0.5, 0.34)); s.addLine(to: p(0.5, 0.86))
            s.addEllipse(in: circle(0.39, 0.24, 0.1)); s.addEllipse(in: circle(0.61, 0.24, 0.1))
        case .arrowL:
            s.move(to: p(0.88, 0.5)); s.addLine(to: p(0.14, 0.5))
            s.move(to: p(0.42, 0.22)); s.addLine(to: p(0.14, 0.5)); s.addLine(to: p(0.42, 0.78))
        case .arrowR:
            s.move(to: p(0.12, 0.5)); s.addLine(to: p(0.86, 0.5))
            s.move(to: p(0.58, 0.22)); s.addLine(to: p(0.86, 0.5)); s.addLine(to: p(0.58, 0.78))
        case .mic:
            s.addRoundedRect(in: CGRect(x: r.minX + 0.36 * w, y: r.minY + 0.08 * h, width: 0.28 * w, height: 0.46 * h),
                             cornerSize: CGSize(width: 0.14 * w, height: 0.14 * w))
            s.move(to: p(0.24, 0.42)); s.addCurve(to: p(0.76, 0.42), control1: p(0.24, 0.8), control2: p(0.76, 0.8))
            s.move(to: p(0.5, 0.7)); s.addLine(to: p(0.5, 0.88))
            s.move(to: p(0.36, 0.9)); s.addLine(to: p(0.64, 0.9))
            s.move(to: p(0.42, 0.24)); s.addLine(to: p(0.58, 0.24))
            s.move(to: p(0.42, 0.34)); s.addLine(to: p(0.58, 0.34))
        case .sun:
            s.addEllipse(in: circle(0.5, 0.5, 0.19))
            for i in 0..<8 {
                let a = CGFloat(i) * .pi / 4 + 0.15
                let r1: CGFloat = 0.3 + (i % 2 == 0 ? 0 : 0.02), r2: CGFloat = i % 2 == 0 ? 0.44 : 0.4
                s.move(to: p(0.5 + r1 * cos(a), 0.5 + r1 * sin(a))); s.addLine(to: p(0.5 + r2 * cos(a), 0.5 + r2 * sin(a)))
            }
        case .pill:
            s.addRoundedRect(in: CGRect(x: r.minX + 0.06 * w, y: r.minY + 0.33 * h, width: 0.88 * w, height: 0.34 * h),
                             cornerSize: CGSize(width: 0.17 * h, height: 0.17 * h))
            s.move(to: p(0.48, 0.33)); s.addLine(to: p(0.5, 0.67))
            for i in 0..<3 {
                let x = 0.6 + 0.1 * CGFloat(i)
                s.move(to: p(x, 0.62)); s.addLine(to: p(x + 0.05, 0.4))
            }
            let t = CGAffineTransform(translationX: r.midX, y: r.midY).rotated(by: -.pi / 4.5).translatedBy(x: -r.midX, y: -r.midY)
            s = s.applying(t)
        case .cup:
            s.move(to: p(0.2, 0.36)); s.addLine(to: p(0.27, 0.7))
            s.addQuadCurve(to: p(0.61, 0.7), control: p(0.44, 0.86))
            s.addLine(to: p(0.68, 0.36))
            s.addQuadCurve(to: p(0.2, 0.36), control: p(0.44, 0.31))
            s.move(to: p(0.68, 0.43)); s.addCurve(to: p(0.63, 0.62), control1: p(0.9, 0.38), control2: p(0.86, 0.66))
            s.move(to: p(0.1, 0.82)); s.addQuadCurve(to: p(0.8, 0.82), control: p(0.45, 0.93))
            s.move(to: p(0.34, 0.26)); s.addCurve(to: p(0.38, 0.1), control1: p(0.27, 0.2), control2: p(0.44, 0.17))
            s.move(to: p(0.5, 0.26)); s.addCurve(to: p(0.54, 0.1), control1: p(0.43, 0.2), control2: p(0.6, 0.17))
        case .video:
            s.addRoundedRect(in: CGRect(x: r.minX + 0.08 * w, y: r.minY + 0.28 * h, width: 0.56 * w, height: 0.44 * h),
                             cornerSize: CGSize(width: 0.07 * w, height: 0.07 * w))
            s.move(to: p(0.64, 0.46)); s.addLine(to: p(0.92, 0.3)); s.addLine(to: p(0.92, 0.7)); s.addLine(to: p(0.64, 0.55))
            s.move(to: p(0.2, 0.38)); s.addLine(to: p(0.34, 0.38))
        case .fork:
            for x in [0.17, 0.29, 0.41] as [CGFloat] { s.move(to: p(x, 0.1)); s.addLine(to: p(x + 0.005, 0.4)) }
            s.move(to: p(0.17, 0.4)); s.addQuadCurve(to: p(0.41, 0.4), control: p(0.29, 0.56))
            s.move(to: p(0.29, 0.52)); s.addLine(to: p(0.3, 0.9))
            s.move(to: p(0.68, 0.9)); s.addLine(to: p(0.68, 0.1))
            s.addCurve(to: p(0.68, 0.56), control1: p(0.9, 0.18), control2: p(0.88, 0.5))
        case .tree:
            s = cloud(CGRect(x: 0.06, y: 0.04, width: 0.88, height: 0.56))
            s.move(to: p(0.44, 0.6)); s.addLine(to: p(0.42, 0.88))
            s.move(to: p(0.57, 0.6)); s.addLine(to: p(0.59, 0.88))
            s.move(to: p(0.28, 0.9)); s.addLine(to: p(0.74, 0.9))
            s.move(to: p(0.4, 0.3)); s.addCurve(to: p(0.5, 0.42), control1: p(0.42, 0.38), control2: p(0.46, 0.4))
        case .book:
            s.move(to: p(0.5, 0.3)); s.addCurve(to: p(0.08, 0.24), control1: p(0.34, 0.2), control2: p(0.18, 0.2))
            s.addLine(to: p(0.08, 0.76)); s.addCurve(to: p(0.5, 0.82), control1: p(0.2, 0.7), control2: p(0.36, 0.7))
            s.move(to: p(0.5, 0.3)); s.addCurve(to: p(0.92, 0.24), control1: p(0.66, 0.2), control2: p(0.82, 0.2))
            s.addLine(to: p(0.92, 0.76)); s.addCurve(to: p(0.5, 0.82), control1: p(0.8, 0.7), control2: p(0.64, 0.7))
            s.move(to: p(0.5, 0.3)); s.addLine(to: p(0.5, 0.82))
            s.move(to: p(0.18, 0.4)); s.addLine(to: p(0.4, 0.45))
            s.move(to: p(0.18, 0.54)); s.addLine(to: p(0.4, 0.58))
            s.move(to: p(0.6, 0.45)); s.addLine(to: p(0.82, 0.4))
        case .thought:
            s = cloud(CGRect(x: 0.04, y: 0.04, width: 0.92, height: 0.66))
            s.addEllipse(in: circle(0.26, 0.82, 0.07)); s.addEllipse(in: circle(0.14, 0.94, 0.04))
        case .signpost:
            s.move(to: p(0.5, 0.08)); s.addLine(to: p(0.5, 0.94))
            s.move(to: p(0.5, 0.2)); s.addLine(to: p(0.14, 0.2)); s.addLine(to: p(0.06, 0.3)); s.addLine(to: p(0.14, 0.4)); s.addLine(to: p(0.5, 0.4))
            s.move(to: p(0.5, 0.5)); s.addLine(to: p(0.86, 0.5)); s.addLine(to: p(0.94, 0.6)); s.addLine(to: p(0.86, 0.7)); s.addLine(to: p(0.5, 0.7))
        case .person:
            s.addEllipse(in: circle(0.5, 0.32, 0.17))
            s.move(to: p(0.18, 0.9)); s.addCurve(to: p(0.82, 0.9), control1: p(0.16, 0.52), control2: p(0.84, 0.52))
        case .house:
            s.move(to: p(0.08, 0.5)); s.addLine(to: p(0.5, 0.14)); s.addLine(to: p(0.92, 0.5))
            s.move(to: p(0.2, 0.44)); s.addLine(to: p(0.2, 0.88)); s.addLine(to: p(0.8, 0.88)); s.addLine(to: p(0.8, 0.44))
            s.addRect(CGRect(x: r.minX + 0.43 * w, y: r.minY + 0.62 * h, width: 0.14 * w, height: 0.26 * h))
        case .check:
            s.move(to: p(0.18, 0.55)); s.addLine(to: p(0.4, 0.78)); s.addLine(to: p(0.84, 0.22))
        case .dots:
            for x in [0.28, 0.5, 0.72] as [CGFloat] { s.addEllipse(in: circle(x, 0.5, 0.05)) }
        }
        return s
    }
}

/// Icono de líneas dobles, como repasado con pluma.
struct SketchIcon: View {
    let kind: SketchKind
    var color: Color = Skin.ink
    var body: some View {
        GeometryReader { g in
            let lw = min(5, max(2.2, min(g.size.width, g.size.height) * 0.075))
            ZStack {
                SketchIconShape(kind: kind)
                    .stroke(color, style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
                if Skin.id == .sketch {      // repaso a pluma solo en el estilo dibujado
                    SketchIconShape(kind: kind)
                        .stroke(color.opacity(0.4), style: StrokeStyle(lineWidth: lw * 0.55, lineCap: .round, lineJoin: .round))
                        .offset(x: lw * 0.4, y: -lw * 0.3).rotationEffect(.degrees(1.4))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Círculo dibujado dos veces (trazo firme + repaso), opcionalmente con rayado.
struct SketchRing: View {
    var seed: Double = 0
    var line: CGFloat = 3.5
    var hatch: Bool = false
    var color: Color = Pal.pen
    var dashed: Bool = false

    var body: some View {
        ZStack {
            if hatch {
                HatchLines(spacing: 8).stroke(color.opacity(0.22), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    .clipShape(Circle()).padding(line * 1.4)
            }
            RoughCircle(seed: seed)
                .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round,
                                                  dash: dashed ? [9, 8] : []))
            if !dashed {
                RoughCircle(seed: seed + 1.9)
                    .stroke(color.opacity(0.4), style: StrokeStyle(lineWidth: line * 0.55, lineCap: .round))
                    .scaleEffect(0.985).rotationEffect(.degrees(3))
            }
        }
    }
}

/// Marco de papel con borde a pluma (sin sombra, sin esquinas perfectas).
struct HandFrame: View {
    var radius: CGFloat = 14
    var seed: Double = 0
    var fill: Double = 0.78
    var line: CGFloat = 3
    var tint: Color? = nil          // relleno de marcador (por ejemplo ámbar)

    var body: some View {
        ZStack {
            RoughRect(radius: radius, seed: seed).fill(tint ?? Color.white.opacity(fill))
            RoughRect(radius: radius, seed: seed).stroke(Pal.pen, style: StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round))
            RoughRect(radius: radius, seed: seed + 3).stroke(Pal.pen.opacity(0.4), style: StrokeStyle(lineWidth: line * 0.55, lineCap: .round))
                .scaleEffect(0.99)
        }
    }
}

extension EventKind {
    var icon: SketchKind {
        switch self {
        case .medicine: .pill
        case .doctor: .cross
        case .visit: .person
        case .birthday: .gift
        case .other: .dots
        }
    }
}
