import SwiftUI

// MARK: - Memo, el elefantito (los elefantes «nunca olvidan»)
// Usa la ilustración memo.png; flota suavemente y respeta «Reducir movimiento».

enum MascotMood { case normal, happy }

struct Mascot: View {
    var size: CGFloat = 96
    var mood: MascotMood = .normal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false

    var body: some View {
        // Ilustración de Memo (memo.png, recortada de elefante.jpeg).
        Group {
            if let ui = UIImage(named: "memo") {
                Image(uiImage: ui).resizable().scaledToFit()
            } else {
                Image(systemName: "hare.fill").resizable().scaledToFit().foregroundStyle(Pal.text2)
            }
        }
        .frame(width: size * 1.1, height: size * 1.1)
        .scaleEffect(mood == .happy && bob ? 1.04 : 1)
        .offset(y: bob ? -size * 0.025 : size * 0.01)
        .frame(width: size * 1.3, height: size * 1.1)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { bob = true }
        }
        .accessibilityLabel("Memo, tu amigo elefante")
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
