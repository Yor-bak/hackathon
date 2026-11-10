import SwiftUI

struct CalendarioView: View {
    @Environment(AppStore.self) private var store
    @State private var month = Date()
    @State private var showAddMedication = false
    @State private var showAddEvent = false

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2   // lunes
        c.locale = Locale(identifier: "es_MX")
        return c
    }

    private let weekdayLetters = ["L", "M", "M", "J", "V", "S", "D"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ScreenTitle(text: "Calendario")
                    PersonPicker()
                    monthCard
                    nextDoseCard

                    VStack(spacing: 10) {
                        Button {
                            showAddMedication = true
                        } label: {
                            Label("Agregar pastilla", systemImage: "plus")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button {
                            showAddEvent = true
                        } label: {
                            Label("Agregar evento", systemImage: "plus")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 24)
                .readableWidth()
            }
            .caregiverChrome(title: "Calendario")
            .sheet(isPresented: $showAddMedication) { AgregarPastillaView() }
            .sheet(isPresented: $showAddEvent) { AgregarEventoView() }
        }
    }

    // MARK: Mes

    private var monthCard: some View {
        VStack(spacing: 4) {
            HStack {
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(RoundIconButtonStyle())
                    .accessibilityLabel("Mes anterior")
                Spacer()
                Text(month, format: .dateTime.month(.wide).year())
                    .font(.rounded(21, relativeTo: .title3))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .textCase(.none)
                Spacer()
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(RoundIconButtonStyle())
                    .accessibilityLabel("Mes siguiente")
            }
            .padding(.bottom, 6)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(weekdayLetters.enumerated()), id: \.offset) { _, letter in
                    Text(letter)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(height: 24)
                }
                ForEach(Array(gridDays().enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayCell(date: day,
                                isToday: calendar.isDateInToday(day),
                                mark: store.mark(for: day, calendar: calendar),
                                calendar: calendar)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
            legend
        }
        .padding(12)
        .cardStyle()
    }

    /// El color nunca va solo: cada marca tiene forma distinta y aquí se explica con texto.
    private var legend: some View {
        FlowLayout(spacing: 14) {
            legendItem(Circle().fill(Theme.done).frame(width: 10, height: 10), "Tomó todo")
            legendItem(Circle().strokeBorder(Theme.attention, style: StrokeStyle(lineWidth: 2.5, dash: [2.5, 2]))
                        .frame(width: 12, height: 12), "Le faltó una")
            legendItem(RoundedRectangle(cornerRadius: 2).fill(Theme.ink).frame(width: 10, height: 10), "Evento")
        }
        .padding(.top, 8)
        .dynamicTypeSize(TypeRange.fixedWidth)
    }

    private func legendItem(_ mark: some View, _ text: String) -> some View {
        HStack(spacing: 6) {
            mark
            Text(text).font(.footnote.weight(.bold)).foregroundStyle(Theme.secondaryText)
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let m = calendar.date(byAdding: .month, value: delta, to: month) { month = m }
    }

    private func gridDays() -> [Date?] {
        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let first = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: first) else { return [] }
        let weekday = calendar.component(.weekday, from: first)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: offset)
        for d in range {
            days.append(calendar.date(byAdding: .day, value: d - 1, to: first))
        }
        return days
    }

    // MARK: Próxima pastilla

    @ViewBuilder
    private var nextDoseCard: some View {
        if let med = store.nextMedication() {
            HStack(spacing: 14) {
                Image(systemName: "pills")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.onInk)
                    .frame(width: 56, height: 56)
                    .chunky(fill: Theme.attention, edge: Theme.attentionEdge, radius: 28, depth: 4)
                VStack(alignment: .leading, spacing: 4) {
                    Text("PRÓXIMA")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Theme.onInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.attention, in: RoundedRectangle(cornerRadius: 6))
                    Text("\(med.timeText) · \(med.name)")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    Text(store.person(med.personID)?.name ?? "")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            }
            .padding(12)
            .cardStyle(border: Theme.attention)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let mark: DayMark
    let calendar: Calendar

    var body: some View {
        VStack(spacing: 2) {
            if isToday {
                // Hoy = «ahora»: amarillo, con borde inferior.
                Text("\(calendar.component(.day, from: date))")
                    .font(.body.weight(.heavy))
                    .foregroundStyle(Theme.onInk)
                    .minimumScaleFactor(0.6)
                    .frame(width: 36, height: 36)
                    .chunky(fill: Theme.attention, edge: Theme.attentionEdge, radius: 18, depth: 3)
            } else {
                Text("\(calendar.component(.day, from: date))")
                    .font(.body.weight(.bold))
                    .foregroundStyle(Theme.text)
                    .minimumScaleFactor(0.6)
                    .frame(height: 26)
                marker
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var marker: some View {
        switch mark {
        case .taken: Circle().fill(Theme.done).frame(width: 9, height: 9)
        case .missed: Circle().strokeBorder(Theme.attention, style: StrokeStyle(lineWidth: 2.5, dash: [2.5, 2]))
                .frame(width: 11, height: 11)
        case .event: RoundedRectangle(cornerRadius: 2).fill(Theme.ink).frame(width: 9, height: 9)
        case .none: Color.clear.frame(width: 9, height: 9)
        }
    }

    private var accessibilityText: String {
        let day = date.formatted(.dateTime.day().month(.wide))
        switch mark {
        case .taken: return "\(day), todas las pastillas tomadas"
        case .missed: return "\(day), dosis omitida"
        case .event: return "\(day), hay un evento"
        case .none: return day
        }
    }
}
