import SwiftUI
import Combine
import AVFoundation

// MARK: - IA (entrevistador y narrador)

/// Hace las preguntas. Hoy es un guion de ejemplo; se puede cambiar por un modelo real
/// (Foundation Models en el dispositivo o la API de Claude) sin tocar la vista.
protocol MemoryInterviewer {
    func firstQuestion(for page: BookPage) async -> String
    func followUp(for page: BookPage, history: [ChatMessage]) async -> String
}

/// Escribe la historia a partir de la conversación. También sustituible por un modelo real.
protocol MemoryStoryWriter {
    func compose(for page: BookPage, conversation: [ChatMessage]) async -> [String]
}

struct ScriptedInterviewer: MemoryInterviewer {
    func firstQuestion(for page: BookPage) async -> String {
        let names = page.faces.map(\.name)
        if names.count >= 2 {
            return "Veo a \(names.dropLast().joined(separator: ", ")) y a \(names.last!) en esta foto. ¿Dónde estaban ese día?"
        } else if let n = names.first {
            return "Veo a \(n) en esta foto. ¿Dónde estaban ese día?"
        }
        return "Cuéntame de esta foto. ¿Dónde fue y qué estaba pasando?"
    }

    func followUp(for page: BookPage, history: [ChatMessage]) async -> String {
        let answered = history.filter { $0.role == .user }.count
        let questions = [
            "Qué bonito. ¿Qué fue lo que más te hizo reír?",
            "¿Cómo te sentías ese día?",
            "¿Recuerdas algún olor, una canción o algo que comieron?",
            "Gracias por contármelo. Si quieres, ya puedo escribir tu historia. ¿O prefieres añadir algo más?",
        ]
        return questions[min(max(answered - 1, 0), questions.count - 1)]
    }
}

/// Une las respuestas de la persona en una narración en primera persona.
struct ScriptedStoryWriter: MemoryStoryWriter {
    func compose(for page: BookPage, conversation: [ChatMessage]) async -> [String] {
        try? await Task.sleep(for: .seconds(1.5))
        // La IA le cuenta la historia a la persona, hablándole de "tú".
        var out: [String] = []
        let names = page.faces.map(\.name)
        if names.count >= 2 {
            out.append("Tú estuviste con \(names.dropLast().joined(separator: ", ")) y \(names.last!).")
        } else if let n = names.first {
            out.append("Tú estuviste con \(n).")
        }
        // TODO: con un modelo real, reescribir cada respuesta en segunda persona.
        // Con el guion de ejemplo solo se introducen las respuestas tal como se dijeron.
        for m in conversation where m.role == .user {
            if case .text(let t) = m.content {
                let line = t.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty else { continue }
                let lowered = line.prefix(1).lowercased() + line.dropFirst()
                out.append("Me contaste que \(lowered)" + (".!?".contains(line.last!) ? "" : "."))
            }
        }
        out.append("Así es como quedó guardado este recuerdo.")
        return out
    }
}

// MARK: - Vista

struct MemoryDetailView: View {
    @Binding var page: BookPage
    var interviewer: MemoryInterviewer = ScriptedInterviewer()
    var writer: MemoryStoryWriter = ScriptedStoryWriter()
    @Environment(\.dismiss) private var dismiss

    @StateObject private var voice = VoiceOutput()
    @StateObject private var mic = VoiceInput()

    // Sesión de conversación por voz
    @State private var conversing = false
    @State private var session: [ChatMessage] = []
    @State private var currentQuestion = ""
    @State private var thinking = false
    @State private var composing = false
    @State private var hint: String?
    /// Persona del árbol genealógico a la que se tocó en la foto.
    @State private var openPerson: PersonLink?
    @State private var typedAnswer = ""

    private let paper = MemoryTheme.darkSurface
    private let ink = Color.white
    private let accent = MemoryTheme.amber
    private let onAccent = MemoryTheme.onAccent

    private var spinning: Bool { (voice.isSpeaking && !voice.isPaused) || mic.isListening || thinking || composing }
    private var answeredCount: Int { session.filter { $0.role == .user }.count }

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            ZStack {
                backdrop
                VStack(spacing: 18) {
                    HStack(spacing: 14) {
                        Button { voice.stop(); mic.stop(); dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(MemoryTheme.darkSurface))
                                .overlay(Circle().strokeBorder(MemoryTheme.edgeGray, lineWidth: 2))
                        }
                        .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeGray))
                        .accessibilityLabel("Cerrar")
                        Text(page.caption)
                            .font(.custom("ArialRoundedMTBold", size: 24, relativeTo: .title2))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    GeometryReader { area in
                        layout(area.size, landscape: landscape)
                    }
                    .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, 36)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .task {
            // Si la foto es real y aún no hay personas, las detecta (cara + cuerpo).
            if page.faces.isEmpty, let ui = page.uiImage {
                page.faces = await PersonDetector.detect(in: ui)
            }
        }
        .onDisappear { voice.stop(); mic.stop() }
        .fullScreenCover(item: $openPerson) { link in
            FamilyDetailView(store: FamilyStore.shared, id: link.id)
        }
    }

    /// Busca en el árbol genealógico a la persona marcada en la foto (por su nombre).
    private func openInTree(_ name: String) {
        let key = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if let m = FamilyStore.shared.members.first(where: {
            $0.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) == key
        }) {
            voice.stop()
            openPerson = PersonLink(id: m.id)
        } else {
            hint = "\(name) todavía no está en tu árbol. Agrégalo desde «Mi familia»."
        }
    }

    // MARK: Fondo

    private var backdrop: some View {
        ZStack {
            MemoryTheme.darkBackground
            LinearGradient(colors: page.placeholder, startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.45)
                .blur(radius: 90)
            if let image = page.image {
                Color.clear.overlay { image.resizable().scaledToFill() }.clipped().blur(radius: 60).opacity(0.35)
            }
            LinearGradient(colors: [.clear, MemoryTheme.darkBackground.opacity(0.7)],
                           startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }

    // MARK: Foto + disco

    /// Foto grande a la izquierda y el panel de la historia a la derecha.
    @ViewBuilder
    private func layout(_ size: CGSize, landscape: Bool) -> some View {
        if landscape {
            let panelW = size.width * 0.34
            let photoW = size.width - panelW - 24
            ZStack {
                polaroid
                    .frame(width: photoW, height: size.height)
                    .rotationEffect(.degrees(-1))
                    .position(x: photoW / 2, y: size.height / 2)
                panel
                    .frame(width: panelW, height: size.height)
                    .position(x: photoW + 24 + panelW / 2, y: size.height / 2)
            }
        } else {
            let panelH = size.height * 0.38
            let photoH = size.height - panelH - 20
            ZStack {
                polaroid
                    .frame(width: min(size.width, photoH * 0.95), height: photoH)
                    .rotationEffect(.degrees(-1))
                    .position(x: size.width / 2, y: photoH / 2)
                panel
                    .frame(width: size.width, height: panelH)
                    .position(x: size.width / 2, y: size.height - panelH / 2)
            }
        }
    }

    private var polaroid: some View {
        VStack(spacing: 0) {
            photo
                .padding([.top, .horizontal], 12)
            Text(page.caption.isEmpty ? " " : page.caption)
                .font(.custom("ArialRoundedMTBold", size: 26))
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(paper))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(MemoryTheme.edgeGray, lineWidth: 3))
        .shadow(color: .black.opacity(0.45), radius: 22, y: 12)
    }

    /// Foto elegida de la galería o tomada con la cámara.
    private func setPhoto(_ ui: UIImage) {
        page.uiImage = ui
        page.image = Image(uiImage: ui)
        page.faces = []
        Task { page.faces = await PersonDetector.detect(in: ui) }
    }

    /// Pasa un rectángulo normalizado de la foto a la vista. Con foto real tiene en cuenta el recorte
    /// (la foto llena el marco y se centra), para que los cuadros caigan sobre la persona correcta.
    private func scaled(_ r: CGRect, _ size: CGSize) -> CGRect {
        guard let s = page.uiImage?.size, s.width > 0, s.height > 0 else {
            return CGRect(x: r.minX * size.width, y: r.minY * size.height,
                          width: r.width * size.width, height: r.height * size.height)
        }
        let k = max(size.width / s.width, size.height / s.height)
        let w = s.width * k, h = s.height * k
        let ox = (size.width - w) / 2, oy = (size.height - h) / 2
        return CGRect(x: ox + r.minX * w, y: oy + r.minY * h, width: r.width * w, height: r.height * h)
    }

    private var photo: some View {
        GeometryReader { geo in
            ZStack {
                if let image = page.image {
                    Color.clear.overlay { image.resizable().scaledToFill() }.clipped()
                } else {
                    LinearGradient(colors: page.placeholder,
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    PhotoAddButton(size: 96) { ui in setPhoto(ui) }
                }
                ForEach(page.faces) { tag in
                    let blue = Color.white
                    let body = scaled(tag.person, geo.size)
                    let face = scaled(tag.face, geo.size)
                    // Persona completa (trazo discontinuo).
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(blue.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                        .frame(width: body.width, height: body.height)
                        .position(x: body.midX, y: body.midY)
                    // Cara (al tocarla se abre su biografía en el árbol).
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(blue, lineWidth: 2.5)
                        .frame(width: face.width, height: face.height)
                        .position(x: face.midX, y: face.midY)
                    Color.clear
                        .frame(width: max(face.width, 56), height: max(face.height, 56))
                        .contentShape(Rectangle())
                        .position(x: face.midX, y: face.midY)
                        .onTapGesture { openInTree(tag.name) }
                        .accessibilityLabel("\(tag.name). Toca para ver su biografía")
                        .accessibilityAddTraits(.isButton)
                    Text(tag.name)
                        .font(.custom("ArialRoundedMTBold", size: 20))
                        .foregroundStyle(MemoryTheme.onAccent)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(MemoryTheme.amber, in: Capsule())
                        .fixedSize()
                        .position(x: face.midX, y: max(face.minY - 20, 14))
                        .onTapGesture { openInTree(tag.name) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    // MARK: Panel

    private var panel: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(ink.opacity(0.12)).frame(height: 1)
            if conversing {
                conversationView
            } else if composing {
                composingView
            } else if let story = page.story, !story.sentences.isEmpty {
                storyView(story)
            } else {
                emptyState
            }
        }
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(paper))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(MemoryTheme.edgeGray, lineWidth: 3))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 14)
    }

    private var statusText: String {
        if composing { return "escribiendo tu historia…" }
        if mic.isListening { return "te escucho…" }
        if thinking { return "pensando…" }
        if voice.isSpeaking && conversing { return "hablando…" }
        if voice.isSpeaking { return "contando tu historia…" }
        return "te ayudo a recordar ese día"
    }

    private var header: some View {
        HStack(spacing: 12) {
            Orb(active: spinning).frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 1) {
                Text("Memento")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(ink)
                Text(statusText)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(ink.opacity(0.6))
            }
            Spacer()
        }
        .padding(.horizontal, 22).padding(.vertical, 18)
    }

    // MARK: Vacío (`is empty`)

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            Orb(active: true).frame(width: 110, height: 110)
            Text("Comienza una nueva historia")
                .font(.custom("ArialRoundedMTBold", size: 34, relativeTo: .title))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)
            Text("Memento te hará preguntas con su voz. Tú respóndele hablando.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(ink.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            HStack {
                Spacer()
                micPill(title: "Empezar")
            }
            .padding(16)
        }
    }

    private func micPill(title: String) -> some View {
        Button { Task { await beginConversation() } } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                Text(title).font(.system(.body, design: .rounded, weight: .bold))
            }
            .foregroundStyle(onAccent)
            .padding(.horizontal, 22).frame(height: 56)
            .background(Capsule().fill(accent))
        }
        .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeAmber))
        .accessibilityLabel(title)
    }

    // MARK: Conversación por voz

    private var conversationView: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            if thinking && currentQuestion.isEmpty {
                TypingDots()
            } else {
                Text(currentQuestion)
                    .font(.custom("ArialRoundedMTBold", size: 28, relativeTo: .title2))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)
                    .transition(.opacity)
                    .id(currentQuestion)
            }
            Spacer(minLength: 0)

            // Lo que la persona va diciendo, en vivo.
            if mic.isListening || !mic.transcript.isEmpty {
                Text(mic.transcript.isEmpty ? "…" : mic.transcript)
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(ink.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 22)
            }
            if let hint {
                Text(hint)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(MemoryTheme.amber)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)
            }
            if mic.unavailable { typedFallback }

            HStack(spacing: 14) {
                Button { Task { await finishConversation() } } label: {
                    Text("Terminar historia")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 16).frame(height: 44)
                        .background(Capsule().fill(MemoryTheme.darkSurface))
                        .overlay(Capsule().strokeBorder(MemoryTheme.edgeGray, lineWidth: 2))
                }
                .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeGray))
                .disabled(answeredCount == 0 || thinking || mic.isListening)
                .opacity(answeredCount == 0 ? 0.4 : 1)

                Spacer()

                Button { Task { await toggleAnswer() } } label: {
                    Image(systemName: mic.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(onAccent)
                        .frame(width: 68, height: 68)
                        .background(Circle().fill(mic.isListening ? MemoryTheme.red : accent))
                        .scaleEffect(mic.isListening ? 1.08 : 1)
                        .animation(.easeInOut(duration: 0.4), value: mic.isListening)
                }
                .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeAmber))
                .disabled(thinking)
                .opacity(thinking ? 0.5 : 1)
                .accessibilityLabel(mic.isListening ? "Terminar de responder" : "Responder hablando")
            }
            .padding(.horizontal, 22).padding(.vertical, 18)
        }
    }

    /// Si el reconocimiento de voz no está disponible (permiso denegado o sin servicio).
    private var typedFallback: some View {
        HStack(spacing: 8) {
            TextField("Reconocimiento de voz no disponible: escribe aquí", text: $typedAnswer)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(ink).tint(ink)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Capsule().fill(ink.opacity(0.07)))
                .onSubmit { Task { await submitTyped() } }
            Button { Task { await submitTyped() } } label: {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 30)).foregroundStyle(ink)
            }
        }
        .padding(.horizontal, 16)
    }

    private var composingView: some View {
        VStack(spacing: 16) {
            Spacer()
            TypingDots()
            Text("Memento está escribiendo tu historia")
                .font(.custom("ArialRoundedMTBold", size: 26, relativeTo: .title3))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(24)
    }

    // MARK: Historia (`!is empty`)

    private func storyView(_ story: MemoryStory) -> some View {
        VStack(spacing: 0) {
            listenBar
                .padding(.horizontal, 18).padding(.top, 14)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("transcripción")
                            .font(.custom("ArialRoundedMTBold", size: 22))
                            .foregroundStyle(ink.opacity(0.6))
                        ForEach(Array(story.sentences.enumerated()), id: \.offset) { i, sentence in
                            let active = voice.currentIndex == i
                            Text(sentence)
                                .font(.custom("ArialRoundedMTBold", size: 23, relativeTo: .body))
                                .foregroundStyle(ink.opacity(voice.currentIndex == nil || active ? 1 : 0.4))
                                .padding(.vertical, 2).padding(.horizontal, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(accent.opacity(active ? 0.3 : 0)))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(i)
                                .animation(.easeInOut(duration: 0.25), value: active)
                        }
                    }
                    .padding(.horizontal, 24).padding(.vertical, 20)
                }
                .onChange(of: voice.currentIndex) { _, new in
                    if let new { withAnimation { proxy.scrollTo(new, anchor: .center) } }
                }
            }
            HStack {
                Text("¿Se te olvidó algo?")
                    .font(.custom("ArialRoundedMTBold", size: 20))
                    .foregroundStyle(ink.opacity(0.55))
                Spacer()
                Button { Task { await beginConversation() } } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(onAccent)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(accent))
                }
                .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeAmber))
                .accessibilityLabel("Agregar más recuerdos a esta historia")
            }
            .padding(.horizontal, 22).padding(.vertical, 14)
        }
    }

    /// Arriba: opción de escuchar la historia (narrada por la IA).
    private var listenBar: some View {
        let story = page.story?.sentences ?? []
        let playing = voice.isSpeaking && voice.currentIndex != nil
        let duration = voice.estimatedDuration > 0 ? voice.estimatedDuration
                                                   : Double(story.joined(separator: " ").count) / 14.5
        return HStack(spacing: 12) {
            Button {
                if playing && !voice.isPaused { voice.pause() }
                else if voice.isPaused { voice.resume() }
                else { voice.narrate(story) }
            } label: {
                Image(systemName: playing && !voice.isPaused ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(onAccent)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(accent))
            }
            .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeAmber))
            .accessibilityLabel(playing && !voice.isPaused ? "Pausar historia" : "Escuchar historia")

            VStack(alignment: .leading, spacing: 6) {
                Text("Escuchar historia")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(ink)
                ZStack(alignment: .leading) {
                    Capsule().fill(ink.opacity(0.15)).frame(height: 4)
                    GeometryReader { g in
                        Capsule().fill(MemoryTheme.darkAction).frame(width: g.size.width * voice.progress, height: 4)
                    }.frame(height: 4)
                }
            }
            Text(format(duration * (1 - voice.progress)))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(ink.opacity(0.7))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(MemoryTheme.edgeGray.opacity(0.45)))
    }

    // MARK: Lógica

    private func beginConversation() async {
        voice.stop()
        session = []
        hint = nil
        conversing = true
        thinking = true
        currentQuestion = ""
        let q = await interviewer.firstQuestion(for: page)
        thinking = false
        currentQuestion = q
        voice.say(q)
    }

    private func toggleAnswer() async {
        hint = nil
        if mic.isListening {
            let text = mic.stop()
            guard !text.isEmpty else { hint = "No alcancé a escucharte, intenta otra vez."; return }
            await submit(text)
        } else {
            voice.stop()
            await mic.start()
        }
    }

    private func submitTyped() async {
        let text = typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        typedAnswer = ""
        await submit(text)
    }

    private func submit(_ text: String) async {
        session.append(ChatMessage(role: .user, content: .text(text)))
        thinking = true
        let q = await interviewer.followUp(for: page, history: session)
        try? await Task.sleep(for: .seconds(0.8))
        thinking = false
        session.append(ChatMessage(role: .ai, content: .text(q)))
        currentQuestion = q
        voice.say(q)
    }

    private func finishConversation() async {
        voice.stop(); mic.stop()
        conversing = false
        composing = true
        let new = await writer.compose(for: page, conversation: session)
        var story = page.story ?? MemoryStory(sentences: [])
        story.sentences += new
        story.conversation += session
        page.story = story
        composing = false
        voice.narrate(story.sentences)       // la IA cuenta la historia en cuanto está lista
    }

    private func format(_ t: Double) -> String {
        let s = max(Int(t.rounded()), 0)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}


// MARK: - Componentes

/// Esfera animada que representa a la IA.
/// Memo, el elefantito: la voz de la IA.
private struct Orb: View {
    var active: Bool
    var body: some View {
        GeometryReader { g in
            Mascot(size: min(g.size.width, g.size.height) * 0.78, mood: active ? .happy : .normal)
                .frame(width: g.size.width, height: g.size.height)
        }
    }
}

private struct TypingDots: View {
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle().fill(Color.gray.opacity(0.7)).frame(width: 8, height: 8)
                        .offset(y: -4 * max(0, sin(t * 6 - Double(i) * 0.7)))
                }
            }
        }
    }
}

private struct PersonLink: Identifiable { let id: UUID }
