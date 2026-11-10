import SwiftUI

struct CuidadorRecuerdosView: View {
    @Environment(AppStore.self) private var store
    @State private var mode: Album.Kind = .person
    @State private var showAdd = false
    @State private var showAddPerson = false

    /// "Por persona" sale del árbol de la familia: siempre las mismas personas.
    private var albums: [Album] {
        mode == .person ? store.personAlbums : store.albums.filter { $0.kind == mode }
    }
    private let columns = [GridItem(.flexible(), spacing: 12, alignment: .top),
                           GridItem(.flexible(), alignment: .top)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ScreenTitle(text: "Recuerdos")
                    FatTabs(selection: $mode, options: [
                        (Album.Kind.person, "Por persona", "person.2"),
                        (Album.Kind.experience, "Experiencias", "sparkles")
                    ])

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(albums) { album in
                            AlbumCard(album: album)
                        }
                        if mode == .person {
                            addPersonCard
                        }
                    }
                    .animation(.default, value: albums.map(\.id))

                    Text("«Le calma» se mide con el ritmo cardiaco del Apple Watch cuando Carmen ve el álbum. Fotos y datos de ejemplo.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        showAdd = true
                    } label: {
                        Label("Agregar recuerdo", systemImage: "plus")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 24)
                .readableWidth()
            }
            .caregiverChrome(title: "Recuerdos")
            .sheet(isPresented: $showAdd) { AgregarRecuerdoView() }
            .sheet(isPresented: $showAddPerson) { AgregarPersonaView() }
        }
    }

    /// Agregar a alguien aquí también lo agrega al árbol.
    private var addPersonCard: some View {
        Button {
            showAddPerson = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus").font(.system(size: 36))
                Text("Agregar persona").font(.headline)
                Text("También va al árbol")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 176)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCorner))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardCorner)
                .strokeBorder(Theme.ink, style: StrokeStyle(lineWidth: 2.5, dash: [7, 5])))
        }
        .buttonStyle(.plain)
    }
}

private struct AlbumCard: View {
    let album: Album

    private var cover: Color {
        // Color estable por álbum (hashValue cambia en cada arranque).
        let seed = album.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return [Theme.upcoming, Theme.faceFillAlt, Color(hex: 0x1B4A63), Theme.line][seed % 4]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                cover
                if let data = album.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    Image(systemName: album.kind == .person ? "person.fill" : "photo.on.rectangle")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.bottom, 26)   // deja lugar a la etiqueta de abajo
                }
                badge
                    .padding(8)
            }
            .frame(height: 112)

            VStack(alignment: .leading, spacing: 0) {
                Text(album.name)
                    .font(.rounded(23, relativeTo: .title3))
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(Theme.text)
                Text(album.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        // Las dos tarjetas de cada fila miden lo mismo aunque un nombre ocupe dos líneas.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner))
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var badge: some View {
        if album.calms == true {
            StatusPill(kind: .done, text: "Le calma", icon: "heart.fill", compact: true)
                .dynamicTypeSize(TypeRange.fixedWidth)
        } else {
            StatusPill(kind: .upcoming, text: "Sin datos aún", icon: "clock", compact: true)
                .dynamicTypeSize(TypeRange.fixedWidth)
        }
    }
}
