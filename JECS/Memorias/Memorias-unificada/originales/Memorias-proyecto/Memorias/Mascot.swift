import SwiftUI

// MARK: - Memo, el elefantito (los elefantes «nunca olvidan»)
// Dibujado con formas, sin imágenes: escala a cualquier tamaño y respeta Reducir movimiento.
// Estilo: cuerpo negro con contorno café grueso, ojos enormes de colores distintos y orejas caídas con detalle verde.
// Solo aparece en el estilo «Juego».

enum MascotMood { case normal, happy }

/// Trompa: tubo que nace en la cara, baja y enrosca la punta hacia arriba. Más ancha arriba que en la punta.
private enum Trunk {
    static let p0 = CGPoint(x: 0.36, y: 0.0), p1 = CGPoint(x: 0.36, y: 0.55)
    static let p2 = CGPoint(x: 0.4, y: 0.98), p3 = CGPoint(x: 0.8, y: 0.74)

    static func center(_ t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(x: u*u*u*p0.x + 3*u*u*t*p1.x + 3*u*t*t*p2.x + t*t*t*p3.x,
                       y: u*u*u*p0.y + 3*u*u*t*p1.y + 3*u*t*t*p2.y + t*t*t*p3.y)
    }
    static func normal(_ t: CGFloat) -> CGPoint {
        let a = center(max(0, t - 0.01)), b = center(min(1, t + 0.01))
        let dx = b.x - a.x, dy = b.y - a.y, l = max(0.0001, hypot(dx, dy))
        return CGPoint(x: -dy / l, y: dx / l)
    }
    static func half(_ t: CGFloat) -> CGFloat { 0.16 - 0.06 * t }      // medio grosor
}

private struct TrunkShape: Shape {
    func path(in r: CGRect) -> Path {
        func pt(_ c: CGPoint, _ n: CGPoint, _ k: CGFloat) -> CGPoint {
            CGPoint(x: r.minX + (c.x + n.x * k) * r.width, y: r.minY + (c.y + n.y * k * r.width / r.height) * r.height)
        }
        var p = Path()
        let steps = 40
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let q = pt(Trunk.center(t), Trunk.normal(t), Trunk.half(t))
            i == 0 ? p.move(to: q) : p.addLine(to: q)
        }
        // punta redonda
        let e = Trunk.center(1), n = Trunk.normal(1), h = Trunk.half(1)
        for i in 1...10 {
            let a = CGFloat(i) / 10 * .pi
            let tangent = CGPoint(x: n.y, y: -n.x)
            let dir = CGPoint(x: n.x * cos(a) + tangent.x * sin(a), y: n.y * cos(a) + tangent.y * sin(a))
            p.addLine(to: pt(e, dir, h))
        }
        for i in stride(from: steps, through: 0, by: -1) {
            let t = CGFloat(i) / CGFloat(steps)
            p.addLine(to: pt(Trunk.center(t), Trunk.normal(t), -Trunk.half(t)))
        }
        p.closeSubpath()
        return p
    }
}

/// Arruguitas de la trompa.
private struct TrunkWrinkles: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        for t in [0.24, 0.38] as [CGFloat] {
            let c = Trunk.center(t), n = Trunk.normal(t), h = Trunk.half(t)
            func pt(_ k: CGFloat) -> CGPoint {
                CGPoint(x: r.minX + (c.x + n.x * k) * r.width, y: r.minY + (c.y + n.y * k * r.width / r.height) * r.height)
            }
            p.move(to: pt(-h * 0.7)); p.addLine(to: pt(h * 0.2))
        }
        return p
    }
}

struct Mascot: View {
    var size: CGFloat = 96
    var mood: MascotMood = .normal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blink = false
    @State private var bob = false

    private let black = Color(UIColor(hex: 0x9AA8B2))      // cuerpo gris
    private let pupil = Color(UIColor(hex: 0x0B1A22))
    private let brown = Color(UIColor(hex: 0x4B5B67))
    private let green = Color(UIColor(hex: 0x1CB0F6))      // detalle azul de las orejas

    private var lw: CGFloat { max(1.6, size * 0.032) }

    private func blob(_ w: CGFloat, _ h: CGFloat, x: CGFloat, y: CGFloat, rot: Double = 0, fill: Color? = nil) -> some View {
        Ellipse().fill(fill ?? black)
            .overlay(Ellipse().stroke(brown, lineWidth: lw))
            .frame(width: size * w, height: size * h)
            .rotationEffect(.degrees(rot))
            .offset(x: size * x, y: size * (y - 0.17))
    }

    var body: some View {
        let s = size
        ZStack {
            // sombra en el piso
            Ellipse().fill(Color.black.opacity(0.28)).frame(width: s * 0.95, height: s * 0.13).blur(radius: s * 0.02)
                .offset(y: s * (0.72 - 0.17))
            // cola, patas y cuerpo sentado
            blob(0.12, 0.1, x: 0.4, y: 0.5, rot: -30)
            blob(0.26, 0.28, x: 0.24, y: 0.56)
            blob(0.52, 0.46, x: 0, y: 0.45)
            blob(0.2, 0.26, x: -0.14, y: 0.62)
            blob(0.2, 0.26, x: 0.12, y: 0.64)
            // orejas caídas con detalle verde
            ForEach([-1.0, 1.0], id: \.self) { side in
                ZStack {
                    Ellipse().fill(black)
                    Ellipse().fill(green).frame(width: s * 0.22, height: s * 0.4).offset(x: CGFloat(side) * s * 0.07, y: s * 0.02)
                    Ellipse().stroke(brown, lineWidth: lw)
                }
                .frame(width: s * 0.46, height: s * 0.58)
                .rotationEffect(.degrees(side * -14))
                .offset(x: CGFloat(side) * s * 0.43, y: s * (-0.04 - 0.17))
            }
            // cabeza
            blob(0.8, 0.68, x: 0, y: 0)
            // trompa: tubo que baja y enrosca la punta
            ZStack {
                TrunkShape().fill(black)
                TrunkWrinkles().stroke(brown, style: StrokeStyle(lineWidth: lw * 0.7, lineCap: .round))
                TrunkShape().stroke(brown, style: StrokeStyle(lineWidth: lw, lineJoin: .round))
                // parche que oculta el contorno superior: la trompa nace de la cara
                Ellipse().fill(black).frame(width: s * 0.44 * 0.36, height: s * 0.1)
                    .position(x: s * 0.44 * 0.36, y: s * 0.0)
            }
            .frame(width: s * 0.44, height: s * 0.4)
            .offset(x: s * 0.05, y: s * (0.3 - 0.17))
            // colmillitos
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule().fill(Color(UIColor(hex: 0xE6EEF2)))
                    .overlay(Capsule().stroke(brown, lineWidth: lw * 0.7))
                    .frame(width: s * 0.06, height: s * 0.13)
                    .rotationEffect(.degrees(side * 22)).offset(x: CGFloat(side) * s * 0.2, y: s * (0.27 - 0.17))
            }
            // ojos enormes de colores distintos
            eye(ring: Color(UIColor(hex: 0xE6EEF2)), iris: Color(UIColor(hex: 0x1CB0F6)), w: 0.3, h: 0.37)
                .offset(x: -s * 0.18, y: s * (-0.08 - 0.17))
            eye(ring: Color(UIColor(hex: 0xE6EEF2)), iris: Color(UIColor(hex: 0x1CB0F6)), w: 0.3, h: 0.37)
                .offset(x: s * 0.17, y: s * (-0.08 - 0.17))
            if mood == .happy {      // mejillas sonrosadas
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Ellipse().fill(Color(UIColor(hex: 0x1CB0F6)).opacity(0.55)).frame(width: s * 0.13, height: s * 0.08)
                        .offset(x: CGFloat(side) * s * 0.33, y: s * (0.1 - 0.17))
                }
            }
        }
        .frame(width: s * 1.3, height: s * 1.1)
        .offset(y: bob ? -s * 0.025 : s * 0.01)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { bob = true }
        }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64.random(in: 2_500_000_000...5_000_000_000))
                withAnimation(.easeInOut(duration: 0.08)) { blink = true }
                try? await Task.sleep(nanoseconds: 120_000_000)
                withAnimation(.easeInOut(duration: 0.08)) { blink = false }
            }
        }
        .accessibilityLabel("Memo, tu amigo elefante")
    }

    private func eye(ring: Color, iris: Color, w: CGFloat, h: CGFloat) -> some View {
        let s = size
        return ZStack {
            Ellipse().fill(ring)
            Ellipse().fill(pupil).frame(width: s * w * 0.55, height: s * h * 0.62)
            Ellipse().stroke(iris, lineWidth: s * 0.022).frame(width: s * w * 0.62, height: s * h * 0.68)
            Circle().fill(Color.white.opacity(0.9)).frame(width: s * 0.045, height: s * 0.045).offset(x: s * 0.03, y: -s * 0.05)
            Ellipse().stroke(brown, lineWidth: lw)
        }
        .frame(width: s * w, height: s * h)
        .scaleEffect(y: blink ? 0.08 : 1)
    }
}

/// Memo con un globo de texto. Al tocarlo lee el mensaje en voz alta.
struct MascotSays: View {
    let text: String
    var mood: MascotMood = .normal
    var size: CGFloat = 64

    var body: some View {
        Button { Speaker.shared.speak(text) } label: {
            HStack(alignment: .center, spacing: 6) {
                Mascot(size: size, mood: mood).frame(width: size * 1.3, height: size * 1.05)
                HStack(spacing: 0) {
                    BubbleTail().fill(Skin.card).frame(width: 12, height: 20).overlay(BubbleTail().stroke(Skin.line, lineWidth: 2))
                    Text(text).font(.headline.weight(.heavy)).foregroundStyle(Skin.ink)
                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background { SkinFrame(radius: 16, seed: 3, fill: 1) }
                }
            }
            .dynamicTypeSize(.xLarge ... .xxxLarge)       // el banner no le quita el camino al día
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .accessibilityHint("Toca para escucharlo")
    }
}

private struct BubbleTail: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.maxX, y: r.minY)); p.addLine(to: CGPoint(x: r.minX, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        return p
    }
}
