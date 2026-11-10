import SwiftUI
import PhotosUI

private struct OpenMember: Identifiable { let id: UUID }

// MARK: - Pantalla «Mi familia»: árbol que se puede mover y ampliar

struct FamilyTreeView: View {
    @ObservedObject var store: FamilyStore
    @State private var dragID: UUID?
    @State private var dragDelta: CGSize = .zero
    @State private var open: OpenMember?
    @State private var showAdd = false
    /// Zoom del árbol: pellizco o botones «−» y «+». 1 = tamaño normal.
    @State private var zoom: CGFloat = 1
    @State private var zoomBase: CGFloat = 1
    private let zoomRange: ClosedRange<CGFloat> = 0.45 ... 1.8

    private let nodeSize: CGFloat = 104

    var body: some View {
        GeometryReader { geo in
            ScrollView([.horizontal, .vertical]) {
                canvas(minSize: geo.size)
            }
            .scrollIndicators(.hidden)
            // En pantallas bajas (iPad mini) el árbol es más alto que la pantalla: se abre mostrando las raíces y la copa se alcanza deslizando.
            // y centrado de lado a lado: el árbol siempre arranca en el centro de la pantalla.
            // Pantallas altas (iPad Pro): se abre en el punto donde caben todas las personas, entre el título y la barra.
            // Pantallas bajas: se abre por las raíces (donde están Carmen y Ramón) y la copa se alcanza deslizando.
            .defaultScrollAnchor(UnitPoint(x: 0.5, y: geo.size.height >= 840 ? 0.72 : 1))
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { v in zoom = clamp(zoomBase * v.magnification) }
                    .onEnded { _ in zoomBase = zoom }
            )
            // El árbol llega hasta arriba: el encabezado y los controles flotan encima con desvanecido, sin cortar el dibujo.
            .safeAreaInset(edge: .top, spacing: 0) { header.frame(maxWidth: .infinity).fadingHeaderBackground(Skin.barFill) }
            // El desvanecido hacia la barra va aquí, DEBAJO de los botones; así los botones quedan pegados abajo, con su color completo.
            .overlay(alignment: .bottom) { BottomFade(color: Skin.barFill) }
            .overlay(alignment: .bottom) { controls.padding(.horizontal, 16).padding(.bottom, 14) }
        }
        .background { SkinBackground() }
        .sheet(isPresented: $showAdd) { FamilyAddView(store: store) }
        .fullScreenCover(item: $open) { o in FamilyDetailView(store: store, id: o.id) }
    }

    private func clamp(_ z: CGFloat) -> CGFloat { min(max(z, zoomRange.lowerBound), zoomRange.upperBound) }

    private func setZoom(_ z: CGFloat) {
        withAnimation(.easeOut(duration: 0.2)) { zoom = clamp(z); zoomBase = zoom }
    }

    /// Zoom y «Agregar persona»: botones grandes, porque pellizcar no es obvio para todos.
    private var controls: some View {
        HStack(alignment: .bottom, spacing: 10) {
            zoomButton("minus.magnifyingglass", label: "Alejar") { setZoom(zoom / 1.25) }
                .disabled(zoom <= zoomRange.lowerBound + 0.01)
            zoomButton("plus.magnifyingglass", label: "Acercar") { setZoom(zoom * 1.25) }
                .disabled(zoom >= zoomRange.upperBound - 0.01)
            Spacer(minLength: 8)
            addButton
        }
        .dynamicTypeSize(.xLarge ... .xxxLarge)
    }

    private func zoomButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(MemoryTheme.darkSurface))
                .overlay(Circle().strokeBorder(MemoryTheme.edgeGray, lineWidth: 2))
        }
        .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeGray))
        .accessibilityLabel(label)
    }

    // MARK: Encabezado

    private var header: some View {
        VStack(spacing: 6) {
            Text("Mi familia").font(Skin.title(40, relativeTo: .largeTitle)).foregroundStyle(Pal.ink)
                .dynamicTypeSize(.xLarge ... .accessibility1)
            Text("Toca a una persona para ver su foto y su historia. Arrástrala para acomodarla.")
                .font(.callout.weight(.semibold)).foregroundStyle(Pal.text2)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 8)
    }

    private var addButton: some View {
        Button { showAdd = true } label: {
            Label("Agregar persona", systemImage: "plus")
                .font(.headline.weight(.heavy))
                .foregroundStyle(Pal.onInk)
                .padding(.horizontal, 16).frame(height: 56)
                .background(Capsule().fill(Skin.accent))
        }
        .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeAmber))
        .accessibilityHint("Agrega a alguien nuevo al árbol")
    }

    // MARK: Lienzo

    private func pos(_ m: FamilyMember) -> CGPoint {
        m.id == dragID ? CGPoint(x: m.x + dragDelta.width, y: m.y + dragDelta.height) : CGPoint(x: m.x, y: m.y)
    }

    /// Hojitas verdes a lo largo de una rama (curva de Bézier).
    private func drawLeaves(_ ctx: inout GraphicsContext, from a: CGPoint, c1: CGPoint, c2: CGPoint, to b: CGPoint) {
        let green = Color(red: 0x3F / 255, green: 0xD0 / 255, blue: 0x8F / 255).opacity(0.85)
        for k in 1...3 {
            let t = CGFloat(k) / 4
            let u = 1 - t
            let x0: CGFloat = u * u * u * a.x
            let x1: CGFloat = 3 * u * u * t * c1.x
            let x2: CGFloat = 3 * u * t * t * c2.x
            let x3: CGFloat = t * t * t * b.x
            let y0: CGFloat = u * u * u * a.y
            let y1: CGFloat = 3 * u * u * t * c1.y
            let y2: CGFloat = 3 * u * t * t * c2.y
            let y3: CGFloat = t * t * t * b.y
            let side: CGFloat = k % 2 == 0 ? 1 : -1
            let center = CGPoint(x: x0 + x1 + x2 + x3 + side * 12, y: y0 + y1 + y2 + y3)
            let rotate = CGAffineTransform(rotationAngle: side * .pi / 4)
            let move = CGAffineTransform(translationX: center.x, y: center.y)
            let leaf = Path(ellipseIn: CGRect(x: -7, y: -13, width: 14, height: 26))
                .applying(rotate.concatenating(move))
            ctx.fill(leaf, with: .color(green))
        }
    }

    private func canvas(minSize: CGSize) -> some View {
        let maxX = store.members.map(\.x).max() ?? 0
        let maxY = store.members.map(\.y).max() ?? 0
        // «Mundo» del árbol: ancho propio (no el de la pantalla), para poder centrarlo; el dibujo de fondo y las personas comparten su centro.
        let size = CGSize(width: max(840, maxX + 250), height: max(minSize.height, maxY + 190, 1100))
        return world(size: size)
            .scaleEffect(zoom, anchor: .topLeading)
            .frame(width: size.width * zoom, height: size.height * zoom, alignment: .topLeading)
            .padding(.top, 150)                       // deja libre la franja del encabezado: la persona de más arriba no queda debajo del título
            .frame(minWidth: minSize.width)           // más angosto que la pantalla: queda centrado; más ancho: se desliza
    }

    private func world(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            // Silueta del árbol: raíces abajo (los abuelos) y copa arriba (los nietos).
            if let ui = UIImage.bundled("arbol.png") {
                let w: CGFloat = 860, h = w * ui.size.height / ui.size.width
                Image(uiImage: ui).resizable().renderingMode(.template)
                    .foregroundStyle(Color(red: 0x2B / 255, green: 0x44 / 255, blue: 0x68 / 255).opacity(0.75))
                    .frame(width: w, height: h)
                    .position(x: 417, y: size.height - 40 - h / 2)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            Canvas { ctx, _ in
                for link in store.links {
                    guard let a = store.member(link.a), let b = store.member(link.b) else { continue }
                    let pa = pos(a), pb = pos(b)
                    var path = Path()
                    switch link.kind {
                    case .partner:
                        path.move(to: pa); path.addLine(to: pb)
                        ctx.stroke(path, with: .color(Skin.accent), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        let mid = CGPoint(x: (pa.x + pb.x) / 2, y: (pa.y + pb.y) / 2)
                        ctx.fill(Path(ellipseIn: CGRect(x: mid.x - 17, y: mid.y - 17, width: 34, height: 34)), with: .color(Pal.bg))
                        ctx.draw(Text(Image(systemName: "heart.fill")).font(.system(size: 20)).foregroundColor(Skin.accent), at: mid)
                    case .parentChild:
                        let c1 = CGPoint(x: pa.x, y: pa.y + (pb.y - pa.y) * 0.55)
                        let c2 = CGPoint(x: pb.x, y: pb.y - (pb.y - pa.y) * 0.55)
                        path.move(to: pa); path.addCurve(to: pb, control1: c1, control2: c2)
                        // Rama: más gruesa en la base y fina hacia el hijo.
                        ctx.stroke(path, with: .color(Color(red: 0x4D / 255, green: 0xA3 / 255, blue: 0xFF / 255).opacity(0.55)),
                                   style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        drawLeaves(&ctx, from: pa, c1: c1, c2: c2, to: pb)
                    }
                }
            }
            .allowsHitTesting(false)

            ForEach(store.members) { m in
                FamilyNodeView(member: m, size: nodeSize, dragging: m.id == dragID)
                    .position(pos(m))
                    .zIndex(m.id == dragID ? 10 : 0)
                    .gesture(
                        DragGesture(minimumDistance: 4, coordinateSpace: .named("canvas"))
                            .onChanged { v in dragID = m.id; dragDelta = v.translation }
                            .onEnded { v in
                                store.move(m.id, to: CGPoint(x: m.x + v.translation.width, y: m.y + v.translation.height))
                                dragID = nil; dragDelta = .zero
                            }
                    )
                    .onTapGesture { open = OpenMember(id: m.id) }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(m.name), \(m.relation)")
                    .accessibilityHint("Toca para ver su foto y su biografía")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(width: size.width, height: size.height)
        .coordinateSpace(name: "canvas")
    }
}

// MARK: - Una persona en el árbol

struct FamilyNodeView: View {
    let member: FamilyMember
    var size: CGFloat = 104
    var dragging = false

    var body: some View {
        VStack(spacing: 8) {
            FamilyPhoto(member: member, size: size)
                .overlay(Circle().strokeBorder(dragging ? Skin.accent : Skin.line, lineWidth: dragging ? 6 : 4))
                .scaleEffect(dragging ? 1.1 : 1)
                .shadow(color: .black.opacity(dragging ? 0.45 : 0.25), radius: dragging ? 14 : 6, y: dragging ? 10 : 4)
            VStack(spacing: 0) {
                Text(member.name).font(.headline.weight(.heavy)).foregroundStyle(Skin.ink)
                Text(member.relation).font(.footnote.weight(.bold)).foregroundStyle(Skin.ink2)
            }
            .lineLimit(1).minimumScaleFactor(0.7)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Skin.card))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Skin.line, lineWidth: 2))
        }
        .frame(width: size + 50)
        .dynamicTypeSize(.xLarge ... .xxLarge)
        .animation(.easeOut(duration: 0.15), value: dragging)
    }
}

/// Foto redonda; si aún no hay foto, la inicial sobre un color.
struct FamilyPhoto: View {
    let member: FamilyMember
    var size: CGFloat
    var corner: CGFloat? = nil     // nil = círculo

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner ?? size / 2, style: .continuous)
        ZStack {
            if let ui = member.uiImage {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                let t = Pal.tones[member.tone % Pal.tones.count]
                t.bg
                Text(member.initial)
                    .font(Skin.title(size * 0.46, relativeTo: .largeTitle))
                    .foregroundStyle(t.fg)
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
    }
}

// MARK: - Foto grande y biografía

struct FamilyDetailView: View {
    @ObservedObject var store: FamilyStore
    let id: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var editing = false
    @State private var draft = FamilyMember(name: "", relation: "", bio: "", x: 0, y: 0)
    @State private var pickerItem: PhotosPickerItem?
    @State private var confirmDelete = false

    var body: some View {
        let m = store.member(id)
        ScrollView {
            if let m {
                VStack(spacing: 22) {
                    HStack {
                        Button { Speaker.shared.stop(); dismiss() } label: {
                            Label("Volver", systemImage: "chevron.left")
                        }
                        .buttonStyle(OutlinePill())
                        Spacer()
                    }
                    if editing { editor } else { reader(m) }
                }
                .padding(24)
                .frame(maxWidth: 640).frame(maxWidth: .infinity)
            }
        }
        .background { SkinBackground() }
        .onDisappear { Speaker.shared.stop() }
        .confirmationDialog("¿Quitar a esta persona del árbol?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Quitar del árbol", role: .destructive) { store.remove(id); dismiss() }
            Button("Cancelar", role: .cancel) {}
        } message: { Text("Sus conexiones también se quitan.") }
    }

    // MARK: Lectura

    private func reader(_ m: FamilyMember) -> some View {
        VStack(spacing: 20) {
            FamilyPhoto(member: m, size: 300, corner: 36)
                .overlay(RoundedRectangle(cornerRadius: 36, style: .continuous).strokeBorder(Skin.line, lineWidth: 4))
                .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
                .accessibilityLabel("Foto de \(m.name)")

            VStack(spacing: 8) {
                Text(m.name).font(Skin.title(44, relativeTo: .largeTitle)).foregroundStyle(Pal.ink)
                    .dynamicTypeSize(.xLarge ... .accessibility1).multilineTextAlignment(.center)
                Text(m.relation).font(.title3.weight(.heavy)).foregroundStyle(Pal.onInk)
                    .padding(.horizontal, 16).padding(.vertical, 6)
                    .background(Capsule().fill(Skin.accent))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Su historia").font(.headline.weight(.heavy)).foregroundStyle(Pal.text2)
                Text(m.bio.isEmpty ? "Todavía no hay una biografía. Toca «Editar» para escribirla." : m.bio)
                    .font(.title3.weight(.semibold)).foregroundStyle(Skin.ink)
                    .lineSpacing(5).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Skin.card))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Skin.line, lineWidth: 3))

            if !m.bio.isEmpty {
                Button { Speaker.shared.speak("\(m.name). \(m.relation). \(m.bio)") } label: {
                    Label("Escuchar su historia", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(BigButton())
            }
            Button { draft = m; editing = true } label: { Label("Editar", systemImage: "pencil") }
                .buttonStyle(BigButton(kind: .outline))
            Button { confirmDelete = true } label: { Label("Quitar del árbol", systemImage: "trash") }
                .buttonStyle(OutlinePill())
        }
    }

    // MARK: Edición

    private var editor: some View {
        VStack(spacing: 18) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    FamilyPhoto(member: draft, size: 220, corner: 30)
                        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(Skin.line, lineWidth: 4))
                    Image(systemName: "camera.fill").font(.title2.weight(.bold)).foregroundStyle(Pal.onInk)
                        .frame(width: 56, height: 56).background(Circle().fill(Skin.accent)).offset(x: 8, y: 8)
                }
            }
            .accessibilityLabel("Cambiar foto")
            .onChange(of: pickerItem) { _, new in
                Task {
                    if let data = try? await new?.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data), let jpg = ui.jpegData(compressionQuality: 0.8) { draft.photo = jpg }
                }
            }
            labeled("Nombre") { TextField("Nombre", text: $draft.name) }
            labeled("Quién es para ti") { TextField("Hija, nieto, amiga…", text: $draft.relation) }
            labeled("Biografía") {
                TextEditor(text: $draft.bio).frame(minHeight: 180).scrollContentBackground(.hidden)
            }
            Button {
                var d = draft; d.name = d.name.trimmingCharacters(in: .whitespaces)
                if !d.name.isEmpty { store.update(d); editing = false }
            } label: { Label("Guardar", systemImage: "checkmark") }
                .buttonStyle(BigButton())
                .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
            Button { editing = false } label: { Text("Cancelar") }
                .buttonStyle(BigButton(kind: .outline))
        }
    }

    private func labeled<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline.weight(.heavy)).foregroundStyle(Pal.text2)
            content()
                .font(.title3.weight(.semibold)).foregroundStyle(Skin.ink)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Skin.card))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Skin.line, lineWidth: 3))
        }
    }
}

// MARK: - Agregar a alguien al árbol

struct FamilyAddView: View {
    @ObservedObject var store: FamilyStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var relation = ""
    @State private var bio = ""
    @State private var photo: Data?
    @State private var item: PhotosPickerItem?
    @State private var other: UUID?
    @State private var connection: FamilyConnection = .childOf

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Button("Cancelar") { dismiss() }.buttonStyle(OutlinePill())
                    Spacer()
                    Text("Nueva persona").font(Skin.title(26, relativeTo: .title2)).foregroundStyle(Pal.ink)
                    Spacer()
                    Button("Guardar") { save() }
                        .buttonStyle(FilledPill()).disabled(!canSave).opacity(canSave ? 1 : 0.4)
                }

                PhotosPicker(selection: $item, matching: .images) {
                    FamilyPhoto(member: preview, size: 190, corner: 30)
                        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(Skin.line, lineWidth: 4))
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.fill").font(.title3.weight(.bold)).foregroundStyle(Pal.onInk)
                                .frame(width: 52, height: 52).background(Circle().fill(Skin.accent)).offset(x: 8, y: 8)
                        }
                }
                .accessibilityLabel("Elegir foto")
                .onChange(of: item) { _, new in
                    Task {
                        if let data = try? await new?.loadTransferable(type: Data.self),
                           let ui = UIImage(data: data) { photo = ui.jpegData(compressionQuality: 0.8) }
                    }
                }

                field("Nombre") { TextField("Ej. Sofía", text: $name) }
                field("Quién es para ti") { TextField("Hija, nieto, amiga…", text: $relation) }

                if !store.members.isEmpty {
                    field("¿Cómo se conecta?") {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("Conexión", selection: $connection) {
                                ForEach(FamilyConnection.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.menu).tint(Skin.accent)
                            if connection != .none {
                                Picker("Con", selection: Binding(get: { other ?? store.members.first?.id }, set: { other = $0 })) {
                                    ForEach(store.members) { Text($0.name).tag(Optional($0.id)) }
                                }
                                .pickerStyle(.menu).tint(Skin.accent)
                            }
                        }
                    }
                }
                field("Su historia (opcional)") {
                    TextEditor(text: $bio).frame(minHeight: 140).scrollContentBackground(.hidden)
                }
            }
            .padding(24)
            .frame(maxWidth: 640).frame(maxWidth: .infinity)
        }
        .background { SkinBackground() }
        .preferredColorScheme(.dark)
    }

    private var preview: FamilyMember {
        FamilyMember(name: name.isEmpty ? "?" : name, relation: relation, bio: "", photo: photo, x: 0, y: 0,
                     tone: store.members.count)
    }

    private func field<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline.weight(.heavy)).foregroundStyle(Pal.text2)
            content()
                .font(.title3.weight(.semibold)).foregroundStyle(Skin.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Skin.card))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Skin.line, lineWidth: 3))
        }
    }

    private func save() {
        let m = FamilyMember(name: name.trimmingCharacters(in: .whitespaces),
                             relation: relation.trimmingCharacters(in: .whitespaces),
                             bio: bio, photo: photo, x: 0, y: 0, tone: store.members.count)
        let target = connection == .none ? nil : (other ?? store.members.first?.id)
        store.add(m, connectedTo: target, as: connection)
        dismiss()
    }
}
