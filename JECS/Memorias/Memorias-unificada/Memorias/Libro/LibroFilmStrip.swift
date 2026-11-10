import SwiftUI

/// Filtro por temporada con forma de tira de película: negativo oscuro con perforaciones y un fotograma por década.
/// El fotograma elegido «se enciende» en ámbar. En pantallas anchas va vertical, a un costado, para no quitarle altura al libro.
struct FilmStrip: View {
    let titles: [(id: Int?, label: String)]
    let selection: Int?
    let vertical: Bool
    var maxLength: CGFloat = 900          // largo máximo disponible (alto si es vertical)
    let onSelect: (Int?) -> Void

    private let film = Color(red: 0x08 / 255, green: 0x0D / 255, blue: 0x16 / 255)
    private let hole = Color(red: 0x1F / 255, green: 0x2E / 255, blue: 0x47 / 255)
    private let band: CGFloat = 16          // ancho de la franja de perforaciones

    var body: some View {
        Group {
            if vertical {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) { frames }
                        .padding(.vertical, 14).padding(.horizontal, band + 4)
                }
                // La tira mide lo que miden sus fotogramas (no toda la pantalla); si no caben, se desliza.
                .frame(width: 112, height: min(maxLength, CGFloat(titles.count) * 68 + 36))
                .background(strip)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) { frames }
                        .padding(.horizontal, 14).padding(.vertical, band + 4)
                }
                // Mide lo que miden sus fotogramas y queda centrada; si no caben (iPhone), se desliza.
                .frame(width: min(maxLength, CGFloat(titles.count) * 86 + 36), height: 76)
                .background(strip)
            }
        }
        .padding(vertical ? .leading : .horizontal, vertical ? 10 : 12)
        .padding(.vertical, vertical ? 10 : 0)
        .frame(maxWidth: vertical ? nil : .infinity)      // centrada sobre el libro
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filtrar recuerdos por temporada")
    }

    @ViewBuilder private var frames: some View {
        ForEach(titles, id: \.label) { t in
            let on = selection == t.id
            Button { onSelect(t.id) } label: {
                Text(t.label)
                    .font(.custom("ArialRoundedMTBold", size: 17, relativeTo: .headline))
                    .minimumScaleFactor(0.7).lineLimit(1)
                    .foregroundStyle(on ? MemoryTheme.onAccent : .white)
                    .frame(width: vertical ? 78 : 78, height: vertical ? 50 : 38)
                    .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(on ? MemoryTheme.amber : MemoryTheme.darkSurface))
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(on ? Color.clear : MemoryTheme.edgeGray, lineWidth: 1.5))
                    .shadow(color: on ? MemoryTheme.amber.opacity(0.55) : .clear, radius: 8)   // el fotograma elegido «se enciende»
                    .frame(minWidth: 60, minHeight: 60)     // objetivo táctil
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
        }
    }

    /// La tira: negativo oscuro con perforaciones a lo largo de los dos bordes largos.
    private var strip: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(film)
            RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(MemoryTheme.edgeGray.opacity(0.7), lineWidth: 1.5)
            if vertical {
                HStack { holes(vertical: true); Spacer(); holes(vertical: true) }.padding(.horizontal, 5)
            } else {
                VStack { holes(vertical: false); Spacer(); holes(vertical: false) }.padding(.vertical, 5)
            }
        }
    }

    private func holes(vertical: Bool) -> some View {
        // Las perforaciones se dibujan en un overlay de un contenedor flexible: no le suman tamaño a la tira, solo se recortan a ella.
        let count = 40
        return Color.clear
            .frame(width: vertical ? 7 : nil, height: vertical ? nil : 7)
            .frame(maxWidth: vertical ? 7 : .infinity, maxHeight: vertical ? .infinity : 7)
            .overlay(alignment: vertical ? .top : .leading) {
                if vertical {
                    VStack(spacing: 9) { ForEach(0..<count, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2).fill(hole).frame(width: 7, height: 10) } }
                } else {
                    HStack(spacing: 9) { ForEach(0..<count, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2).fill(hole).frame(width: 10, height: 7) } }
                }
            }
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
