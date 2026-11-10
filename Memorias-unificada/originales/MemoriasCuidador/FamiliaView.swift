import SwiftUI

// MARK: - Pantalla (pestaña "Familia")

struct FamiliaView: View {
    @Environment(AppStore.self) private var store
    @State private var showAdd = false
    @State private var confirmRemove = false

    private var selected: Relative? {
        store.relative(store.familySelectedID) ?? store.me
    }

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ScreenTitle(text: "Familia de Carmen")
                        .padding(.horizontal, Theme.screenPadding)
                    MemoBanner(message: "Toca una cara para saber quién es.")
                        .padding(.horizontal, Theme.screenPadding)
                        .readableWidth()

                    // El árbol crece hacia los lados: si no cabe, se desliza.
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            FamilyTree(selectedID: $store.familySelectedID)
                                .padding(.horizontal, 8)
                                .containerRelativeFrame(.horizontal) { width, _ in
                                    max(width, TreeLayout(store: store).width + 16)
                                }
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .onChange(of: store.familySelectedID) { _, id in
                            withAnimation { proxy.scrollTo(id, anchor: .center) }
                        }
                    }
                    .frame(height: TreeLayout.height)

                    if !store.friends.isEmpty {
                        friendsRow
                    }

                    if let selected {
                        infoCard(selected)
                            .padding(.horizontal, Theme.screenPadding)
                            .readableWidth()
                    }

                    Button {
                        showAdd = true
                    } label: {
                        Label("Agregar persona", systemImage: "person.badge.plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal, Theme.screenPadding)
                    .readableWidth()
                }
                .padding(.bottom, 24)
                .animation(.spring(duration: 0.45), value: store.relatives)
            }
            .caregiverChrome(title: "Familia de Carmen")
            .sheet(isPresented: $showAdd) {
                AgregarPersonaView(suggestedFor: selected)
            }
        }
    }

    // MARK: Amigos y vecinos (no van en las ramas, pero sí tienen álbum)

    private var friendsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Amigos y vecinos", icon: "house")
                .padding(.horizontal, Theme.screenPadding)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(store.friends) { friend in
                        FaceButton(member: friend, label: friend.name,
                                   relation: store.relationText(friend),
                                   selected: friend.id == store.familySelectedID) {
                            store.familySelectedID = friend.id
                        }
                        .padding(.bottom, 26)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 4)
            }
        }
    }

    // MARK: Tarjeta de la persona elegida

    private func infoCard(_ person: Relative) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                FacePhoto(photoData: person.photoData, size: 56, lineWidth: 3.5)
                VStack(alignment: .leading, spacing: 0) {
                    Text(store.treeName(person))
                        .font(.rounded(32, relativeTo: .largeTitle))
                        .foregroundStyle(Theme.text)
                        .minimumScaleFactor(0.7)
                    Text(store.relationText(person))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if person.role != .me {
                    Button {
                        confirmRemove = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(RoundIconButtonStyle())
                    .accessibilityLabel("Quitar a \(person.name) del árbol")
                    // Pegada al botón, para que la pregunta salga junto al bote de basura.
                    .confirmationDialog(removeTitle, isPresented: $confirmRemove, titleVisibility: .visible) {
                        Button("Quitar", role: .destructive) { store.removeRelative(id: person.id) }
                    } message: {
                        Text("Se puede deshacer durante 8 segundos.")
                    }
                }
            }

            Button {
                Speaker.shared.speak(store.narration(person))
            } label: {
                Label("Escuchar quién es", systemImage: "speaker.wave.2")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(16)
        .cardStyle()
    }

    private var removeTitle: String {
        guard let selected else { return "" }
        let others = store.dependents(of: selected.id).map(\.name)
        if others.isEmpty { return "¿Quitar a \(selected.name) del árbol?" }
        return "¿Quitar a \(selected.name) del árbol? También se quitará a "
            + ListFormatter.localizedString(byJoining: others) + "."
    }
}

// MARK: - Acomodo del árbol
// Se calcula con las personas del store: al agregar a alguien, el árbol se reacomoda solo.
// Abajo Carmen y su pareja (el tronco); en medio cada hijo con su pareja; arriba los nietos.

struct TreeLayout {
    struct Branch { let from: CGPoint; let to: CGPoint; let width: CGFloat }

    static let height: CGFloat = 430
    private static let rowGrandkids: CGFloat = 56   // y de los nietos de los extremos; los del centro suben 20
    private static let rowChildren: CGFloat = 192
    private static let rowMe: CGFloat = 326
    private static let coupleHalf: CGFloat = 35     // media distancia entre las caras de una pareja
    private static let kidStep: CGFloat = 80        // distancia entre nietos
    private static let familyGap: CGFloat = 26
    private static let margin: CGFloat = 30

    var width: CGFloat = 342
    var positions: [String: CGPoint] = [:]
    var rings: [CGPoint] = []
    var branches: [Branch] = []
    var trunkX: CGFloat = 171

    @MainActor
    init(store: AppStore) {
        struct Family { let child: Relative; let partner: Relative?; let kids: [Relative]; let width: CGFloat }
        let families: [Family] = store.children.map { child in
            let partner = store.partner(of: child.id)
            let kids = store.kids(of: child.id)
            let coupleWidth: CGFloat = partner == nil ? 74 : 74 + Self.coupleHalf * 2
            let kidsWidth = CGFloat(max(kids.count - 1, 0)) * Self.kidStep + 74
            return Family(child: child, partner: partner, kids: kids, width: max(coupleWidth, kidsWidth))
        }

        let total = families.map(\.width).reduce(0, +) + CGFloat(max(families.count - 1, 0)) * Self.familyGap
        width = max(342, total + Self.margin * 2)
        trunkX = width / 2
        let trunkTop = CGPoint(x: trunkX, y: Self.rowMe + 4)

        // Carmen y su pareja, sobre el tronco
        if let me = store.me {
            if let partner = store.myPartner {
                positions[me.id] = CGPoint(x: trunkX - Self.coupleHalf, y: Self.rowMe)
                positions[partner.id] = CGPoint(x: trunkX + Self.coupleHalf, y: Self.rowMe)
                rings.append(CGPoint(x: trunkX, y: Self.rowMe - 27))
            } else {
                positions[me.id] = CGPoint(x: trunkX, y: Self.rowMe)
            }
        }

        var x = (width - total) / 2
        for family in families {
            let cx = x + family.width / 2
            let anchor = CGPoint(x: cx, y: Self.rowChildren)
            if let partner = family.partner {
                positions[family.child.id] = CGPoint(x: cx - Self.coupleHalf, y: Self.rowChildren)
                positions[partner.id] = CGPoint(x: cx + Self.coupleHalf, y: Self.rowChildren)
                rings.append(CGPoint(x: cx, y: Self.rowChildren - 27))
            } else {
                positions[family.child.id] = anchor
            }
            branches.append(Branch(from: trunkTop, to: anchor, width: 9))

            let mid = CGFloat(family.kids.count - 1) / 2
            for (i, kid) in family.kids.enumerated() {
                let kx = cx + (CGFloat(i) - mid) * Self.kidStep
                // Los del centro un poco más arriba, como en el boceto.
                let lift = mid > 0 ? 20 * (1 - abs(CGFloat(i) - mid) / mid) : 20
                let point = CGPoint(x: kx, y: Self.rowGrandkids - lift)
                positions[kid.id] = point
                branches.append(Branch(from: anchor, to: point, width: 7))
            }
            x += family.width + Self.familyGap
        }
    }

    /// Curva suave de una rama, del punto bajo al punto alto.
    static func path(_ b: Branch) -> Path {
        Path { p in
            p.move(to: b.from)
            let dy = b.from.y - b.to.y
            p.addCurve(to: b.to,
                       control1: CGPoint(x: b.from.x + (b.to.x - b.from.x) * 0.3, y: b.from.y - dy * 0.3),
                       control2: CGPoint(x: b.to.x + (b.from.x - b.to.x) * 0.1, y: b.to.y + dy * 0.42))
        }
    }

    /// Punto a la mitad de la rama, para poner hojas.
    static func midpoint(_ b: Branch) -> CGPoint {
        let dy = b.from.y - b.to.y
        let c1 = CGPoint(x: b.from.x + (b.to.x - b.from.x) * 0.3, y: b.from.y - dy * 0.3)
        let c2 = CGPoint(x: b.to.x + (b.from.x - b.to.x) * 0.1, y: b.to.y + dy * 0.42)
        // Bézier cúbica en t = 0.5
        return CGPoint(x: (b.from.x + 3 * c1.x + 3 * c2.x + b.to.x) / 8,
                       y: (b.from.y + 3 * c1.y + 3 * c2.y + b.to.y) / 8)
    }
}

// MARK: - Árbol

private struct FamilyTree: View {
    @Environment(AppStore.self) private var store
    @Binding var selectedID: String

    var body: some View {
        let layout = TreeLayout(store: store)
        let inTree = store.relatives.filter { layout.positions[$0.id] != nil }

        ZStack(alignment: .topLeading) {
            // Tronco
            Path { p in
                let x = layout.trunkX
                p.move(to: CGPoint(x: x - 25, y: TreeLayout.height))
                p.addCurve(to: CGPoint(x: x - 11, y: 350), control1: CGPoint(x: x - 18, y: 402), control2: CGPoint(x: x - 11, y: 382))
                p.addLine(to: CGPoint(x: x + 11, y: 350))
                p.addCurve(to: CGPoint(x: x + 25, y: TreeLayout.height), control1: CGPoint(x: x + 11, y: 382), control2: CGPoint(x: x + 18, y: 402))
                p.closeSubpath()
            }
            .fill(Theme.ink)

            ForEach(Array(layout.branches.enumerated()), id: \.offset) { _, b in
                TreeLayout.path(b)
                    .stroke(Theme.ink, style: StrokeStyle(lineWidth: b.width, lineCap: .round))
            }

            // Hojas a los lados de cada rama
            ForEach(Array(layout.branches.enumerated()), id: \.offset) { i, b in
                let m = TreeLayout.midpoint(b)
                let side: CGFloat = b.to.x < b.from.x ? -1 : 1
                Ellipse()
                    .fill(Theme.faceFillAlt)
                    .frame(width: 20, height: 10)
                    .rotationEffect(.degrees(Double(side) * (i.isMultiple(of: 2) ? 30 : -25)))
                    .position(x: m.x + 16 * side, y: m.y + 6)
                Ellipse()
                    .fill(Theme.faceFillAlt)
                    .frame(width: 20, height: 10)
                    .rotationEffect(.degrees(Double(side) * -35))
                    .position(x: m.x - 14 * side, y: m.y - 14)
            }
            .accessibilityHidden(true)

            // Anillos de las parejas
            ForEach(Array(layout.rings.enumerated()), id: \.offset) { _, p in
                ZStack {
                    Circle().stroke(Theme.ink, lineWidth: 2.5).frame(width: 12, height: 12).offset(x: -4)
                    Circle().stroke(Theme.ink, lineWidth: 2.5).frame(width: 12, height: 12).offset(x: 4)
                }
                .position(p)
                .accessibilityHidden(true)
            }

            ForEach(inTree) { member in
                FaceButton(member: member, label: store.treeName(member),
                           relation: store.relationText(member),
                           selected: member.id == selectedID,
                           tilt: member.id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 2 == 0 ? -1.5 : 1.5) {
                    selectedID = member.id
                }
                .id(member.id)
                .position(layout.positions[member.id] ?? .zero)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: layout.width, height: TreeLayout.height)
    }
}

// MARK: - Cara (rama con rostro)

struct FacePhoto: View {
    let photoData: Data?
    var size: CGFloat = 58
    var ring: Color = Theme.ink
    var lineWidth: CGFloat = 3.5

    var body: some View {
        ZStack {
            Circle().fill(Theme.faceFill)
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(Theme.ink)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(ring, lineWidth: lineWidth))
    }
}

private struct FaceButton: View {
    let member: Relative
    let label: String
    let relation: String
    let selected: Bool
    var tilt: Double = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if selected {
                    // Elegido = amarillo
                    Circle().stroke(Theme.attention, lineWidth: 4).frame(width: 76, height: 76)
                }
                FacePhoto(photoData: member.photoData,
                          ring: selected ? Theme.attention : Theme.ink,
                          lineWidth: selected ? 5 : 3.5)

                Text(label)
                    .font(.rounded(16, relativeTo: .callout))
                    .foregroundStyle(selected ? Theme.onInk : Theme.text)
                    .lineLimit(1)
                    // El nombre completo puede ser más ancho que la cara (74 pt): "Roberto", "Andrés".
                    .fixedSize()
                    .padding(.horizontal, 7)
                    .frame(height: 26)
                    .chunky(fill: selected ? Theme.attention : Theme.surface,
                            edge: selected ? Theme.attentionEdge : Theme.line,
                            outline: selected ? nil : Theme.line, radius: 10, depth: 3)
                    // Etiquetas ligeramente inclinadas, como en el camino
                    .rotationEffect(.degrees(tilt))
                    .dynamicTypeSize(TypeRange.tabBar)
                    .offset(y: 35)
            }
            .frame(width: 74, height: 74)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), \(relation)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
