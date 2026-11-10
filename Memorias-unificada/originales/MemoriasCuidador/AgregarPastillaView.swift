import SwiftUI

// MARK: - Nueva pastilla

struct AgregarPastillaView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var personID = "carmen"
    @State private var time = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var days: Set<Int> = Set(1...7)

    // (letra, día de la semana según Calendar: 1 = domingo)
    private let weekdays: [(String, Int, String)] = [
        ("L", 2, "Lunes"), ("M", 3, "Martes"), ("M", 4, "Miércoles"), ("J", 5, "Jueves"),
        ("V", 6, "Viernes"), ("S", 7, "Sábado"), ("D", 1, "Domingo")
    ]

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !days.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    field("Nombre de la pastilla") {
                        TextField("Ej. Donepezilo 5 mg", text: $name)
                            .font(.title3)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 64)
                            .cardStyle()
                    }

                    field("¿Para quién?") {
                        HStack(spacing: 8) {
                            ForEach(store.people) { p in
                                Chip(title: p.name, selected: personID == p.id) { personID = p.id }
                            }
                        }
                    }

                    field("¿A qué hora?") {
                        HStack {
                            Image(systemName: "clock").foregroundStyle(Theme.ink)
                            DatePicker("Hora", selection: $time, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                            Spacer()
                        }
                        .font(.title3)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 64)
                        .cardStyle()
                    }

                    field("Se repite") {
                        FlowLayout(spacing: 6) {
                            ForEach(Array(weekdays.enumerated()), id: \.offset) { _, d in
                                let on = days.contains(d.1)
                                Button {
                                    if on { days.remove(d.1) } else { days.insert(d.1) }
                                } label: {
                                    Text(d.0)
                                        .font(.title3.weight(.heavy))
                                        .minimumScaleFactor(0.6)
                                }
                                // Elegido = amarillo y relleno; no elegido = contorno
                                .buttonStyle(ChunkyButtonStyle(fill: on ? Theme.attention : Theme.surface,
                                                               edge: on ? Theme.attentionEdge : Theme.line,
                                                               textColor: on ? Theme.onInk : Theme.text,
                                                               outline: on ? nil : Theme.line,
                                                               height: Theme.minTouch - 6))
                                .frame(width: 52)
                                .dynamicTypeSize(TypeRange.tabBar)
                                .accessibilityLabel(d.2)
                                .accessibilityAddTraits(on ? .isSelected : [])
                            }
                        }
                    }

                    Text("Aparecerá en el camino de \(store.person(personID)?.name ?? ""). Si ya la tomó, la app lo avisa para evitar una doble dosis.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)

                    VStack(spacing: 10) {
                        Button("Guardar pastilla") { save() }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(!canSave)
                            .opacity(canSave ? 1 : 0.5)
                        Text("Se puede deshacer durante 8 segundos.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(Theme.screenPadding)
                .readableWidth()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Nueva pastilla")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .presentationBackground(Theme.background)
    }

    private func save() {
        let c = Calendar.current.dateComponents([.hour, .minute], from: time)
        let med = Medication(name: name.trimmingCharacters(in: .whitespaces),
                             personID: personID,
                             hour: c.hour ?? 0,
                             minute: c.minute ?? 0,
                             weekdays: days)
        store.addMedication(med)
        dismiss()
    }

    @ViewBuilder
    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.secondaryText)
            content()
        }
    }
}

// MARK: - Nuevo evento

struct AgregarEventoView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var personID = "carmen"
    @State private var date = Date()

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre del evento").font(.headline).foregroundStyle(Theme.secondaryText)
                        TextField("Ej. Cita con el médico", text: $title)
                            .font(.title3)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 64)
                            .cardStyle()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Para quién?").font(.headline).foregroundStyle(Theme.secondaryText)
                        HStack(spacing: 8) {
                            ForEach(store.people) { p in
                                Chip(title: p.name, selected: personID == p.id) { personID = p.id }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Cuándo?").font(.headline).foregroundStyle(Theme.secondaryText)
                        DatePicker("Fecha y hora", selection: $date)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                            .padding(.horizontal, 16)
                            .cardStyle()
                    }

                    Button("Guardar evento") {
                        store.addEvent(CareEvent(title: title, personID: personID, date: date))
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                }
                .padding(Theme.screenPadding)
                .readableWidth()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Nuevo evento")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .presentationBackground(Theme.background)
    }
}
