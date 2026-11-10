import SwiftUI

struct AlertasView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ScreenTitle(text: "Alertas")
                    if !store.attentionAlerts.isEmpty {
                        SectionTitle(text: "Necesita atención", color: Theme.attention, icon: "exclamationmark.circle")
                        ForEach(store.attentionAlerts) { alert in
                            AttentionCard(alert: alert)
                        }
                    }

                    SectionTitle(text: "Hoy", icon: "checkmark.circle")
                        .padding(.top, 8)
                    ForEach(store.todayAlerts) { alert in
                        InfoRow(alert: alert)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 24)
                .readableWidth()
            }
            .caregiverChrome(title: "Alertas")
        }
    }
}

// MARK: - Necesita atención (ámbar, con una acción principal)

private struct AttentionCard: View {
    @Environment(AppStore.self) private var store
    let alert: CareAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(alert.title)
                .font(.rounded(22, relativeTo: .title3))
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Theme.text)
            Text(alert.detail)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)

            HStack(spacing: 10) {
                switch alert.kind {
                case .help:
                    callButton
                    Button("Ver ubicación") {
                        store.selectedPersonID = alert.personID
                        store.selectedTab = .inicio
                    }
                    .buttonStyle(SecondaryButtonStyle())
                case .pendingDose:
                    Button { store.markDoseTaken(alertID: alert.id) } label: {
                        Label("Ya la tomó", systemImage: "checkmark")
                    }
                    .buttonStyle(DoneButtonStyle())
                    callButton
                case .info:
                    EmptyView()
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(border: Theme.attention, lineWidth: 3)
    }

    // En la demo no se marca un número real.
    private var callButton: some View {
        Button {
            // TODO: abrir "tel:" con el teléfono de la persona.
        } label: {
            Label("Llamar", systemImage: "phone")
        }
        .buttonStyle(alert.kind == .help ? AnyButtonStyle(PrimaryButtonStyle()) : AnyButtonStyle(SecondaryButtonStyle()))
    }
}

/// Permite elegir un estilo de botón en tiempo de ejecución.
private struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView
    init<S: ButtonStyle>(_ style: S) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }
    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}

// MARK: - Registro de hoy (tranquilo)

private struct InfoRow: View {
    let alert: CareAlert

    var body: some View {
        HStack(spacing: 12) {
            // Hecho = verde con palomita
            Image(systemName: "checkmark")
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.onInk)
                .frame(width: 40, height: 40)
                .chunky(fill: Theme.done, edge: Theme.doneEdge, radius: 20, depth: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(alert.resolved ? "Pastilla tomada" : alert.title)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                Text(alert.detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: Theme.minTouch, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
