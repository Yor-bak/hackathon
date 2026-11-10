import SwiftUI

// MARK: - Memo, el elefantito (dibujado con formas, solo gris y azul)

/// Elefante sentado que acompaña y habla. Dos estados: normal y contento (mejillas azules).
/// Parpadea y flota suavemente; con «Reducir movimiento» se queda quieto.
/// Tamaños del sistema: 44 pt (aviso), 62 pt (banner), 150 pt (pantallas grandes).
struct MemoView: View {
    var size: CGFloat = 62
    var happy = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                MemoDrawing(happy: happy, blink: 0, float: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    // Parpadeo corto cada 4 s
                    let phase = t.truncatingRemainder(dividingBy: 4)
                    let blink = phase < 0.16 ? sin(phase / 0.16 * .pi) : 0
                    MemoDrawing(happy: happy, blink: blink, float: sin(t * 1.6))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(happy ? "Memo, el elefantito, contento" : "Memo, el elefantito")
    }
}

private struct MemoDrawing: View {
    let happy: Bool
    let blink: Double     // 0 = abierto, 1 = cerrado
    let float: Double     // -1 ... 1

    // Paleta de Memo
    private let body_ = Color(hex: 0x9AA8B2)
    private let outline = Color(hex: 0x4B5B67)
    private let blue = Theme.ink
    private let white = Color(hex: 0xE6EEF2)
    private let pupil = Color(hex: 0x0B1A22)

    var body: some View {
        Canvas { ctx, canvasSize in
            // Se dibuja en una caja de 100 × 100 y se escala.
            let s = canvasSize.width / 100
            func r(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect {
                CGRect(x: x * s, y: y * s, width: w * s, height: h * s)
            }
            func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            let line = 3 * s

            // Sombra suave en el piso (no flota)
            let shadowScale = 1 - float * 0.06
            ctx.fill(Path(ellipseIn: r(50 - 28 * shadowScale, 92, 56 * shadowScale, 7)),
                     with: .color(.black.opacity(0.28)))

            // Todo lo demás flota
            ctx.translateBy(x: 0, y: -float * 2.2 * s)

            func blob(_ rect: CGRect, fill: Color) {
                let shape = Path(ellipseIn: rect)
                ctx.fill(shape, with: .color(fill))
                ctx.stroke(shape, with: .color(outline), lineWidth: line)
            }

            // Orejas grandes y caídas (detrás de la cabeza), con interior azul
            blob(r(1, 17, 38, 46), fill: body_)
            blob(r(61, 17, 38, 46), fill: body_)
            ctx.fill(Path(ellipseIn: r(8, 25, 25, 31)), with: .color(blue))
            ctx.fill(Path(ellipseIn: r(67, 25, 25, 31)), with: .color(blue))

            // Cuerpo sentado y patitas
            blob(r(24, 52, 52, 40), fill: body_)
            blob(r(28, 81, 18, 13), fill: body_)
            blob(r(54, 81, 18, 13), fill: body_)

            // Cabeza
            blob(r(24, 12, 52, 50), fill: body_)

            // Colmillitos
            for (x0, x1) in [(42.0, 38.5), (58.0, 61.5)] {
                var tusk = Path()
                tusk.move(to: p(x0, 51))
                tusk.addQuadCurve(to: p(x1, 59), control: p(x0, 57))
                ctx.stroke(tusk, with: .color(white), style: StrokeStyle(lineWidth: 3.6 * s, lineCap: .round))
            }

            // Trompa regordeta que baja y enrosca la punta
            var trunk = Path()
            trunk.move(to: p(50, 44))
            trunk.addCurve(to: p(49, 70), control1: p(52, 54), control2: p(47, 62))
            trunk.addCurve(to: p(58, 74), control1: p(50, 77), control2: p(56, 78))
            trunk.addCurve(to: p(55.5, 68), control1: p(60.5, 71.5), control2: p(58, 67))
            ctx.stroke(trunk, with: .color(outline), style: StrokeStyle(lineWidth: 13 * s, lineCap: .round, lineJoin: .round))
            ctx.stroke(trunk, with: .color(body_), style: StrokeStyle(lineWidth: 8 * s, lineCap: .round, lineJoin: .round))
            // Dos arruguitas
            for y in [55.0, 60.0] {
                var wrinkle = Path()
                wrinkle.move(to: p(47, y))
                wrinkle.addQuadCurve(to: p(52.5, y), control: p(49.7, y + 1.6))
                ctx.stroke(wrinkle, with: .color(outline), style: StrokeStyle(lineWidth: 1.6 * s, lineCap: .round))
            }

            // Mejillas azules (contento)
            if happy {
                ctx.fill(Path(ellipseIn: r(27.5, 42, 10, 6)), with: .color(blue.opacity(0.55)))
                ctx.fill(Path(ellipseIn: r(62.5, 42, 10, 6)), with: .color(blue.opacity(0.55)))
            }

            // Ojos enormes e iguales
            let open = max(0.08, 1 - blink)
            for cx in [38.5, 61.5] {
                let cy = 31.0
                func eye(_ radius: Double, dx: Double = 0, dy: Double = 0) -> Path {
                    Path(ellipseIn: r(cx + dx - radius, cy + dy - radius * open, radius * 2, radius * 2 * open))
                }
                ctx.fill(eye(11), with: .color(white))
                ctx.stroke(eye(11), with: .color(outline), lineWidth: 1.5 * s)
                if open > 0.3 {
                    ctx.fill(eye(7.6, dy: 0.8), with: .color(blue))
                    ctx.fill(eye(4.4, dy: 1), with: .color(pupil))
                    ctx.fill(eye(2.2, dx: 2.6, dy: -2.6), with: .color(.white))
                }
            }
        }
    }
}

// MARK: - Banner de Memo con globo (62 pt). Tocar el globo lo lee en voz alta.

struct MemoBanner: View {
    let message: String
    var happy = false

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            MemoView(size: 62, happy: happy)

            Button {
                Speaker.shared.speak(message, slow: true)
            } label: {
                HStack(spacing: 10) {
                    Text(message)
                        .font(.rounded(19, relativeTo: .headline))
                        .foregroundStyle(Theme.text)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "speaker.wave.2")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: Theme.minTouch)
                .cardStyle()
                // Colita del globo apuntando a Memo
                .overlay(alignment: .leading) {
                    BubbleTail()
                        .fill(Theme.surface)
                        .overlay(BubbleTail().stroke(Theme.line, lineWidth: 2))
                        .frame(width: 12, height: 16)
                        .offset(x: -10, y: -2)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(message)
            .accessibilityHint("Toca para escucharlo")
        }
        .dynamicTypeSize(TypeRange.fixedWidth)
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}
