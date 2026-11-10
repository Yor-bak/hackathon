import SwiftUI

/// Raíz de la parte del cuidador (antes `CuidadorRootView` de MemoriasCuidador).
struct CuidadorRootView: View {
    @State private var store = AppStore()

    var body: some View {
        CuidadorTabs()
            .environment(store)
            .environment(\.locale, Locale(identifier: "es_MX"))
            .preferredColorScheme(.dark)
            .tint(Theme.ink)
            .fontWeight(.bold)
            .dynamicTypeSize(TypeRange.app)
    }
}

private struct CuidadorTabs: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store

        TabView(selection: $store.selectedTab) {
            InicioView().tag(AppTab.inicio).toolbar(.hidden, for: .tabBar)
            CalendarioView().tag(AppTab.calendario).toolbar(.hidden, for: .tabBar)
            AlertasView().tag(AppTab.alertas).toolbar(.hidden, for: .tabBar)
            CuidadorRecuerdosView().tag(AppTab.recuerdos).toolbar(.hidden, for: .tabBar)
            FamilyTreeView(store: FamilyStore.shared).safeAreaPadding(.bottom, 104).tag(AppTab.familia).toolbar(.hidden, for: .tabBar)
        }
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MedallionTabBar()
                .environment(\.barFade, store.selectedTab == .familia ? 0 : Skin.barFade)
                .overlay(alignment: .top) {
                    UndoBanner()
                        .alignmentGuide(.top) { $0[.bottom] + 14 }
                        .animation(.spring(duration: 0.35), value: store.notice?.id)
                }
        }
    }
}

enum CuidadorAppearance {
    /// Apariencia de las barras de navegación del cuidador (se llama una vez al iniciar).
    static func install() {
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
                .foregroundColor: UIColor.white]
            nav.titleTextAttributes = [
                .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: small),
                .foregroundColor: UIColor.white]
        }
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = nav
        bar.scrollEdgeAppearance = nav
        bar.compactAppearance = nav
        bar.largeTitleTextAttributes = nav.largeTitleTextAttributes
        bar.titleTextAttributes = nav.titleTextAttributes
    }
}
