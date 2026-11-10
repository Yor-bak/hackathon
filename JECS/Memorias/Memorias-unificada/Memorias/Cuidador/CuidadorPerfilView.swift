import SwiftUI

struct PerfilView: View {
    @Environment(AppStore.self) private var store
    @State private var showWatchInfo = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenTitle(text: "Perfil")
                // Tarjeta de Ana
                HStack(spacing: 16) {
                    Text("A")
                        .font(.title.bold())
                        .foregroundStyle(Theme.ink)
                        .frame(width: 60, height: 60)
                        .overlay(Circle().stroke(Theme.ink, lineWidth: 2))
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Ana")
                            .font(.rounded(32, relativeTo: .title))
                            .foregroundStyle(Theme.text)
                        Text("Hija · cuidadora principal")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                }
                .padding(12)
                .cardStyle()

                SectionTitle(text: "A quién cuido").padding(.top, 8)
                ForEach(store.people) { person in
                    PersonRow(initial: person.initial,
                              title: person.name,
                              subtitle: person.hasWatch ? "Apple Watch conectado" : "Sin Apple Watch vinculado",
                              trailing: person.hasWatch ? "\(person.battery ?? 0) %" : nil)
                }

                // El árbol ahora es una pestaña: este botón lleva a ella.
                Button {
                    store.selectedTab = .familia
                } label: {
                    HStack {
                        Label("Ver árbol de la familia de Carmen", systemImage: "tree")
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.secondaryText)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 60)
                    .cardStyle()
                }

                SectionTitle(text: "Círculo de cuidado").padding(.top, 8)
                PersonRow(initial: "A", title: "Ana (tú)",
                          subtitle: "Todo: pastillas, ubicación y recuerdos", trailing: nil, outlined: true)
                PersonRow(initial: "L", title: "Luis · hermano",
                          subtitle: "Ve ubicación y alertas", trailing: nil)

                Text("Carmen y Don Ernesto saben qué ve su familia: ubicación, pastillas y reloj. Datos de ejemplo.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.top, 4)

                Button {
                    showWatchInfo = true
                } label: {
                    Label("Agregar Apple Watch", systemImage: "applewatch")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 24)
            .readableWidth()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .principal) { HiddenNavTitle() } }
        .alert("Apple Watch", isPresented: $showWatchInfo) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("En la demo el reloj es simulado. En la versión real, la app del reloj comparte los datos con el cuidador.")
        }
    }
}

private struct PersonRow: View {
    let initial: String
    let title: String
    let subtitle: String
    let trailing: String?
    var outlined = false

    var body: some View {
        HStack(spacing: 14) {
            Text(initial)
                .font(.rounded(20, relativeTo: .headline))
                .foregroundStyle(outlined ? Theme.onInk : Theme.text)
                .frame(width: 52, height: 52)
                .chunky(fill: outlined ? Theme.ink : Theme.upcoming,
                        edge: outlined ? Theme.inkEdge : Theme.upcomingEdge, radius: 26, depth: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.headline).foregroundStyle(Theme.text)
                Text(subtitle).font(.subheadline).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            if let trailing {
                Label(trailing, systemImage: "checkmark")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}
