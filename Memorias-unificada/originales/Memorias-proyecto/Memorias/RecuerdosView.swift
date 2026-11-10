// xcode: set sdk=iOS

import SwiftUI

// MARK: - Foto de ejemplo con nombres escritos a mano sobre cada rostro

struct PhotoScene: View {
    let memory: Memory
    var showPeople = true
    var body: some View {
        let t = Pal.tones[memory.tone % Pal.tones.count]
        ZStack {
            Rectangle().fill(t.bg)
            Image(systemName: memory.symbol).resizable().scaledToFit()
                .padding(.horizontal, 60).padding(.vertical, 40)
                .foregroundStyle(t.fg.opacity(0.22))
            if showPeople { VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 22) {
                    ForEach(memory.people, id: \.self) { name in
                        VStack(spacing: 6) {
                            Text(name).font(Hand.font(30, relativeTo: .title2)).foregroundStyle(t.fg)
                                .lineLimit(1).minimumScaleFactor(0.6)
                            Circle().fill(t.fg)
                                .overlay(Text(String(name.prefix(1))).font(.title.weight(.heavy)).foregroundStyle(t.bg))
                                .frame(width: 64, height: 64)
                        }
                    }
                }
                .padding(.bottom, 18)
            } }
        }
        .dynamicTypeSize(.xLarge ... .xxxLarge)
        .overlay { if showPeople { PhotoCorners(size: 22).fill(Skin.id == .duo ? Skin.card : Skin.ink.opacity(0.95)).padding(0) } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(memory.people.isEmpty ? "Foto" : "Foto con \(memory.people.joined(separator: " y "))")
    }
}

// MARK: - Abanico de páginas (referencia: álbum con páginas en perspectiva)

struct FanSpec {
    let stripW: CGFloat
    let step: CGFloat
    let maxN: Int
    var visible: CGFloat { stripW * 0.47 }                    // ancho aparente a 62°
    var width: CGFloat { visible + step * CGFloat(maxN - 1) }
    static let spread = FanSpec(stripW: 96, step: 22, maxN: 4)
    static let compact = FanSpec(stripW: 40, step: 9, maxN: 2)
}

struct PageFan: View {
    let pages: [Memory]          // la más cercana al libro primero
    let side: HorizontalEdge
    let spec: FanSpec

    var body: some View {
        let right = side == .trailing
        ZStack(alignment: right ? .leading : .trailing) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { i, m in
                PhotoScene(memory: m, showPeople: false)
                    .frame(width: spec.stripW).frame(maxHeight: .infinity)
                    .overlay(Color.black.opacity(0.14 * Double(i + 1)))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .scaleEffect(y: 1 - 0.07 * CGFloat(i))
                    .rotation3DEffect(.degrees(right ? -62 : 62), axis: (x: 0, y: 1, z: 0),
                                      anchor: right ? .leading : .trailing, perspective: 0.5)
                    .offset(x: (right ? 1 : -1) * CGFloat(i) * spec.step)
                    .zIndex(Double(pages.count - i))
            }
        }
        .frame(width: spec.width, alignment: right ? .leading : .trailing)
        .accessibilityHidden(true)
    }
}

// MARK: - Libro abierto

private struct Turn { let page: Int; let forward: Bool }

private struct TurnEffect: ViewModifier {
    let angle: Double
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.5)
            .opacity(abs(angle) > 85 ? 0 : 1)
    }
}

/// El álbum es el libro abierto: hay un solo álbum con toda la historia. Se llega desde «Mi día».
struct RecuerdosView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(startAt: Int = 0) {
        _index = State(initialValue: startAt)
        _leftIndex = State(initialValue: startAt)
    }

    @State private var index: Int         // página confirmada
    @State private var leftIndex: Int     // página que se ve en la mitad izquierda
    @State private var target = 0
    @State private var turn: Turn?
    @State private var angle: Double = 0
    @State private var entry: UUID? = {
        // Solo para capturas: -entry abre la 1.ª página, -entry-empty la vacía
        let a = CommandLine.arguments
        if a.contains("-entry") { return Sample.memories[0].id }   // -entry: abre la 1.ª página
        return nil
    }()

    private var pages: [Memory] { app.memories }
    private var spread: Bool { hSize == .regular }
    private var rightBase: Int { turn.map { $0.forward ? target : index } ?? index }

    var body: some View {
        GeometryReader { g in
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Button { Speaker.shared.stop(); app.section = nil } label: { Label("Mi día", systemImage: "chevron.left") }
                                .buttonStyle(OutlinePill())
                            Spacer()
                        }
                        Text(pages[min(leftIndex, pages.count - 1)].fullDate)
                            .font(.title.weight(.heavy)).foregroundStyle(Pal.ink)
                            .dynamicTypeSize(.xLarge ... .accessibility1)
                            .lineLimit(2).minimumScaleFactor(0.6)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(maxWidth: 900)

                    bookArea(width: g.size.width, height: g.size.height)

                    Text("Página \(index + 1) de \(pages.count)").dynamicTypeSize(.xLarge ... .accessibility1)
                        .font(.title3.weight(.bold).monospacedDigit()).foregroundStyle(Pal.text2)


                    VStack(spacing: 8) {
                        Label("Desliza para pasar la página", systemImage: "hand.draw.fill")
                        Label(pages[index].hasStory ? "Toca la página para abrirla" : "Toca la página para contar su historia",
                              systemImage: "hand.tap.fill")
                    }
                    .font(.title3.weight(.bold)).foregroundStyle(Pal.ink)
                    .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20).padding(.bottom, 24)
                .frame(maxWidth: .infinity)
                .frame(minHeight: g.size.height)
            }
        }
        .background { SkinBackground() }
        .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { v in
            // solo deslizamientos claramente horizontales: no estorban al desplazar
            guard abs(v.translation.width) > abs(v.translation.height) * 1.5 else { return }
            if v.translation.width < -50 { go(1) } else if v.translation.width > 50 { go(-1) }
        })
        .accessibilityAction(named: "Página siguiente") { go(1) }
        .accessibilityAction(named: "Página anterior") { go(-1) }
        .fullScreenCover(isPresented: Binding(get: { entry != nil }, set: { if !$0 { entry = nil } })) {
            if let id = entry { MemoryEntry(id: id) }
        }
    }

    // MARK: Libro

    @ViewBuilder private func bookArea(width: CGFloat, height: CGFloat) -> some View {
        if spread {
            let spec = FanSpec.spread
            let arrowsW: CGFloat = wide(width) ? 76 * 2 + 32 : 0
            // En vertical el libro es más alto (casi cuadrado) para llenar la pantalla; en horizontal, apaisado.
            let aspect: CGFloat = height > width ? 1.1 : 1.5
            let bookW = max(480, min(width - arrowsW - 2 * spec.width - 56, (height - 360) * aspect, 900))
            HStack(spacing: 16) {
                                book(spec: spec).frame(width: bookW + 2 * spec.width, height: bookW / aspect)
            }
        } else {
            book(spec: .compact).frame(maxWidth: 460)
        }
    }

    private func wide(_ w: CGFloat) -> Bool { w > 1150 }

    /// El libro: la página actual al centro y, a cada lado, las demás páginas en abanico 3D
    /// (como en la referencia). El abanico dice cuántas páginas quedan antes y después.
    private func book(spec: FanSpec) -> some View {
        let compact = spec.maxN == FanSpec.compact.maxN
        let next = Array(pages.dropFirst(index + 1).prefix(spec.maxN))
        let prev = Array(pages.prefix(index).suffix(spec.maxN).reversed())   // la más cercana primero
        return Group {
            if compact {
                face(rightBase, compact: true)
                    .overlay { if let t = turn { face(t.page, compact: true).modifier(TurnEffect(angle: angle)) } }
            } else {
                HStack(spacing: 0) {
                    PhotoScene(memory: pages[leftIndex]).id(leftIndex).transition(.opacity)
                    Rectangle().fill(Color.black.opacity(0.35)).frame(width: 3)   // lomo
                    face(rightBase, compact: false)
                        .overlay { if let t = turn { face(t.page, compact: false).modifier(TurnEffect(angle: angle)) } }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
        .padding(.horizontal, spec.width - 4)
        .overlay(alignment: .leading) { PageFan(pages: prev, side: .leading, spec: spec) }
        .overlay(alignment: .trailing) { PageFan(pages: next, side: .trailing, spec: spec) }
        .contentShape(Rectangle())
        .onTapGesture { Speaker.shared.stop(); entry = pages[index].id }      // tocar la página la abre
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Página \(index + 1) de \(pages.count). \(pages[index].fullDate). \(pages[index].title). \(pages[index].caption)")
        .accessibilityHint("Toca dos veces para abrir el recuerdo. Desliza hacia arriba o abajo para cambiar de página.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAdjustableAction { dir in go(dir == .increment ? 1 : -1) }
    }

    /// Cara de página: en iPad es la mitad derecha del libro; en iPhone es la página completa.
    @ViewBuilder private func face(_ i: Int, compact: Bool) -> some View {
        let m = pages[min(i, pages.count - 1)]
        VStack(alignment: .leading, spacing: 14) {
            if compact { PhotoScene(memory: m).aspectRatio(3 / 2, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)) }
            Text(m.caption).font(Hand.font(compact ? 30 : 40, relativeTo: .largeTitle)).foregroundStyle(Pal.ink)
                .dynamicTypeSize(.xLarge ... .xxxLarge)
                .fixedSize(horizontal: false, vertical: true)
            Text(m.title).font(.title2.weight(.heavy)).foregroundStyle(Pal.text)
                .dynamicTypeSize(.xLarge ... .xxxLarge).fixedSize(horizontal: false, vertical: true)
            Label(m.hasStory ? "Con historia · \(m.duration ?? "")" : "Sin historia todavía",
                  systemImage: m.hasStory ? "waveform" : "mic.slash")
                .font(.headline).foregroundStyle(m.hasStory ? Pal.ink : Pal.text2)
                .dynamicTypeSize(.xLarge ... .xxxLarge).fixedSize(horizontal: false, vertical: true)
            if !compact { Spacer(minLength: 0) }
            Text("Lo agregó \(m.addedBy)").font(.headline).foregroundStyle(Pal.text2)
        }
        .padding(compact ? 16 : 28)
        .frame(maxWidth: .infinity, maxHeight: compact ? nil : .infinity, alignment: .topLeading)
        .background(Pal.surface)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 14 : 0, style: .continuous))
    }

    // MARK: Paso de página

    private func go(_ d: Int) {
        let n = index + d
        guard n >= 0, n < pages.count, turn == nil else { return }
        Speaker.shared.stop()
        if reduceMotion { withAnimation(.easeInOut(duration: 0.3)) { index = n; leftIndex = n }; return }
        if d > 0 {
            turn = Turn(page: index, forward: true); angle = 0; target = n
            withAnimation(.easeInOut(duration: 0.6)) { angle = -90; leftIndex = n } completion: {
                index = n; turn = nil; angle = 0
            }
        } else {
            turn = Turn(page: n, forward: false); angle = -90; target = index
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 40_000_000)
                withAnimation(.easeInOut(duration: 0.6)) { angle = 0; leftIndex = n } completion: {
                    index = n; turn = nil
                }
            }
        }
    }
}

// MARK: - Página de un recuerdo: foto con nombres, audio y transcripción (o «Comienza una nueva historia»)

struct MemoryEntry: View {
    let id: UUID
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var playing = false
    @State private var progress = 0.0
    @State private var listening = false

    private var memory: Memory? { app.memories.first { $0.id == id } }

    var body: some View {
        if let m = memory {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(m.fullDate).font(.largeTitle.weight(.heavy)).foregroundStyle(Pal.text)
                        .accessibilityAddTraits(.isHeader)
                    if hSize == .regular {
                        HStack(alignment: .top, spacing: 28) {
                            photo(m).frame(maxWidth: .infinity)
                            story(m).frame(maxWidth: .infinity)
                        }
                    } else {
                        photo(m)
                        story(m)
                    }
                    actions(m)
                }
                .padding(20)
                .frame(maxWidth: 1000).frame(maxWidth: .infinity)
            }
            .background { SkinBackground() }
        }
    }

    private func photo(_ m: Memory) -> some View {
        PhotoScene(memory: m)
            .aspectRatio(hSize == .regular ? 3 / 4 : 4 / 3, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder private func story(_ m: Memory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(m.caption).font(Hand.font(36, relativeTo: .largeTitle)).foregroundStyle(Pal.ink)
            if m.hasStory {
                // reproductor: un botón grande, barra y duración
                HStack(spacing: 16) {
                    Button { togglePlay(m) } label: {
                        Image(systemName: playing ? "pause.fill" : "play.fill").font(.title.weight(.heavy))
                            .frame(width: 76, height: 76).foregroundStyle(Pal.onInk)
                            .background(Pal.ink, in: Circle())
                    }
                    .accessibilityLabel(playing ? "Pausar" : "Escuchar la historia")
                    ProgressView(value: progress).tint(Pal.ink).scaleEffect(y: 2.2)
                    Text(m.duration ?? "").font(.title3.weight(.bold).monospacedDigit()).foregroundStyle(Pal.text)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lo que contaste").font(.headline).foregroundStyle(Pal.text2)
                    Text(m.story).font(Hand.font(30, relativeTo: .title)).foregroundStyle(Pal.text)
                        .lineSpacing(6).fixedSize(horizontal: false, vertical: true)
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(Pal.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Comienza una nueva historia").font(.title.weight(.heavy)).foregroundStyle(Pal.text)
                    Text("Cuéntame qué recuerdas de esta foto y yo la guardo aquí.")
                        .font(.title3).foregroundStyle(Pal.text2)
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(Pal.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }

    @ViewBuilder private func actions(_ m: Memory) -> some View {
        VStack(spacing: 12) {
            if m.hasStory {
                Button {
                    Speaker.shared.stop(); dismiss()
                    Task { try? await Task.sleep(nanoseconds: 400_000_000); app.section = .asistente }
                } label: { Label("Agregar más recuerdos", systemImage: "plus") }
                    .buttonStyle(BigButton())
            } else {
                Button { record(m) } label: {
                    Label(listening ? "Te escucho…" : "Toca y cuenta", systemImage: listening ? "waveform" : "mic.fill")
                        .symbolEffect(.variableColor.iterative, isActive: listening && !reduceMotion)
                }
                .buttonStyle(BigButton()).disabled(listening)
            }
            Button("Volver al álbum") { Speaker.shared.stop(); dismiss() }.buttonStyle(BigButton(kind: .outline))
        }
        .frame(maxWidth: 520).frame(maxWidth: .infinity)
    }

    // MARK: Demostración (voz y grabación simuladas)

    private func togglePlay(_ m: Memory) {
        if playing { Speaker.shared.stop(); playing = false; return }
        Speaker.shared.speak(m.story)
        playing = true; progress = 0
        let total = max(2, Double(m.story.split(separator: " ").count) * 0.45)
        Task { @MainActor in
            var t = 0.0
            while playing && t < total {
                try? await Task.sleep(nanoseconds: 100_000_000)
                t += 0.1; progress = min(1, t / total)
            }
            playing = false; progress = playing ? progress : 0
        }
    }

    private func record(_ m: Memory) {
        listening = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            listening = false
            app.setStory(m.id, story: "Fue el primer coche que tuvimos. Ramón lo compró con sus ahorros y le pusimos de nombre Pepe.", duration: "0:42")
        }
    }
}
