import SwiftUI
import PhotosUI

/// Hoja para agregar a alguien al árbol de Carmen.
/// Lo que se guarda aquí aparece al momento en el árbol, en "Recuerdos → Por persona"
/// y en "¿Quién aparece?" al agregar un recuerdo.
struct AgregarPersonaView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// Persona elegida en el árbol: sirve para adivinar qué se quiere agregar
    /// (si está elegida Ana, lo más probable es un nieto de Ana).
    var suggestedFor: Relative?

    @State private var pickerItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var name = ""
    @State private var role: Relative.Role = .child
    @State private var gender: Relative.Gender = .female
    @State private var linkedTo: String?
    @State private var detail = ""
    @State private var note = ""
    @State private var didSetDefaults = false

    // MARK: Opciones según quién ya está en el árbol

    private var roleOptions: [(Relative.Role, String)] {
        var options: [(Relative.Role, String)] = [(.child, "Hijo o hija")]
        if !store.children.isEmpty { options.append((.grandchild, "Nieto o nieta")) }
        if !childrenWithoutPartner.isEmpty { options.append((.childPartner, "Pareja de un hijo")) }
        if store.myPartner == nil { options.append((.partner, "Pareja de Carmen")) }
        options.append((.friend, "Amigo o vecino"))
        return options
    }

    private var childrenWithoutPartner: [Relative] {
        store.children.filter { store.partner(of: $0.id) == nil }
    }

    private var linkOptions: [Relative] {
        switch role {
        case .grandchild: return store.children
        case .childPartner: return childrenWithoutPartner
        default: return []
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    private var canSave: Bool {
        !trimmedName.isEmpty && (linkOptions.isEmpty ? true : linkedTo != nil)
    }

    private var draft: Relative {
        Relative(id: UUID().uuidString,
                 name: trimmedName,
                 role: role,
                 gender: gender,
                 linkedTo: linkOptions.isEmpty ? nil : linkedTo,
                 detail: role == .friend ? detail.trimmingCharacters(in: .whitespaces) : "",
                 note: note.trimmingCharacters(in: .whitespaces),
                 photoData: photoData)
    }

    // MARK: Vista

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 16) {
                        photoPicker
                        labeled("Nombre") {
                            textField("Ej. Valeria", text: $name)
                                .textInputAutocapitalization(.words)
                        }
                    }

                    labeled("¿Quién es para Carmen?") {
                        FlowLayout {
                            ForEach(roleOptions, id: \.0) { option in
                                Chip(title: option.1, selected: role == option.0) {
                                    role = option.0
                                    linkedTo = linkOptions.first?.id
                                }
                            }
                        }
                    }

                    labeled("Es") {
                        HStack(spacing: 8) {
                            Chip(title: "Mujer", selected: gender == .female) { gender = .female }
                            Chip(title: "Hombre", selected: gender == .male) { gender = .male }
                        }
                    }

                    if !linkOptions.isEmpty {
                        labeled(role == .grandchild ? "¿Hijo o hija de quién?" : "¿Pareja de quién?") {
                            FlowLayout {
                                ForEach(linkOptions) { child in
                                    Chip(title: child.name, selected: linkedTo == child.id) {
                                        linkedTo = child.id
                                    }
                                }
                            }
                        }
                    }

                    if role == .friend {
                        labeled("¿Quién es?") {
                            textField("vecina, amiga de la iglesia…", text: $detail)
                        }
                    }

                    labeled("Algo que le ayude a recordar (opcional)") {
                        textField("Viene a verte los domingos.", text: $note)
                    }

                    if !trimmedName.isEmpty {
                        preview
                    }

                    Button("Agregar al árbol") { save() }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.5)

                    Text("También tendrá su álbum en Recuerdos.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                }
                .padding(Theme.screenPadding)
                .readableWidth()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Nueva persona")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task { photoData = try? await item?.loadTransferable(type: Data.self) }
            }
            .onAppear(perform: setDefaults)
        }
        .presentationBackground(Theme.background)
    }

    /// Lo que Carmen va a escuchar, para revisarlo antes de guardar.
    private var preview: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "speaker.wave.2")
                .foregroundStyle(Theme.ink)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Carmen escuchará")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                Text("«\(store.narration(draft))»")
                    .font(.rounded(20, relativeTo: .body))
                    .foregroundStyle(Theme.text)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                FacePhoto(photoData: photoData, size: 84, lineWidth: 3)
                Image(systemName: "camera.fill")
                    .font(.footnote)
                    .foregroundStyle(Theme.onInk)
                    .frame(width: 28, height: 28)
                    .background(Theme.ink, in: Circle())
            }
        }
        .accessibilityLabel(photoData == nil ? "Elegir foto de la cara" : "Cambiar foto")
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

    // MARK: Acciones

    private func setDefaults() {
        guard !didSetDefaults else { return }
        didSetDefaults = true
        switch suggestedFor?.role {
        case .child?:
            role = .grandchild
            linkedTo = suggestedFor?.id
        case .childPartner?, .grandchild?:
            role = .grandchild
            linkedTo = suggestedFor?.linkedTo
        default:
            role = .child
        }
        if linkOptions.isEmpty == false, linkedTo == nil { linkedTo = linkOptions.first?.id }
    }

    private func save() {
        store.addRelative(draft)
        dismiss()
    }
}
