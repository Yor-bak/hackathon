//
//  LibroPhotoBookView.swift
//  Memorias
//
//  Libro 3D de fotos: cada hoja gira sobre el lomo con perspectiva real.
//  Se recorre arrastrando (la hoja sigue al dedo) o tocando los laterales.
//

import SwiftUI

// MARK: - Modelo

/// Cara detectada en la foto. `rect` está normalizado (0...1) respecto a la foto.
struct FaceTag: Identifiable {
    let id = UUID()
    var name: String
    /// Cara de la persona (normalizada, origen arriba-izquierda).
    var face: CGRect
    /// Cuerpo completo de la persona (normalizado).
    var person: CGRect
}

/// Mensaje de la conversación entre la persona y la IA (Memento) sobre un recuerdo.
struct ChatMessage: Identifiable, Equatable {
    enum Role { case ai, user }
    enum Content: Equatable { case text(String), voice(TimeInterval) }
    let id = UUID()
    var role: Role
    var content: Content
}

/// Historia de un recuerdo. `nil` = aún no hubo conversación.
struct MemoryStory {
    /// Historia narrada por la IA, ya dividida en frases (se muestra como transcripción del audio).
    var sentences: [String]
    /// Conversación de voz con la que se escribió.
    var conversation: [ChatMessage] = []
}

struct BookPage: Identifiable {
    let id = UUID()
    var faces: [FaceTag] = []
    /// `nil` = el recuerdo aún no tiene historia ("is empty").
    var story: MemoryStory?
    var image: Image?
    /// Original para detectar personas con Vision.
    var uiImage: UIImage?
    /// Fecha del recuerdo, se muestra encima de la página (p. ej. «14 de febrero de 1971»).
    var date: String = ""
    var caption: String = ""
    /// Portada del libro: lleva a Memo y no se puede abrir.
    var isCover = false
    /// Fondo de respaldo cuando aún no hay foto (útil para demos / placeholders).
    var placeholder: [Color] = [Color(red: 0.23, green: 0.50, blue: 0.78), Color(red: 0.29, green: 0.26, blue: 0.46)]
}

// MARK: - Vista principal

struct PhotoBookView: View {
    let title: String
    let pages: [BookPage]

    /// Progreso continuo: 0 = libro cerrado, `leafCount` = completamente volteado.
    @State private var progress: Double = 0
    @State private var dragStartProgress: Double?

    private var leafCount: Int { (pages.count + 1) / 2 }

    var onAdd: (() -> Void)? = nil
    /// Se llama al tocar la foto que está a la vista.
    var onSelect: ((BookPage) -> Void)? = nil

    private let sideButtonSize: CGFloat = 52

    var body: some View {
        GeometryReader { geo in
            // Pantalla angosta (iPhone vertical): las flechas pasan a la fila de abajo y el libro usa todo el ancho.
            let narrow = geo.size.width < 600
            let sideSpace = narrow ? 0 : 2 * (sideButtonSize + 12)
            let available = geo.size.width - sideSpace - (narrow ? 16 : 24)
            // Pantallas bajas (iPad mini en horizontal): menos espacio fijo para que el libro y los botones quepan.
            let compact = geo.size.height < 600
            // Páginas más altas y angostas en teléfono vertical: el libro abierto (dos páginas) es más grande sin salirse del ancho.
            let aspect: CGFloat = narrow ? 0.62 : 0.78
            let pageH = min(compact ? geo.size.height - 130 : geo.size.height - 200, available / 2 / aspect)
            let pageW = pageH * aspect

            VStack(spacing: compact ? 8 : 20) {
                if compact {
                    // Una sola línea si cabe; si no (teléfono), título y datos en dos líneas centradas, sin partir el texto.
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            Text(title).font(.custom("ArialRoundedMTBold", size: 26, relativeTo: .title)).foregroundStyle(.white)
                            Text("· \(pages.filter { !$0.isCover }.count) recuerdos · \(pageLabel)")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Color(red: 0xB9/255, green: 0xC6/255, blue: 0xD8/255))
                                .lineLimit(1)
                        }
                        VStack(spacing: 2) {
                            Text(title).font(.custom("ArialRoundedMTBold", size: 26, relativeTo: .title)).foregroundStyle(.white)
                            Text("\(pages.filter { !$0.isCover }.count) recuerdos · \(pageLabel)")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Color(red: 0xB9/255, green: 0xC6/255, blue: 0xD8/255))
                        }
                    }
                } else {
                    header
                }

                HStack(spacing: 12) {
                    if !narrow {
                    roundButton("chevron.left", disabled: progress <= 0.01) {
                        goTo(Int(progress.rounded()) - 1)
                    }
                    }
                    ZStack {
                        ForEach(0..<leafCount, id: \.self) { i in
                            leaf(i, pageW: pageW, pageH: pageH)
                        }
                    }
                    .frame(width: pageW * 2, height: pageH)
                    // Centra el libro cuando está cerrado (portada) o terminado (contraportada).
                    .offset(x: centeringOffset(pageW: pageW))
                    .contentShape(Rectangle())
                    .gesture(dragGesture(pageW: pageW))
                    if !narrow {
                    roundButton("chevron.right", disabled: progress >= Double(leafCount) - 0.01) {
                        goTo(Int(progress.rounded()) + 1)
                    }
                    }
                }

                actions(narrow: narrow)
            }
            .padding(.vertical, compact ? 8 : 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Subvistas

    private var header: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.custom("ArialRoundedMTBold", size: 34, relativeTo: .title))
                .foregroundStyle(.white)
            Text("\(pages.filter { !$0.isCover }.count) recuerdos · \(pageLabel)")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Color(red: 0xB9/255, green: 0xC6/255, blue: 0xD8/255))
        }
    }

    /// Botones inferiores: compartir y agregar.
    private func actions(narrow: Bool) -> some View {
        HStack(spacing: narrow ? 12 : 16) {
            if narrow {
                roundButton("chevron.left", disabled: progress <= 0.01) { goTo(Int(progress.rounded()) - 1) }
            }
            ShareLink(item: "Mis recuerdos: \(title)") {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(MemoryTheme.darkSurface))
                    .overlay(Circle().strokeBorder(MemoryTheme.edgeGray, lineWidth: 2))
            }
            .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeGray))
            .accessibilityLabel("Compartir")
            Button { onAdd?() } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(MemoryTheme.onAccent)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(MemoryTheme.amber))
            }
            .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeAmber))
            .accessibilityLabel("Agregar un recuerdo")
            if narrow {
                roundButton("chevron.right", disabled: progress >= Double(leafCount) - 0.01) { goTo(Int(progress.rounded()) + 1) }
            }
        }
    }

    private func roundButton(_ symbol: String, disabled: Bool,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(MemoryTheme.onAccent)
                .frame(width: sideButtonSize, height: sideButtonSize)
                .background(Circle().fill(MemoryTheme.darkAction))
        }
        .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeBlue))
        .opacity(disabled ? 0.35 : 1)
        .disabled(disabled)
        .accessibilityLabel(symbol == "chevron.left" ? "Página anterior" : "Página siguiente")
    }

    private var pageLabel: String {
        let leaf = Int(progress.rounded())
        let left = leaf * 2
        if leaf == 0 { return "Portada" }
        if leaf >= leafCount { return "Fin" }
        return "páginas \(left)–\(left + 1)"
    }

    // MARK: Hoja 3D

    @ViewBuilder
    private func leaf(_ i: Int, pageW: CGFloat, pageH: CGFloat) -> some View {
        let t = min(max(progress - Double(i), 0), 1)          // 0 = plana a la derecha, 1 = volteada
        let angle = -180 * t
        let showBack = t > 0.5
        let front = pages[2 * i]
        let back: BookPage? = (2 * i + 1) < pages.count ? pages[2 * i + 1] : nil

        // Borde de páginas apiladas asomando en cada lado.
        let ahead = max(Double(i) - progress, 0)               // hojas por delante a la derecha
        let behind = max(progress - Double(i) - 1, 0)          // hojas ya volteadas a la izquierda
        let stackX = t < 0.5 ? CGFloat(min(ahead, 5)) * 9 : -CGFloat(min(behind, 5)) * 9
        let stackScale = t < 0.5 ? 1 - CGFloat(min(ahead, 5)) * 0.03
                                 : 1 - CGFloat(min(behind, 5)) * 0.03

        ZStack {
            PageFace(page: front, side: .front)
                .opacity(showBack ? 0 : 1)
            PageFace(page: back, side: .back)
                .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
                .opacity(showBack ? 1 : 0)
        }
        .frame(width: pageW, height: pageH)
        .contentShape(Rectangle())
        .onTapGesture {
            // Solo la foto visible (la de arriba a cada lado del lomo) responde.
            let current = Int(progress.rounded())
            if showBack, i == current - 1, let back, !back.isCover { onSelect?(back) }
            else if !showBack, i == current, !front.isCover { onSelect?(front) }
        }
        // Sombra proyectada mientras la hoja está en el aire.
        .overlay {
            Color.black
                .opacity(0.35 * sin(t * .pi))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .allowsHitTesting(false)
        }
        .rotation3DEffect(.degrees(angle), axis: (0, 1, 0),
                          anchor: .leading, anchorZ: 0, perspective: 0.3)
        .scaleEffect(x: 1, y: stackScale, anchor: .center)
        .offset(x: pageW / 2 + stackX)
        .shadow(color: .black.opacity(0.25 * (1 - abs(t - 0.5) * 2) + 0.15),
                radius: 10, x: 0, y: 6)
        .zIndex(t > 0.5 ? Double(i) : Double(leafCount - i))
    }

    private func centeringOffset(pageW: CGFloat) -> CGFloat {
        let opening = min(max(progress, 0), 1)
        let closing = min(max(progress - Double(leafCount - 1), 0), 1)
        return -pageW / 2 * (1 - opening) + pageW / 2 * closing
    }

    // MARK: Gestos

    private func dragGesture(pageW: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if dragStartProgress == nil { dragStartProgress = progress }
                let delta = -value.translation.width / pageW
                progress = min(max((dragStartProgress ?? 0) + delta, 0), Double(leafCount))
            }
            .onEnded { value in
                let start = dragStartProgress ?? progress
                dragStartProgress = nil
                // Usa la velocidad para decidir si la hoja termina de pasar.
                let predicted = start - value.predictedEndTranslation.width / pageW
                let target = Int(max(min(predicted, start + 1), start - 1).rounded())
                goTo(target)
            }
    }

    private func goTo(_ leaf: Int) {
        let clamped = min(max(leaf, 0), leafCount)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            progress = Double(clamped)
        }
    }
}

// MARK: - Cara de una página

private struct PageFace: View {
    enum Side { case front, back }
    let page: BookPage?
    let side: Side

    /// Portada: ícono de libro sobre fondo azul, con el título. No es una foto, así que no se abre.
    private func cover(_ page: BookPage) -> some View {
        ZStack {
            LinearGradient(colors: [MemoryTheme.darkAction, MemoryTheme.edgeBlue],
                           startPoint: .top, endPoint: .bottom)
            VStack(spacing: 14) {
                Spacer(minLength: 0)
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(MemoryTheme.amber)
                    .frame(width: 150, height: 150)
                    .background(Circle().fill(.white.opacity(0.22)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 3))
                Text(page.caption)
                    .font(.custom("ArialRoundedMTBold", size: 30, relativeTo: .title))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2).minimumScaleFactor(0.6)
                    .padding(.horizontal, 16)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 26)
        }
    }

    @ViewBuilder
    private func photo(_ page: BookPage) -> some View {
        ZStack(alignment: .bottomLeading) {
                if let image = page.image {
                    Color.clear.overlay { image.resizable().scaledToFill() }.clipped()
                } else {
                    LinearGradient(colors: page.placeholder,
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 52, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 104, height: 104)
                                .background(Circle().fill(.white.opacity(0.22)))
                                .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 3))
                        )
                }
                if !page.date.isEmpty {
                    VStack {
                        Text(page.date)
                            .font(.custom("ArialRoundedMTBold", size: 15, relativeTo: .footnote))
                            .foregroundStyle(MemoryTheme.onAccent)
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(MemoryTheme.amber, in: Capsule())
                            .padding(.top, 12)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                if !page.caption.isEmpty {
                    Text(page.caption)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.black.opacity(0.35), in: Capsule())
                        .padding(12)
                }
        }
    }

    var body: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: side == .front ? 3 : 14,
            bottomLeadingRadius: side == .front ? 3 : 14,
            bottomTrailingRadius: side == .front ? 14 : 3,
            topTrailingRadius: side == .front ? 14 : 3,
            style: .continuous
        )

        ZStack(alignment: .bottomLeading) {
            if let page, page.isCover {
                cover(page)
            } else if let page {
                // Pasepartú crema con un filete dorado: la foto queda enmarcada.
                ZStack {
                    Color(red: 1.0, green: 0.97, blue: 0.91)
                    photo(page)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(MemoryTheme.amber, lineWidth: 2))
                        .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
                        .padding(10)
                }
            } else {
                Color(white: 0.96) // reverso en blanco cuando el número de páginas es impar
            }

            // Sombra del lomo: oscurece el borde pegado al centro.
            LinearGradient(
                colors: [.black.opacity(0.35), .clear],
                startPoint: side == .front ? .leading : .trailing,
                endPoint: side == .front ? UnitPoint(x: 0.12, y: 0.5) : UnitPoint(x: 0.88, y: 0.5)
            )
            .allowsHitTesting(false)
        }
        .clipShape(shape)
        .overlay(shape.stroke(.white.opacity(0.35), lineWidth: 0.5))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(colors: [MemoryTheme.darkBackground, Color(red: 0.13, green: 0.33, blue: 0.59)],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        PhotoBookView(
            title: "Verano 2023",
            pages: [
                BookPage(caption: "Central Park", placeholder: [Color(red: 0.23, green: 0.50, blue: 0.78), Color(red: 0.13, green: 0.33, blue: 0.59)]),
                BookPage(caption: "Soho", placeholder: [.orange, .pink]),
                BookPage(caption: "Lavanda", placeholder: [.purple, Color(red: 0.6, green: 0.74, blue: 0.93)]),
                BookPage(caption: "Playa", placeholder: [.teal, Color(red: 0.23, green: 0.50, blue: 0.78)]),
                BookPage(caption: "Atardecer", placeholder: [MemoryTheme.amber, MemoryTheme.edgeAmber]),
                BookPage(caption: "Amigas", placeholder: [.pink, Color(red: 0.29, green: 0.26, blue: 0.46)]),
                BookPage(caption: "Campo", placeholder: [.green, MemoryTheme.amber]),
                BookPage(caption: "Ciudad", placeholder: [.indigo, .mint]),
            ]
        )
    }
}
