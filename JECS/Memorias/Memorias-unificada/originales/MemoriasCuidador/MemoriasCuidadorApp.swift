import SwiftUI

@main
struct MemoriasCuidadorApp: App {
    @State private var store = AppStore()

    init() {
        // Títulos de pantalla con la letra redondeada del sistema visual (respeta Dynamic Type).
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Theme.background)
        nav.shadowColor = .clear
        func roundedFont(_ size: CGFloat) -> UIFont? {
            let base = UIFont.systemFont(ofSize: size, weight: .heavy)
            return base.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: size) }
        }
        if let large = roundedFont(34), let small = roundedFont(19) {
            nav.largeTitleTextAttributes = [
                .font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large),
                .foregroundColor: UIColor.white
            ]
            nav.titleTextAttributes = [
                .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: small),
                .foregroundColor: UIColor.white
            ]
        }
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = nav
        bar.scrollEdgeAppearance = nav
        bar.compactAppearance = nav
        // SwiftUI a veces solo respeta las propiedades directas de la barra.
        bar.largeTitleTextAttributes = nav.largeTitleTextAttributes
        bar.titleTextAttributes = nav.titleTextAttributes
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(\.locale, Locale(identifier: "es_MX"))
                .preferredColorScheme(.dark)
                .tint(Theme.ink)
                .fontWeight(.bold)                       // cuerpo y controles: SF Pro bold
                .dynamicTypeSize(TypeRange.app)          // de xLarge a accessibility5
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store

        // La barra del sistema se esconde: la propia (medallones) va abajo.
        TabView(selection: $store.selectedTab) {
            InicioView().tag(AppTab.inicio).toolbar(.hidden, for: .tabBar)
            CalendarioView().tag(AppTab.calendario).toolbar(.hidden, for: .tabBar)
            AlertasView().tag(AppTab.alertas).toolbar(.hidden, for: .tabBar)
            RecuerdosView().tag(AppTab.recuerdos).toolbar(.hidden, for: .tabBar)
            FamiliaView().tag(AppTab.familia).toolbar(.hidden, for: .tabBar)
        }
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MedallionTabBar()
                // El aviso de 8 s flota justo encima de la barra, sin mover el contenido.
                .overlay(alignment: .top) {
                    UndoBanner()
                        .alignmentGuide(.top) { $0[.bottom] + 14 }
                        .animation(.spring(duration: 0.35), value: store.notice?.id)
                }
        }
    }
}
