import SwiftUI
import MapKit

struct InicioView: View {
    @State private var vitalsExpanded = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ScreenTitle(text: "Hola, Ana")
                    PersonPicker()
                    MapCard()
                    VitalsCard(expanded: $vitalsExpanded)
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 24)
                .readableWidth()
            }
            .caregiverChrome(title: "Hola, Ana")
        }
    }
}

// MARK: - Mapa

private struct MapCard: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: SampleData.home,
            span: MKCoordinateSpan(latitudeDelta: 0.014, longitudeDelta: 0.014)))
        ) {
            // Zona segura (de ejemplo)
            MapCircle(center: SampleData.home, radius: 150)
                .foregroundStyle(Theme.ink.opacity(0.15))
                .stroke(Theme.ink, lineWidth: 2)

            ForEach(store.visiblePeople) { person in
                Annotation(person.name, coordinate: person.coordinate) {
                    Text(person.initial)
                        .font(.headline.bold())
                        .foregroundStyle(Theme.onInk)
                        .frame(width: 40, height: 40)
                        .background(Theme.ink, in: Circle())
                        .overlay(Circle().stroke(Theme.background, lineWidth: 3))
                }
            }
        }
        .mapStyle(.standard)
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner))
        .overlay(alignment: .topLeading) {
            StatusPill(kind: .done, text: "\(store.focusPerson.name) · en casa", icon: "house")
                .padding(12)
        }
        .overlay(alignment: .bottomTrailing) {
            Text("Ubicación de ejemplo")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.background.opacity(0.9), in: Capsule())
                .padding(10)
        }
        .cardStyle()
    }
}

// MARK: - Signos vitales

private struct VitalsCard: View {
    @Environment(AppStore.self) private var store
    @Binding var expanded: Bool

    var body: some View {
        let person = store.focusPerson

        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { expanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Signos vitales")
                            .font(.rounded(22, relativeTo: .title3))
                            .foregroundStyle(Theme.text)
                        Text(person.hasWatch
                             ? "Apple Watch de \(person.name) · hace 1 min"
                             : "\(person.name) · sin Apple Watch vinculado")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.headline)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: Theme.minTouch, height: Theme.minTouch)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Signos vitales")
            .accessibilityValue(expanded ? "Desplegado" : "Oculto")

            if person.hasWatch {
                HStack(spacing: 10) {
                    StatusPill(kind: .done, text: "Todo normal")
                    Text("Sin caídas hoy")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }

                if expanded {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                        VitalTile(title: "Ritmo cardiaco", value: "\(person.heartRate ?? 0)", unit: "lpm")
                        VitalTile(title: "Pasos hoy", value: person.steps.formatted(), unit: "")
                        VitalTile(title: "Sueño anoche", value: person.sleepText, unit: "")
                        VitalTile(title: "Batería del reloj", value: "\(person.battery ?? 0) %", unit: "")
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

private struct VitalTile: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.rounded(26, relativeTo: .title2))
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(Theme.text)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: Theme.cardCorner))
        .accessibilityElement(children: .combine)
    }
}
