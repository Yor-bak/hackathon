import SwiftUI

/// Calendario mensual dibujado a mano. Navega entre meses con dos botones claros (con el nombre del mes) o deslizando.
/// Las citas, los medicamentos y las visitas los agrega la app espejo del cuidador (`AppState.events`).
struct MonthCalendarView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var monthOffset: Int = {
        // Solo para capturas: -month 1
        let a = CommandLine.arguments
        if let i = a.firstIndex(of: "-month"), i + 1 < a.count, let n = Int(a[i + 1]) { return n }
        return 0
    }()
    @State private var selected: Date = Fmt.cal.startOfDay(for: .now)

    private var cal: Calendar { Fmt.cal }
    private var today: Date { cal.startOfDay(for: .now) }

    private func month(_ off: Int) -> Date {
        let first = cal.date(from: cal.dateComponents([.year, .month], from: today))!
        return cal.date(byAdding: .month, value: off, to: first)!
    }

    private func name(_ d: Date) -> String {
        let m = d.formatted(.dateTime.month(.wide).locale(Fmt.locale))
        return m.prefix(1).uppercased() + m.dropFirst()
    }

    var body: some View {
        let start = month(monthOffset)
        ScrollView {
            VStack(spacing: 10) {
                // Mes en grande + a dónde ir
                Text("\(name(start)) \(start.formatted(.dateTime.year().locale(Fmt.locale)))")
                    .dynamicTypeSize(.xLarge ... .accessibility1)
                    .font(Skin.title(40, relativeTo: .largeTitle)).foregroundStyle(Skin.ink)
                    .minimumScaleFactor(0.6).lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                navRow(start)
                weekdayRow
                grid(start)
                    .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { v in
                        // solo si el deslizamiento es claramente horizontal: no estorba al desplazar la pantalla
                        guard abs(v.translation.width) > abs(v.translation.height) * 1.8 else { return }
                        if v.translation.width < -50 { go(1) } else if v.translation.width > 50 { go(-1) }
                    })
                agenda
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 28)
            .frame(maxWidth: 720).frame(maxWidth: .infinity)
        }
    }

    // MARK: Cambiar de mes

    private func navRow(_ start: Date) -> some View {
        HStack(spacing: 10) {
            navButton(name(month(monthOffset - 1)), icon: .arrowL, leading: true) { go(-1) }
            if monthOffset != 0 || selected != today {      // «Hoy» aparece solo cuando te has ido de hoy
                Button { monthOffset = 0; selected = today } label: {
                    VStack(spacing: 0) {
                        SketchIcon(kind: .sun, color: Skin.onAccent).frame(width: 24, height: 24)
                        Text("Hoy").font(.footnote.weight(.heavy)).foregroundStyle(Skin.onAccent)
                    }
                    .frame(width: 66, height: 54)
                    .background { SkinFrame(radius: 16, seed: 6, selected: true) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Volver a hoy")
            }
            navButton(name(month(monthOffset + 1)), icon: .arrowR, leading: false) { go(1) }
        }
    }

    private func navButton(_ label: String, icon: SketchKind, leading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if leading { SketchIcon(kind: icon).frame(width: 28, height: 28) }
                Text(label).font(.headline.weight(.heavy)).foregroundStyle(Skin.ink).lineLimit(1).minimumScaleFactor(0.6)
                    .dynamicTypeSize(.xLarge ... .xxxLarge)
                if !leading { SketchIcon(kind: icon).frame(width: 28, height: 28) }
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .background { SkinFrame(radius: 16, seed: leading ? 2 : 9) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(leading ? "Mes anterior, \(label)" : "Mes siguiente, \(label)")
    }

    private func go(_ d: Int) {
        monthOffset += d
        selected = monthOffset == 0 ? today : month(monthOffset)
    }

    // MARK: Rejilla del mes

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(["lun", "mar", "mié", "jue", "vie", "sáb", "dom"], id: \.self) { d in
                Text(d).font(.footnote.weight(.heavy)).foregroundStyle(Skin.ink)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
        .dynamicTypeSize(.xLarge ... .xxxLarge)
    }

    private func grid(_ start: Date) -> some View {
        let lead = (cal.component(.weekday, from: start) - cal.firstWeekday + 7) % 7
        let days = cal.range(of: .day, in: .month, for: start)!.count
        let rows = (lead + days + 6) / 7
        return VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { c in
                        let n = r * 7 + c - lead + 1
                        if n >= 1 && n <= days {
                            cell(cal.date(byAdding: .day, value: n - 1, to: start)!, number: n)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 52)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .background { SkinFrame(radius: 18, seed: 4, fill: 0.74, line: 2.6) }
        .dynamicTypeSize(.xLarge ... .xxxLarge)
    }

    private func cell(_ d: Date, number n: Int) -> some View {
        let isToday = cal.isDate(d, inSameDayAs: today)
        let isSel = cal.isDate(d, inSameDayAs: selected)
        let past = d < today
        let marks = app.marks(on: d)
        return Button { selected = d } label: {
            VStack(spacing: 1) {
                ZStack {
                    if isSel { Circle().fill(Skin.accent).frame(width: 36, height: 36) }
                    if isToday { SketchRing(seed: Double(n), line: 2.8).frame(width: 38, height: 38) }
                    Text("\(n)").font(.title3.weight(.heavy).monospacedDigit()).foregroundStyle(isSel ? Skin.onAccent : Skin.ink)
                }
                .frame(width: 38, height: 38)
                HStack(spacing: 2) {
                    ForEach(Array(marks.prefix(2).enumerated()), id: \.offset) { _, e in
                        SketchIcon(kind: e.kind.icon).frame(width: 14, height: 14)
                    }
                    if marks.isEmpty { Color.clear.frame(width: 14, height: 14) }
                }
            }
            .opacity(past && !isSel ? 0.5 : 1)
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(n) de \(name(d))\(isToday ? ", hoy" : "")\(marks.isEmpty ? "" : ", " + marks.map(\.title).joined(separator: ", "))")
        .accessibilityAddTraits(isSel ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Lo que pasa el día elegido

    private var agenda: some View {
        let list = app.events(on: selected)
        let isToday = cal.isDate(selected, inSameDayAs: today)
        let weekday = selected.formatted(.dateTime.weekday(.wide).locale(Fmt.locale))
        let title = isToday ? "Hoy, \(weekday) \(cal.component(.day, from: selected))"
                            : "\(weekday.prefix(1).uppercased() + weekday.dropFirst()) \(cal.component(.day, from: selected)) de \(name(selected).lowercased())"
        return VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.title2.weight(.heavy)).foregroundStyle(Skin.ink)
                .padding(.top, 8).accessibilityAddTraits(.isHeader)
            ForEach(Array(list.enumerated()), id: \.element.id) { i, e in eventRow(e, index: i) }
            if list.isEmpty {
                Text("No hay nada planeado. Un día tranquilo.")
                    .font(Skin.title(28, relativeTo: .title2)).foregroundStyle(Skin.ink).padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func eventRow(_ e: CalEvent, index: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Medallion(seed: Double(index) * 1.3, line: 2.8)
                SketchIcon(kind: e.kind.icon).padding(14)
            }
            .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 2) {
                Text(e.title).font(.headline.weight(.heavy)).foregroundStyle(Skin.ink)
                    .dynamicTypeSize(.xLarge ... .accessibility2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Fmt.timeString(minutes: e.minutes)).font(.subheadline.weight(.heavy).monospacedDigit()).foregroundStyle(Skin.ink)
                if let who = e.addedBy {
                    Text("Lo agregó \(who)").font(.footnote.weight(.semibold)).foregroundStyle(Skin.ink2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background { SkinFrame(radius: 14, seed: Double(index) + 11, fill: 0.78, line: 2.6) }
        .accessibilityElement(children: .combine)
    }
}
