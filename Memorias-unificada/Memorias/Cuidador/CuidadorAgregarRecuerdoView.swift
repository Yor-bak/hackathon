import SwiftUI
import PhotosUI

/// Hoja para agregar un recuerdo. Los campos son el contrato con el álbum:
/// el narrador con IA usa SOLO lo que se escribe aquí.
struct AgregarRecuerdoView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var photoData: Data?
    /// ids de las personas del árbol que salen en la foto
    @State private var people: Set<String> = ["ana"]
    @State private var when = ""
    @State private var place = ""
    @State private var phrase = ""
    @State private var narrateWithMyVoice = true

    private var canSave: Bool { photoData != nil && !people.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    photoPicker

                    // Las mismas personas que el árbol de la familia.
                    labeled("¿Quién aparece?") {
                        FlowLayout {
                            ForEach(store.knownPeople) { person in
                                Chip(title: person.name, selected: people.contains(person.id)) {
                                    if people.contains(person.id) { people.remove(person.id) } else { people.insert(person.id) }
                                }
                            }
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        labeled("¿Cuándo?") { textField("Verano de 1998", text: $when) }
                        labeled("¿Dónde?") { textField("Acapulco", text: $place) }
                    }

                    labeled("Tu frase para Carmen") {
                        TextField("Aquí estábamos todos…", text: $phrase, axis: .vertical)
                            .font(.rounded(21, relativeTo: .body))
                            .lineLimit(2...4)
                            .padding(14)
                            .frame(minHeight: 84, alignment: .topLeading)
                            .cardStyle()
                    }

                    Toggle(isOn: $narrateWithMyVoice) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Narrar con mi voz").font(.headline).foregroundStyle(Theme.text)
                            Text("Solo usa lo que escribas aquí.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .tint(Theme.ink)

                    Button("Guardar recuerdo") { save() }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.5)
                }
                .padding(Theme.screenPadding)
                .readableWidth()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Nuevo recuerdo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task {
                    photoData = try? await item?.loadTransferable(type: Data.self)
                }
            }
        }
        .presentationBackground(Theme.background)
    }

    // MARK: Piezas

    private var photoPicker: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            Group {
                if let photoData, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle").font(.system(size: 40))
                        Text("Elegir foto").font(.title3.bold())
                    }
                    .foregroundStyle(Theme.ink)
                    // El fondo llena todo el recuadro, no solo la franja del texto.
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.faceFill)
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Theme.ink, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
            )
        }
        .accessibilityLabel("Elegir foto")
    }

    private func textField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.body)
            .padding(.horizontal, 14)
            .frame(minHeight: 56)
            .cardStyle()
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundStyle(Theme.secondaryText)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() {
        let record = MemoryRecord(photoData: photoData,
                                  people: store.knownPeople.filter { people.contains($0.id) }.map(\.name),
                                  when: when,
                                  place: place,
                                  phrase: phrase,
                                  narrateWithMyVoice: narrateWithMyVoice)
        store.addMemory(record)
        dismiss()
    }
}
