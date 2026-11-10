import SwiftUI

@main
struct MemoriasApp: App {
    @StateObject private var app = AppState()

    init() { CuidadorAppearance.install() }

    var body: some Scene {
        WindowGroup {
            TabView {
                // Paciente (Carmen): la app original de Memorias.
                RootView()
                    .environmentObject(app)
                    .dynamicTypeSize(.xLarge ... .accessibility5)
                    .tint(Pal.ink)
                    .preferredColorScheme(.dark)
                    .tabItem { Label("Carmen", systemImage: "person.fill") }

                // Cuidador: la app MemoriasCuidador.
                CuidadorRootView()
                    .tabItem { Label("Cuidador", systemImage: "heart.text.square.fill") }

                // Apple Watch de Carmen: avisos suaves y lo que se comparte con el cuidador (solo interfaz).
                RelojView()
                    .tint(Pal.ink)
                    .tabItem { Label("Reloj", systemImage: "applewatch") }
            }
            .preferredColorScheme(.dark)
        }
    }
}

/// Aviso de confirmación con "Deshacer". Se queda 8 s.
struct ToastBar: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        if let t = app.toast {
            HStack(spacing: 14) {
                if Skin.id == .duo { Mascot(size: 44, mood: .happy).frame(width: 52, height: 48) }
                else { Image(systemName: "checkmark.circle.fill").font(.title).foregroundStyle(Skin.id == .sketch ? Pal.pen : Skin.accent).accessibilityHidden(true) }
                Text(t.message).font(.title3.weight(.bold)).foregroundStyle(Skin.id == .sketch ? Pal.text : Skin.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let undo = t.undo {
                    Button("Deshacer") { undo(); app.dismissToast() }
                        .buttonStyle(FilledPill())
                }
            }
            .padding(16)
            .background(Skin.id == .sketch ? Pal.surface2 : Skin.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Skin.id == .sketch ? Pal.pen : Skin.line, lineWidth: 3))
            .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .animation(.easeOut(duration: 0.25), value: app.toast?.id)
            .id(t.id)
        }
    }
}

/// "Estoy perdido": calma primero, una acción después. Memo acompaña y habla despacio. Dirección y llamada simuladas.
struct LostScreen: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    private let calm = "Tranquila, Carmen. Estás en casa. Respira despacio, yo estoy contigo."

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Estás en casa").font(Skin.title(40, relativeTo: .largeTitle)).foregroundStyle(Pal.ink)
                    .dynamicTypeSize(.xLarge ... .accessibility1)
                    .multilineTextAlignment(.center).padding(.top, 12)
                VStack(spacing: 6) {
                    if Skin.id == .duo { Mascot(size: 150, mood: .happy).frame(height: 170) }
                    Button { Speaker.shared.speak(calm) } label: {
                        Text("Tranquila, Carmen.\nYo estoy contigo.").font(.title.weight(.heavy)).foregroundStyle(Skin.ink)
                            .dynamicTypeSize(.xLarge ... .accessibility1)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20).padding(.vertical, 16).frame(maxWidth: .infinity)
                            .background { SkinFrame(radius: 20, seed: 3, fill: 1) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Toca para escucharlo otra vez")
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tu casa está en").font(.headline).foregroundStyle(Pal.text2)
                    Text("Calle de los Naranjos 12, Puebla").font(.title2.weight(.bold)).foregroundStyle(Pal.text)
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background { SkinFrame(radius: 20, seed: 5, fill: 1) }

                Button {
                    app.confirm("Llamando a Ana…"); dismiss()
                } label: { Label("Llamar a Ana", systemImage: "phone.fill") }
                    .buttonStyle(BigButton())
                Button { dismiss() } label: { Label("Volver a Mi día", systemImage: "chevron.left") }
                    .buttonStyle(BigButton(kind: .outline))
            }
            .padding(24)
            .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background { SkinBackground() }
        .onAppear { Speaker.shared.speak(calm) }
        .onDisappear { Speaker.shared.stop() }
    }
}

struct ProfileScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Circle().fill(Pal.ink).frame(width: 140, height: 140)
                .overlay(Text("C").font(.system(size: 64, weight: .heavy)).foregroundStyle(Pal.onInk))
                .accessibilityHidden(true)
            Text("Carmen").font(.largeTitle.weight(.heavy)).foregroundStyle(Pal.text)
            Text("Tu familiar de confianza es Ana.").font(.title3).foregroundStyle(Pal.text2)
                .multilineTextAlignment(.center)
            Spacer()
            Button { dismiss() } label: { Label("Volver a Mi día", systemImage: "chevron.left") }
                .buttonStyle(BigButton())
        }
        .padding(24)
        .frame(maxWidth: 600).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { SkinBackground() }
    }
}

// MARK: - Raíz: contenido + barra inferior fija

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch app.section {
                case .none: HomeView()
                case .familia: FamilyTreeView(store: app.family)
                case .recuerdos: LibroView()   // libro de fotos 3D (antes: RecuerdosView(startAt: app.albumStart))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            MainTabBar()
        }
        .background { SkinBackground() }
        .overlay(alignment: .bottom) { ToastBar().padding(.horizontal, 16).padding(.bottom, 96) }
        .fullScreenCover(item: $app.screen) { s in
            switch s {
            case .perdido: LostScreen()
            case .perfil: ProfileScreen()
            }
        }
    }
}

/// Barra inferior baja y siempre visible. El apartado elegido sobresale por encima de la barra.
/// Fuera de «Mi día» aparece un botón «Mi día» (sol) para volver.
struct MainTabBar: View {
    @EnvironmentObject var app: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            homeItem
            item("Mi familia", icon: .tree, section: .familia, seed: 3)
            item("Mis recuerdos", icon: .book, section: .recuerdos, seed: 8)
        }
        .padding(.horizontal, 12).padding(.top, 4).padding(.bottom, 0)
        .background(Rectangle().fill(Skin.barFill).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { SkinRule(seed: 2).offset(y: -4) }
        .dynamicTypeSize(.xLarge ... .xxLarge)       // 4 etiquetas en una fila: tope más bajo
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: app.section)
    }

    private func item(_ label: String, icon: SketchKind, section: MainSection, seed: Double) -> some View {
        let on = app.section == section
        let s: CGFloat = 50
        return Button {
            Speaker.shared.stop()
            if on { return }
            if section == .recuerdos { app.openAlbum(at: 0) } else { app.section = section }
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    Medallion(seed: seed, current: on, line: on ? 4 : 3)
                    SketchIcon(kind: icon, color: on ? Skin.onAccent : Skin.ink).frame(width: s * 0.5, height: s * 0.5)
                }
                .frame(width: s, height: s)
                                barLabel(label, on: on)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    private func barLabel(_ t: String, on: Bool) -> some View {
        Text(t).font(.footnote.weight(.heavy)).foregroundStyle(Skin.barText)
            .lineLimit(1).minimumScaleFactor(0.5).allowsTightening(true)
            .padding(.horizontal, 4)
            .background(alignment: .bottom) {
                if on { Rectangle().fill(Skin.accent.opacity(Skin.id == .sketch ? 1 : 0.85)).frame(height: 7).offset(y: -1).opacity(Skin.id == .sketch ? 1 : 0.0) }
            }
            .overlay(alignment: .bottom) {
                if on && Skin.id != .sketch { Rectangle().fill(Skin.accent).frame(height: 2.5).offset(y: 3) }
            }
    }

    /// «Mi día»: dibujo de un sol; siempre visible, igual que los demás.
    private var homeItem: some View {
        let on = app.section == nil
        return Button { Speaker.shared.stop(); app.section = nil } label: {
            VStack(spacing: 2) {
                ZStack {
                    Medallion(seed: 1, current: on, line: on ? 4 : 3)
                    SketchIcon(kind: .sun, color: on ? Skin.onAccent : Skin.ink).frame(width: 25, height: 25)
                }
                .frame(width: 50, height: 50)
                barLabel("Mi día", on: on)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mi día")
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}
