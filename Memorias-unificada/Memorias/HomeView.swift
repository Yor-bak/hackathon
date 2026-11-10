import SwiftUI

// MARK: - Datos del día (SINTÉTICOS)

enum NodeKind { case task, session }

struct DayNode: Identifiable {
    let id: String
    let kind: NodeKind
    let title: String
    let minutes: Int?          // minutos desde medianoche; nil en las sesiones
    let icon: SketchKind
    var needsCheck = false     // pastillas: hay que confirmarlas
    var session: Session? = nil  // sesiones con el asistente de IA

    /// Orden del boceto: tarea, sesión con el asistente, tarea, sesión, ... a lo largo del día.
    static let today: [DayNode] = [
        DayNode(id: "pm", kind: .task, title: "Pastilla de la mañana", minutes: 8 * 60, icon: .pill, needsCheck: true),
        DayNode(id: "m1", kind: .session, title: "", minutes: nil, icon: .thought, session: Sample.sessions[0]),
        DayNode(id: "cafe", kind: .task, title: "Café con pan", minutes: 11 * 60, icon: .cup),
        DayNode(id: "m2", kind: .session, title: "", minutes: nil, icon: .thought, session: Sample.sessions[1]),
        DayNode(id: "ana", kind: .task, title: "Videollamada con Ana", minutes: 15 * 60, icon: .video),
        DayNode(id: "pt", kind: .task, title: "Pastilla de la tarde", minutes: 18 * 60, icon: .pill, needsCheck: true),
        DayNode(id: "cena", kind: .task, title: "Cena", minutes: 20 * 60, icon: .fork),
    ]
}

private enum NodeState { case past, current, future }

// MARK: - Pantalla principal: "Mi día" (dibujada a mano, tinta negra sobre papel acuarela)

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var circleBase: CGFloat = 104
    @State private var pulse = false

    var body: some View {
        // Este lector SÍ respeta la zona segura: así mide cuánto ocupa la barra inferior (+ el indicador de inicio).
        GeometryReader { outer in dayContent(barInset: outer.safeAreaInsets.bottom) }
    }

    /// El contenido llega hasta el borde de la pantalla y se desliza por debajo de la barra (translúcida), sin cortarse.
    private func dayContent(barInset: CGFloat) -> some View {
        GeometryReader { geo in
        let landscape = geo.size.width > geo.size.height
        TimelineView(.periodic(from: .now, by: 60)) { ctx in
            let now = ctx.date
            let mins = Fmt.cal.component(.hour, from: now) * 60 + Fmt.cal.component(.minute, from: now)
            let nodes = DayNode.today
            // El nodo actual es la primera tarea que aún no pasó (con 30 min de gracia).
            let cur = nodes.firstIndex { $0.kind == .task && ($0.minutes ?? 0) + 30 > mins }

            VStack(spacing: 0) {
                topBar
                header(now)
                if app.homeMode == .day && Skin.id == .duo { memoBanner(nodes: nodes, current: cur).frame(maxWidth: 640).padding(.horizontal, 16).padding(.top, 2) }
                if app.homeMode == .calendar {
                    MonthCalendarView()
                        .contentMargins(.bottom, barInset, for: .scrollContent)
                } else {
                if hSize == .regular && landscape {
                    // iPad horizontal: el camino corre a lo ancho, en zigzag arriba y abajo.
                    GeometryReader { g in
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                horizontalPath(nodes: nodes, current: cur, height: g.size.height - barInset)
                                    .padding(.horizontal, 24)
                            }
                            .task {
                                try? await Task.sleep(nanoseconds: 600_000_000)
                                if let cur { withAnimation { proxy.scrollTo("col\(cur)", anchor: .center) } }
                            }
                        }
                    }
                } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        path(nodes: nodes, current: cur)
                            .padding(.top, 10).padding(.bottom, 40)
                    }
                    // El camino se desliza POR DEBAJO de la barra inferior (translúcida y con desvanecido): lo último queda por encima de ella.
                    .contentMargins(.bottom, barInset, for: .scrollContent)
                    .mask(
                        VStack(spacing: 0) {   // desvanecido arriba: ningún texto queda cortado a medias
                            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 44)
                            Rectangle()
                        }
                    )
                    .task {
                        // esperar a que el camino tenga su tamaño y centrar el "AHORA"
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        if let cur { proxy.scrollTo("row\(cur)", anchor: UnitPoint(x: 0.5, y: 0.45)) }
                    }
                }
                }
                }
            }
        }
        .background { SkinBackground() }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false)) { pulse = true }
        }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Barra superior: Estoy perdido (izq.) y Perfil (der.)

    private var topBar: some View {
        HStack(alignment: .top) {
            Button { app.screen = .perdido } label: {
                HStack(spacing: 10) {
                    SketchIcon(kind: .signpost).frame(width: 38, height: 38)
                    Text("Estoy perdido").font(.headline.weight(.heavy)).foregroundStyle(Skin.ink)
                        .lineLimit(2).minimumScaleFactor(0.8)
                }
                .padding(.leading, 14).padding(.trailing, 20).padding(.vertical, 10)
                .frame(minHeight: 62)
                .background { SkinFrame(radius: 31, seed: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Te ayuda a saber dónde estás y a llamar a tu familia")
            Spacer(minLength: 12)
            Button { app.screen = .perfil } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Medallion(seed: 2, line: 3)
                        SketchIcon(kind: .person).padding(15)
                    }
                    .frame(width: 66, height: 66)
                    Text("Perfil").font(.footnote.weight(.heavy)).foregroundStyle(Skin.ink)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mi perfil")
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 2)
        .dynamicTypeSize(.xLarge ... .xxxLarge)
    }

    /// Dos pestañas de papel con nombre: «Mi día» y «Calendario». La elegida va en marcador ámbar y más grande.
    private func header(_ now: Date) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                modeTab("Mi día", icon: .sun, mode: .day, seed: 3)
                modeTab("Calendario", icon: .calendar, mode: .calendar, seed: 8)
            }
            .frame(maxWidth: 560)
        }
        .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 4)
        .dynamicTypeSize(.xLarge ... .xxLarge)
    }

    /// Memo resume lo que toca ahora; al tocarlo, lo lee en voz alta.
    private func memoBanner(nodes: [DayNode], current: Int?) -> some View {
        // Mensajes cortos: el banner ocupa dos líneas como máximo y no le quita lugar al camino.
        let text: String = {
            guard let c = current else { return "¡Buen trabajo hoy, Carmen!" }
            let n = nodes[c]
            if n.kind == .session { return "¿Me cuentas «\(n.session?.title ?? "una historia")»?" }
            return "Ahora toca: \(n.title.lowercased())."
        }()
        return MascotSays(text: text, mood: current == nil ? .happy : .normal, size: 62)
    }

    private func modeTab(_ label: String, icon: SketchKind, mode m: HomeMode, seed: Double) -> some View {
        let on = app.homeMode == m
        return Button { app.homeMode = m } label: {
            HStack(spacing: 8) {
                SketchIcon(kind: icon, color: on ? Skin.onAccent : Skin.ink).frame(width: on ? 32 : 26, height: on ? 32 : 26)
                Text(label).font(Skin.title(on ? 34 : 27, relativeTo: .title)).foregroundStyle(on ? Skin.onAccent : Skin.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background { SkinFrame(radius: 18, seed: seed, fill: 0.72, line: on ? 3.6 : 2.6, selected: on) }
            .offset(y: on ? 0 : 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Camino del día

    private func path(nodes: [DayNode], current: Int?) -> some View {
        let d = min(circleBase * (hSize == .regular ? 1.2 : 1), 150)
        let rowH = max(212, d + 110)
        return GeometryReader { g in
            let w = g.size.width
            let xs: [CGFloat] = [w * 0.26, w * 0.74]
            ZStack(alignment: .top) {
                // camino de puntitos detrás de los dibujos; lo recorrido más fuerte, lo que falta más suave
                ForEach(0..<(nodes.count - 1), id: \.self) { i in
                    let dir: CGFloat = i % 2 == 0 ? 1 : -1
                    let r = d / 2
                    let start = CGPoint(x: xs[i % 2] + dir * (r + 6), y: rowH * (CGFloat(i) + 0.4))
                    let end = CGPoint(x: xs[(i + 1) % 2] - dir * (r + 6), y: rowH * (CGFloat(i) + 1.4))
                    let walked = i < (current ?? nodes.count)
                    SkinTrail(start: start,
                              c1: CGPoint(x: start.x + dir * 64, y: start.y),
                              c2: CGPoint(x: end.x - dir * 64, y: end.y),
                              end: end, walked: walked, seed: Double(i) * 3.3)
                }
                VStack(spacing: 0) {
                    ForEach(Array(nodes.enumerated()), id: \.element.id) { i, n in
                        let state: NodeState = current == nil ? .past : (i == current ? .current : (i < current! ? .past : .future))
                        node(n, index: i, state: state, size: d)
                            .frame(width: 190)
                            .position(x: xs[i % 2], y: rowH * 0.4)
                            .frame(width: w, height: rowH)
                            .id("row\(i)")
                    }
                }
            }
        }
        .frame(height: rowH * CGFloat(nodes.count))
        .frame(maxWidth: hSize == .regular ? 900 : 560)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
    }

    /// Versión apaisada del camino: las paradas van de izquierda a derecha, alternando arriba y abajo.
    private func horizontalPath(nodes: [DayNode], current: Int?, height: CGFloat) -> some View {
        // En pantallas bajas (iPad mini en horizontal) los círculos se achican para que las dos filas quepan sin cortarse.
        let d = min(min(circleBase * 1.1, 140), max(76, (height - 170) / 1.7))
        let colW = max(250, d + 130)
        let h = max(height, 330)
        let nodeH = d + 150                // círculo + hora y nombre; el nodo se centra como un bloque
        let y0 = nodeH / 2 + 4
        let y1 = max(y0 + d * 0.7, h - nodeH / 2 - 4)
        let ys: [CGFloat] = [y0, y1]
        return ZStack(alignment: .topLeading) {
            ForEach(0..<(nodes.count - 1), id: \.self) { i in
                let dir: CGFloat = i % 2 == 0 ? 1 : -1
                let r = d / 2
                let cy = { (k: Int) in ys[k % 2] - nodeH / 2 + d / 2 + 8 }   // centro del círculo
                let start = CGPoint(x: colW * (CGFloat(i) + 0.5), y: cy(i) + dir * (r + 6))
                let end = CGPoint(x: colW * (CGFloat(i) + 1.5), y: cy(i + 1) - dir * (r + 6))
                let walked = i < (current ?? nodes.count)
                SkinTrail(start: start,
                          c1: CGPoint(x: start.x, y: start.y + dir * 64),
                          c2: CGPoint(x: end.x, y: end.y - dir * 64),
                          end: end, walked: walked, seed: Double(i) * 3.3)
            }
            HStack(spacing: 0) {
                ForEach(Array(nodes.enumerated()), id: \.element.id) { i, n in
                    let state: NodeState = current == nil ? .past : (i == current ? .current : (i < current! ? .past : .future))
                    node(n, index: i, state: state, size: d)
                        .frame(width: 210)
                        .position(x: colW / 2, y: ys[i % 2])
                        .frame(width: colW, height: h)
                        .id("col\(i)")
                }
            }
        }
        .frame(width: colW * CGFloat(nodes.count), height: h)
    }

    @ViewBuilder private func node(_ n: DayNode, index: Int, state: NodeState, size d: CGFloat) -> some View {
        let key = "0-\(n.id)"
        let confirmed = app.done.contains(key)
        let isSession = n.kind == .session
        let sessionDone = n.session.map { app.doneSessions[$0.id] != nil } ?? false
        let isDone = isSession ? sessionDone : (confirmed || state == .past && !n.needsCheck)
        // pastilla pasada sin confirmar: pide un toque, sin regañar
        let pending = n.needsCheck && state == .past && !confirmed
        let title = isSession ? (n.session?.title ?? "Sesión") : n.title
        let sub: String = isSession ? (sessionDone ? "Ya está en tu álbum" : "Cuéntalo en tus recuerdos")
                                    : (pending ? "Toca si ya la tomaste" : Fmt.timeString(minutes: n.minutes ?? 0))
        let size = state == .current ? d * 1.18 : d

        Button {
            if isSession, let s = n.session {
                if let i = app.albumIndex(for: s) { app.openAlbum(at: i) } else { app.startSession(s) }
            }
            else if n.needsCheck { app.toggleDone(key, title: n.title) }
            else { Speaker.shared.speak("\(n.title), a las \(Fmt.timeString(minutes: n.minutes ?? 0))") }
        } label: {
            VStack(spacing: state == .current ? 18 : 10) {
                ZStack {
                    if state == .current && !reduceMotion {
                        Circle().stroke(Skin.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: size, height: size)
                            .scaleEffect(pulse ? 1.38 : 1).opacity(pulse ? 0 : 0.9)
                    }
                    drawing(n, index: index, state: state, size: size, done: isDone, pending: pending)
                }
                .frame(width: size, height: size)

                tag(title: title, sub: sub, isSession: isSession, pending: pending, current: state == .current, index: index)
            }
            .frame(minWidth: 60, minHeight: 60)
            .dynamicTypeSize(.xLarge ... .xxxLarge)   // el camino tiene ancho fijo: sus etiquetas no crecen más
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(sub)\(state == .current ? ", ahora" : "")\(isDone ? ", hecho" : "")")
        .accessibilityAddTraits(.isButton)
    }

    /// El dibujo de cada momento: círculo a pluma con su icono; lo hecho va rayado a lápiz y con palomita;
    /// lo de ahora, resaltado con marcador ámbar; las sesiones con el asistente, una nube de pensamiento con un micrófono.
    @ViewBuilder
    private func drawing(_ n: DayNode, index: Int, state: NodeState, size: CGFloat, done: Bool, pending: Bool) -> some View {
        let seed = Double(index) * 1.7
        if n.kind == .session {
            ZStack {
                SketchIcon(kind: .thought).frame(width: size * 1.15, height: size * 1.15)
                SketchIcon(kind: .mic).frame(width: size * 0.34, height: size * 0.34).offset(y: -size * 0.14)
                if done {
                    ZStack {
                        Circle().fill(Skin.card)
                        Circle().strokeBorder(Skin.line.opacity(0.6), lineWidth: 1.2)
                        SketchIcon(kind: .check).padding(7)
                    }
                    .frame(width: size * 0.34, height: size * 0.34)
                    .offset(x: size * 0.36, y: size * 0.3)
                }
            }
        } else {
            ZStack {
                Medallion(seed: seed, current: state == .current, done: done, pending: pending)
                SketchIcon(kind: n.icon, color: state == .current ? Skin.onAccent : Skin.ink).frame(width: size * 0.5, height: size * 0.5)
                if done {
                    ZStack {
                        Circle().fill(Skin.card)
                        Circle().strokeBorder(Skin.line.opacity(0.6), lineWidth: 1.2)
                        SketchIcon(kind: .check).padding(7)
                    }
                    .frame(width: size * 0.34, height: size * 0.34)
                    .offset(x: size * 0.36, y: size * 0.34)
                }
            }
        }
    }

    /// Etiqueta de papel con borde a pluma; «AHORA» va con marcador ámbar encima.
    private func tag(title: String, sub: String, isSession: Bool, pending: Bool, current: Bool, index: Int) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(isSession ? Skin.title(24, relativeTo: .title3) : .headline.weight(.heavy))
                .foregroundStyle(Skin.ink)
                .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
            Text(sub).font(.subheadline.weight(.heavy)).foregroundStyle(Skin.ink)
                .padding(.horizontal, 4)
                .background(alignment: .bottom) {   // subrayado de marcador en lo que pide atención
                    if pending { Rectangle().fill(Skin.accent.opacity(0.85)).frame(height: 9).offset(y: -2) }
                }
                .multilineTextAlignment(.center).lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14).padding(.top, current ? 16 : 10).padding(.bottom, 10)
        .background { SkinFrame(radius: 10, seed: Double(index) + 7, fill: 0.74, tape: index % 2 == 0) }
        .overlay(alignment: .top) {
            if current {
                Text("AHORA").font(.footnote.weight(.heavy)).foregroundStyle(Skin.onAccent).lineLimit(1).fixedSize()
                    .padding(.horizontal, 16).padding(.vertical, 3)
                    .background { Skin.id == .sketch ? AnyView(RoughRect(radius: 4, seed: 4).fill(Skin.accent)) : AnyView(Rectangle().fill(Skin.accent)) }
                    .rotationEffect(.degrees(-3))
                    .offset(y: -14)
            }
        }
        .rotationEffect(.degrees(index % 2 == 0 ? -1.6 : 1.4))
    }
}
