import SwiftUI
import AVFoundation

// MARK: - Pieza «gorda»: cara + borde inferior sólido que se hunde al tocarla

/// Dibuja la pieza con su borde inferior. `pressed` baja la cara y esconde el borde.
struct Chunky: ViewModifier {
    var fill: Color
    var edge: Color
    var outline: Color? = nil
    var radius: CGFloat = Theme.buttonCorner
    var depth: CGFloat = Theme.buttonEdge
    var pressed = false

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: radius).fill(fill))
            .overlay {
                if let outline {
                    RoundedRectangle(cornerRadius: radius).strokeBorder(outline, lineWidth: 2)
                }
            }
            .offset(y: pressed ? min(Theme.pressDepth, depth) : 0)
            .padding(.bottom, depth)
            .background(RoundedRectangle(cornerRadius: radius).fill(edge))
    }
}

extension View {
    func chunky(fill: Color, edge: Color, outline: Color? = nil,
                radius: CGFloat = Theme.buttonCorner, depth: CGFloat = Theme.buttonEdge,
                pressed: Bool = false) -> some View {
        modifier(Chunky(fill: fill, edge: edge, outline: outline, radius: radius, depth: depth, pressed: pressed))
    }
}

// MARK: - Botones (72 pt, esquinas 22, borde inferior 6 pt, bajan 5 pt al tocar)

/// Botón gordo genérico. Úsalo con los nombres de abajo para que cada color tenga un significado.
struct ChunkyButtonStyle: ButtonStyle {
    var fill: Color
    var edge: Color
    var textColor: Color
    var outline: Color? = nil
    var height: CGFloat = Theme.buttonHeight

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.bold))
            .foregroundStyle(textColor)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: height)
            .contentShape(Rectangle())
            .chunky(fill: fill, edge: edge, outline: outline, pressed: configuration.isPressed)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// Acción principal (azul). Uno por pantalla.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ChunkyButtonStyle(fill: Theme.ink, edge: Theme.inkEdge, textColor: Theme.onInk)
            .makeBody(configuration: configuration)
    }
}

/// Acción secundaria: tarjeta oscura con texto azul.
struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat = Theme.buttonHeight
    func makeBody(configuration: Configuration) -> some View {
        ChunkyButtonStyle(fill: Theme.surface, edge: Theme.line, textColor: Theme.ink,
                          outline: Theme.line, height: max(height, Theme.minTouch))
            .makeBody(configuration: configuration)
    }
}

/// Marcar algo como hecho (verde, siempre con palomita en la etiqueta).
struct DoneButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ChunkyButtonStyle(fill: Theme.done, edge: Theme.doneEdge, textColor: Theme.onInk)
            .makeBody(configuration: configuration)
    }
}

/// Botón redondo de solo icono (60 pt), para flechas, borrar, etc.
struct RoundIconButtonStyle: ButtonStyle {
    var size: CGFloat = Theme.minTouch
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.bold))
            .foregroundStyle(Theme.text)
            .frame(width: size, height: size)
            .contentShape(Circle())
            .chunky(fill: Theme.surface, edge: Theme.line, outline: Theme.line,
                    radius: size / 2, depth: 4, pressed: configuration.isPressed)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Tarjetas (esquinas 18, borde inferior 5 pt)

extension View {
    /// Tarjeta gorda. `border` es el contorno y el borde inferior (gris, o amarillo si pide atención).
    func cardStyle(border: Color = Theme.line, lineWidth: CGFloat = 2, radius: CGFloat = Theme.cardCorner) -> some View {
        self
            .background(RoundedRectangle(cornerRadius: radius).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(border, lineWidth: lineWidth))
            .padding(.bottom, Theme.cardEdge)
            .background(RoundedRectangle(cornerRadius: radius).fill(border))
    }
}

struct SectionTitle: View {
    let text: String
    var color: Color = Theme.secondaryText
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icon { Image(systemName: icon) }
            Text(text)
                .font(.rounded(19, relativeTo: .headline))
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Etiqueta de estado: color + icono + texto (el color nunca va solo).
struct StatusPill: View {
    enum Kind { case done, attention, upcoming }
    let kind: Kind
    let text: String
    var icon: String? = nil
    /// Versión chica para encima de fotos y portadas.
    var compact = false

    var body: some View {
        let (fill, edge, fg, defaultIcon): (Color, Color, Color, String) = switch kind {
        case .done: (Theme.done, Theme.doneEdge, Theme.onInk, "checkmark")
        case .attention: (Theme.attention, Theme.attentionEdge, Theme.onInk, "exclamationmark")
        case .upcoming: (Theme.upcoming, Theme.upcomingEdge, Theme.text, "clock")
        }
        Label(text, systemImage: icon ?? defaultIcon)
            .font((compact ? Font.caption : .subheadline).weight(.heavy))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(fg)
            .padding(.horizontal, compact ? 9 : 12)
            .padding(.vertical, compact ? 4 : 6)
            .chunky(fill: fill, edge: edge, radius: compact ? 10 : 14, depth: 3)
    }
}

// MARK: - Fichas (elegida = amarillo)

struct Chip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if selected { Image(systemName: "checkmark") }
                Text(title).minimumScaleFactor(0.8)
            }
            .font(.body.weight(.heavy))
        }
        .buttonStyle(ChipStyle(selected: selected))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct ChipStyle: ButtonStyle {
    let selected: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(selected ? Theme.onInk : Theme.text)
            .padding(.horizontal, 18)
            .frame(minHeight: Theme.minTouch - 4)
            .chunky(fill: selected ? Theme.attention : Theme.surface,
                    edge: selected ? Theme.attentionEdge : Theme.line,
                    outline: selected ? nil : Theme.line,
                    radius: 18, depth: 4, pressed: configuration.isPressed)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// Dos pestañas gordas: la elegida en amarillo y un poco más grande.
struct FatTabs<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, title: String, icon: String)]

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(options, id: \.value) { option in
                let isOn = option.value == selection
                Button {
                    withAnimation(.spring(duration: 0.3)) { selection = option.value }
                } label: {
                    // Un solo renglón: si no cabe, la letra se encoge (nunca «…» ni palabras partidas).
                    Label(option.title, systemImage: option.icon)
                        .labelStyle(.titleAndIcon)
                        .font(.headline.weight(.heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .buttonStyle(ChunkyButtonStyle(
                    fill: isOn ? Theme.attention : Theme.surface,
                    edge: isOn ? Theme.attentionEdge : Theme.line,
                    textColor: isOn ? Theme.onInk : Theme.text,
                    outline: isOn ? nil : Theme.line,
                    height: isOn ? 68 : 60))
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .dynamicTypeSize(TypeRange.fixedWidth)
    }
}

struct PersonPicker: View {
    @Environment(AppStore.self) private var store
    var showAll = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if showAll {
                    Chip(title: "Todos", selected: store.selectedPersonID == nil) {
                        store.selectedPersonID = nil
                    }
                }
                ForEach(store.people) { p in
                    Chip(title: p.name, selected: store.selectedPersonID == p.id) {
                        store.selectedPersonID = p.id
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Perfil arriba a la derecha + navegación

/// Título grande de pantalla con la letra redondeada (va dentro del contenido y se desplaza con él).
struct ScreenTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.rounded(34, relativeTo: .largeTitle))
            .foregroundStyle(Theme.text)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// El título del sistema se queda (VoiceOver y botón «atrás») pero no se dibuja:
/// el visible es `ScreenTitle`, con la letra del sistema visual.
struct HiddenNavTitle: View {
    var body: some View { Color.clear.frame(width: 1, height: 1).accessibilityHidden(true) }
}

struct CaregiverChrome: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) { HiddenNavTitle() }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: Route.perfil) {
                        Image(systemName: "person.crop.circle")
                            .font(.title.weight(.bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: Theme.minTouch, height: Theme.minTouch)
                    }
                    .accessibilityLabel("Perfil")
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .perfil: PerfilView()
                }
            }
    }
}

extension View {
    func caregiverChrome(title: String) -> some View { modifier(CaregiverChrome(title: title)) }
}

// MARK: - Barra inferior: botones redondos; el elegido sube como medallón amarillo

struct MedallionTabBar: View {
    @Environment(AppStore.self) private var store

    private let items: [(tab: AppTab, title: String, icon: String)] = [
        (.inicio, "Inicio", "mappin.and.ellipse"),
        (.calendario, "Calendario", "calendar"),
        (.alertas, "Alertas", "bell"),
        (.recuerdos, "Recuerdos", "photo.on.rectangle"),
        (.familia, "Familia", "tree")
    ]

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(items, id: \.tab) { item in
                TabMedallion(title: item.title, icon: item.icon,
                             selected: store.selectedTab == item.tab,
                             badge: item.tab == .alertas ? store.attentionCount : 0) {
                    withAnimation(.spring(duration: 0.35)) { store.selectedTab = item.tab }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(alignment: .top) {
            Theme.background
                .overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 2) }
                .ignoresSafeArea(edges: .bottom)
        }
        .dynamicTypeSize(TypeRange.tabBar)
    }
}

private struct TabMedallion: View {
    let title: String
    let icon: String
    let selected: Bool
    let badge: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: selected ? 26 : 21, weight: .bold))
                    .foregroundStyle(selected ? Theme.onInk : Theme.text)
                    .frame(width: selected ? 62 : 50, height: selected ? 62 : 50)
                    .chunky(fill: selected ? Theme.attention : Theme.surface,
                            edge: selected ? Theme.attentionEdge : Theme.line,
                            outline: selected ? nil : Theme.line,
                            radius: selected ? 31 : 25, depth: 4)
                    .overlay(alignment: .topTrailing) {
                        if badge > 0 {
                            Text("\(badge)")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(Theme.onInk)
                                .frame(minWidth: 24, minHeight: 24)
                                .background(Theme.attention, in: Circle())
                                .overlay(Circle().stroke(Theme.background, lineWidth: 3))
                                .offset(x: 6, y: -4)
                        }
                    }
                    // El elegido sube sobre la barra.
                    .offset(y: selected ? -14 : 0)
                    .padding(.bottom, selected ? -14 : 0)

                Text(title)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(selected ? Theme.attention : Theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.bottom, 3)
                    .overlay(alignment: .bottom) {
                        if selected {
                            Capsule().fill(Theme.attention).frame(height: 3)
                        }
                    }
            }
            .frame(minWidth: Theme.minTouch, minHeight: 76)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(badge > 0 ? "\(title), \(badge) pendientes" : title)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Aviso de confirmación (8 s): Memo contento, mensaje y «Deshacer»

struct UndoBanner: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        if let notice = store.notice {
            HStack(spacing: 12) {
                MemoView(size: 44, happy: true)
                Text(notice.message)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Deshacer") { store.undoNotice() }
                    .buttonStyle(ChunkyButtonStyle(fill: Theme.surface, edge: Theme.line,
                                                   textColor: Theme.ink, outline: Theme.line,
                                                   height: Theme.minTouch))
                    .fixedSize()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .cardStyle(border: Theme.ink)
            .padding(.horizontal, 16)
            .readableWidth()
            .dynamicTypeSize(TypeRange.fixedWidth)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Voz (lectura en voz alta real con AVSpeechSynthesizer)

final class Speaker {
    static let shared = Speaker()
    private let synthesizer = AVSpeechSynthesizer()

    /// `slow` = la voz de Memo: más lenta y pausada.
    func speak(_ text: String, slow: Bool = false) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = slow ? 0.36 : 0.42
        utterance.pitchMultiplier = slow ? 1.1 : 1
        synthesizer.speak(utterance)
    }
}

// MARK: - Fichas que bajan de renglón cuando no caben

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
