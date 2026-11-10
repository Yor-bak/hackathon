import SwiftUI

/// Hoja para agregar una página (recuerdo) al libro. «Cancelar» la cierra sin guardar nada.
struct LibroAddMemoryView: View {
    var onSave: (BookPage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var uiImage: UIImage?

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Button("Cancelar") { dismiss() }
                        .buttonStyle(SheetButton(kind: .secondary))
                    Spacer()
                    Text("Nuevo recuerdo")
                        .font(.custom("ArialRoundedMTBold", size: 24, relativeTo: .title2))
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Guardar") { save() }
                        .buttonStyle(SheetButton(kind: .primary))
                        .disabled(!canSave).opacity(canSave ? 1 : 0.4)
                }

                // Foto (opcional): «+» para elegir de la galería o tomar una
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        if let uiImage {
                            Color.clear.overlay { Image(uiImage: uiImage).resizable().scaledToFill() }.clipped()
                        } else {
                            LinearGradient(colors: [MemoryTheme.darkAction, MemoryTheme.edgeBlue],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        }
                    }
                    .frame(height: 220).frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(MemoryTheme.edgeGray, lineWidth: 3))
                    PhotoAddButton(size: uiImage == nil ? 88 : 56) { uiImage = $0 }
                        .frame(maxWidth: .infinity, maxHeight: .infinity,
                               alignment: uiImage == nil ? .center : .bottomTrailing)
                        .padding(uiImage == nil ? 0 : 14)
                }
                .frame(height: 220)

                field("¿Cómo se llama este recuerdo?") {
                    TextField("", text: $title, prompt: Text("Ej. La playa con Ana").foregroundStyle(.white.opacity(0.4)))
                        .textInputAutocapitalization(.sentences)
                }

                field("Fecha") {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                        .labelsHidden().environment(\.locale, Locale(identifier: "es_MX"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

            }
            .padding(24)
            .frame(maxWidth: 640).frame(maxWidth: .infinity)
        }
        .background(MemoryTheme.darkBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func field<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.custom("ArialRoundedMTBold", size: 16, relativeTo: .subheadline))
                .foregroundStyle(Color(red: 0xB9/255, green: 0xC6/255, blue: 0xD8/255))
            content()
                .font(.custom("ArialRoundedMTBold", size: 20, relativeTo: .body))
                .foregroundStyle(.white)
                .padding(.horizontal, 16).frame(minHeight: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(MemoryTheme.darkSurface))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(MemoryTheme.edgeGray, lineWidth: 2))
        }
    }

    private func save() {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "d 'de' MMMM 'de' yyyy"
        let tones: [[Color]] = [[Pal.tones[0].bg, MemoryTheme.edgeBlue], [Pal.tones[1].bg, Color(red: 0x2F/255, green: 0xA8/255, blue: 0x70/255)],
                                [Pal.tones[2].bg, MemoryTheme.edgeAmber], [Pal.tones[3].bg, Color(red: 0x8A/255, green: 0x6F/255, blue: 0xE0/255)]]
        var page = BookPage(date: f.string(from: date), caption: title.trimmingCharacters(in: .whitespaces),
                            placeholder: tones.randomElement() ?? tones[0])
        if let uiImage { page.uiImage = uiImage; page.image = Image(uiImage: uiImage) }
        onSave(page)
        dismiss()
    }
}

private struct SheetButton: ButtonStyle {
    enum Kind { case primary, secondary }
    var kind: Kind
    func makeBody(configuration: Configuration) -> some View {
        let p = configuration.isPressed
        let primary = kind == .primary
        configuration.label
            .font(.custom("ArialRoundedMTBold", size: 18, relativeTo: .headline))
            .foregroundStyle(primary ? MemoryTheme.onAccent : .white)
            .padding(.horizontal, 20).frame(height: 48)
            .background(Capsule().fill(primary ? MemoryTheme.amber : MemoryTheme.darkSurface))
            .overlay(Capsule().strokeBorder(primary ? .clear : MemoryTheme.edgeGray, lineWidth: 2))
            .compositingGroup()
            .shadow(color: primary ? MemoryTheme.edgeAmber : MemoryTheme.edgeGray, radius: 0, y: p ? 1 : 5)
            .offset(y: p ? 4 : 0)
    }
}
