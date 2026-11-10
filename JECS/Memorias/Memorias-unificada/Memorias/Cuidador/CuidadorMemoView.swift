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
        // Ilustración de Memo (memo.png, recortada de elefante.jpeg).
        Group {
            if reduceMotion {
                memo(float: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                    memo(float: sin(context.date.timeIntervalSinceReferenceDate * 1.6))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(happy ? "Memo, el elefantito, contento" : "Memo, el elefantito")
    }

    private func memo(float: Double) -> some View {
        Group {
            if let ui = UIImage(named: "memo") {
                Image(uiImage: ui).resizable().scaledToFit()
            } else {
                Image(systemName: "hare.fill").resizable().scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(happy ? 1.04 : 1)
        .offset(y: CGFloat(float) * size * 0.02)
    }
}
