// LibroView.swift: «Mis recuerdos», el libro de fotos con filtros por década.

import SwiftUI

private struct LibroSelectedMemory: Identifiable { let id: UUID }

struct LibroView: View {
    @State private var memories: [BookPage] = [
        BookPage(faces: [FaceTag(name: "Luis", face: CGRect(x: 0.245, y: 0.305, width: 0.10, height: 0.10), person: CGRect(x: 0.175, y: 0.29, width: 0.255, height: 0.47)),
                         FaceTag(name: "Ramón", face: CGRect(x: 0.470, y: 0.350, width: 0.095, height: 0.085), person: CGRect(x: 0.426, y: 0.325, width: 0.313, height: 0.47))],
                 story: MemoryStory(sentences: [
                    "Tú estuviste con Luis y Ramón a la orilla del río.",
                    "Era un día de febrero, con el cielo muy azul y casi sin viento.",
                    "Salieron de casa antes del amanecer, con el termo de café y los panes que tú habías preparado la noche anterior.",
                    "Ramón se puso su sombrero favorito, ese que usa en todas las pescas, y no se lo quitó en toda la mañana.",
                    "Luis llevaba la caña nueva que le regalaron, y no dejaba de presumirla.",
                    "Caminaron un buen rato por la orilla hasta encontrar un lugar donde el agua estuviera tranquila.",
                    "Ramón le enseñó a Luis cómo lanzar la línea, igual que años atrás se lo enseñó su propio padre a él.",
                    "Lo que más te hizo reír fue ver a Luis casi caerse al agua cuando un pez grande le jaló la caña.",
                    "Ramón se burló de él un buen rato, pero luego lo ayudó a sacarlo con la red.",
                    "Comieron junto al río, con los pies metidos en el agua fría, y hablaron de cuando Luis era niño.",
                    "Al final del día pidieron que alguien les tomara esta foto: los dos juntos, con las cañas en alto.",
                    "Así quedó guardado este recuerdo: tu esposo y tu hijo, juntos y felices, en uno de los mejores días del año.",
                ], conversation: [
                    ChatMessage(role: .ai, content: .text("Veo a Luis y a Ramón en esta foto. ¿Dónde estaban ese día?")),
                    ChatMessage(role: .user, content: .text("En el río, fueron a pescar desde temprano.")),
                ]),
                 image: UIImage.bundled("pescador.jpg").map { Image(uiImage: $0) }, uiImage: UIImage.bundled("pescador.jpg"),
                 date: "14 de febrero de 2023", caption: "Pesca en el río", placeholder: [Pal.tones[0].bg, MemoryTheme.edgeBlue]),
        memory("pesca-1.jpg", date: "9 de octubre de 2021", caption: "Risas con papá",
               faces: [("Ramón", CGRect(x: 0.375, y: 0.234, width: 0.106, height: 0.206), CGRect(x: 0.09, y: 0.18, width: 0.56, height: 0.82)),
                       ("Luis", CGRect(x: 0.512, y: 0.206, width: 0.100, height: 0.215), CGRect(x: 0.33, y: 0.14, width: 0.40, height: 0.86))],
               ask: "Veo a Luis y a Ramón muy contentos. ¿Qué estaban celebrando?",
               answer: "Luis pescó su primer pez grande y su papá no paraba de reírse.",
               story: [
                "Tú estuviste con Ramón y Luis una tarde de octubre, a la orilla del río.",
                "Habían ido todos juntos desde temprano, y tú te quedaste sentada en la sombra con un termo de café.",
                "Desde ahí escuchabas las risas de los dos cada vez que algo se enredaba en la caña.",
                "Luis acababa de sacar su primer pez grande, y no podía creerlo.",
                "Ramón lo abrazó por los hombros, con su sombrero de siempre, y le dijo que ya era todo un pescador.",
                "Tú les pediste que se quedaran así un momento, con las cañas en alto, para tomarles la foto.",
                "Los dos salieron riéndose a carcajadas, y esa es la foto que más te gusta de ellos.",
                "Esa noche cenaron el pescado en casa, y Luis lo contó tantas veces que ya nadie lo dejaba terminar.",
                "Así quedó guardado este recuerdo: tu esposo y tu hijo, felices, a la orilla del río."
               ]),
        memory("pesca-2.jpg", date: "12 de abril de 1971", caption: "Tú a los veinte",
               faces: [("Carmen", CGRect(x: 0.347, y: 0.14, width: 0.096, height: 0.13), CGRect(x: 0.235, y: 0.10, width: 0.49, height: 0.855))],
               ask: "Esta foto es de ti, Carmen. ¿Recuerdas dónde fue?",
               answer: "Fue en el puerto, un domingo de primavera. Me acuerdo de esos pantalones.",
               story: [
                "Tú estás en esta foto, a los veinte años, con el pelo largo hasta la cintura.",
                "Era un domingo de primavera de 1971, y habían ido de paseo al puerto.",
                "Detrás de ti se ven los barcos, el pasto muy verde y las flores de la barda.",
                "Llevabas tus pantalones cortos de colores, los que tu mamá decía que eran demasiado atrevidos.",
                "Te los habías hecho tú misma, con tela de tres retazos distintos.",
                "Te apoyaste en la baranda, sonriendo un poco tímida, mientras alguien contaba hasta tres.",
                "Esa foto la guardaste muchos años en una caja de galletas, junto a las cartas de ese año.",
                "Ese mismo año conociste a Ramón, aunque todavía no lo sabías.",
                "Así quedó guardado este recuerdo: tú, joven, en un día claro, con toda la vida por delante."
               ]),
        memory("pesca-3.jpg", date: "5 de junio de 1971", caption: "El día de la boda",
               faces: [("Carmen", CGRect(x: 0.28, y: 0.22, width: 0.21, height: 0.28), CGRect(x: 0.0, y: 0.07, width: 0.55, height: 0.93)),
                       ("Ramón", CGRect(x: 0.49, y: 0.12, width: 0.25, height: 0.40), CGRect(x: 0.46, y: 0.0, width: 0.54, height: 1.0))],
               ask: "Qué foto tan especial. ¿Ese día se casaron Ramón y tú?",
               answer: "Sí, fue en junio. Yo estaba muy nerviosa y él no dejaba de sonreír.",
               story: [
                "Tú y Ramón se casaron un sábado de junio de 1971.",
                "Dormiste muy poco la noche anterior, entre los nervios y las últimas costuras del vestido.",
                "Llevabas el velo largo que había sido de tu abuela, y una corona pequeña que te prestó tu hermana.",
                "Ramón llegó con su traje oscuro y una flor blanca en la solapa, y desde que te vio no dejó de sonreír.",
                "En esta foto están muy juntos, con las manos entrelazadas, justo después de la ceremonia.",
                "Tú todavía temblabas un poco, y él te apretó la mano para que te tranquilizaras.",
                "Después hubo música, comida en el patio y baile hasta que se acabaron las velas.",
                "Se conocieron en un baile en la plaza, y ese día bailaron otra vez la misma canción.",
                "Así quedó guardado este recuerdo: el día en que empezó la vida que hoy sigues contando."
               ]),
        memory("pesca-4.jpg", date: "3 de septiembre de 1978", caption: "Esperando en la esquina",
               faces: [("Ramón", CGRect(x: 0.405, y: 0.645, width: 0.035, height: 0.05), CGRect(x: 0.395, y: 0.63, width: 0.055, height: 0.22)),
                       ("Carmen", CGRect(x: 0.445, y: 0.665, width: 0.035, height: 0.05), CGRect(x: 0.44, y: 0.65, width: 0.045, height: 0.20))],
               ask: "Se ven pequeños en la esquina. ¿Qué estaban esperando?",
               answer: "Esperábamos el camión para ir al centro. Era un domingo con mucho sol.",
               story: [
                "Tú y Ramón están en esta foto, de pie en una esquina, esperando el camión.",
                "Era un domingo de septiembre de 1978, con un cielo muy azul y casi sin nubes.",
                "Iban al centro a comprar los útiles de la escuela de Ana, que empezaba la semana siguiente.",
                "Te habías puesto tu vestido rosa favorito, y Ramón su camisa de los domingos.",
                "El semáforo cambiaba y cambiaba, y el camión no llegaba.",
                "Ramón bromeaba diciendo que caminando llegarían antes, pero tú preferiste esperar a la sombra del poste.",
                "Alguien les tomó esta foto desde lejos, sin que se dieran cuenta, y ustedes ni lo notaron.",
                "Después comieron helado en la plaza y regresaron a casa ya de noche.",
                "Así quedó guardado este recuerdo: un día cualquiera, de los que juntos hicieron una vida."
               ]),
        BookPage(date: "25 de diciembre de 1998", caption: "Amigas", placeholder: [Pal.tones[3].bg, MemoryTheme.edgeAmber]),
        BookPage(date: "8 de mayo de 2001", caption: "Campo", placeholder: [Pal.tones[1].bg, Pal.tones[2].bg]),
        BookPage(date: "30 de marzo de 2015", caption: "Ciudad", placeholder: [Pal.tones[0].bg, Pal.tones[1].bg]),
    ]
    @State private var selected: LibroSelectedMemory?
    /// Década elegida (nil = todas).
    @State private var decade: Int?
    @State private var showAdd = false
    private let cover = BookPage(caption: "Mis recuerdos", isCover: true)

    /// Año de un recuerdo, leído de su fecha («14 de febrero de 1971»).
    private func year(of page: BookPage) -> Int? {
        Int(page.date.split(separator: " ").last ?? "")
    }

    private var decades: [Int] {
        Array(Set(memories.compactMap { year(of: $0) }.map { $0 / 10 * 10 })).sorted()
    }

    /// Portada + los recuerdos de la temporada elegida, del más antiguo al más reciente.
    private var bookPages: [BookPage] {
        let list = memories.filter { m in
            guard let d = decade else { return true }
            return year(of: m).map { $0 / 10 * 10 == d } ?? false
        }
        .sorted { (year(of: $0) ?? 0) < (year(of: $1) ?? 0) }
        return [cover] + list
    }

    var body: some View {
        ZStack {
            MemoryTheme.darkBackground.ignoresSafeArea()
            GeometryReader { geo in
                // La tira de película siempre va ARRIBA y centrada; el libro queda centrado debajo y usa el resto del alto.
                VStack(spacing: 0) {
                    FilmStrip(titles: [(nil, "Todos")] + decades.map { ($0, "\($0)s") },
                              selection: decade, vertical: false, maxLength: geo.size.width - 24) { decade = $0 }
                        .padding(.top, 8)
                    book
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            LibroAddMemoryView { page in
                memories.append(page)
                decade = nil          // ver todos, para que el nuevo recuerdo aparezca
            }
        }
        .fullScreenCover(item: $selected) { sel in
            if let idx = memories.firstIndex(where: { $0.id == sel.id }) {
                MemoryDetailView(page: $memories[idx])
            }
        }
    }

    private var book: some View {
        PhotoBookView(title: "Mis recuerdos", pages: bookPages, onAdd: { showAdd = true }) { page in
            selected = LibroSelectedMemory(id: page.id)
        }
        .id(decade)      // al cambiar de temporada el libro vuelve a la portada
    }
}

extension UIImage {
    /// Imagen suelta dentro de la app (por ejemplo «pescador.jpg»).
    static func bundled(_ file: String) -> UIImage? {
        Bundle.main.path(forResource: file, ofType: nil).flatMap { UIImage(contentsOfFile: $0) }
    }
}


/// Arma un recuerdo con foto, personas marcadas (cara y cuerpo) e historia en segunda persona.
private func memory(_ file: String, date: String, caption: String,
                    faces: [(String, CGRect, CGRect)], ask: String, answer: String, story: [String]) -> BookPage {
    let ui = UIImage.bundled(file)
    return BookPage(faces: faces.map { FaceTag(name: $0.0, face: $0.1, person: $0.2) },
                    story: MemoryStory(sentences: story, conversation: [
                        ChatMessage(role: .ai, content: .text(ask)),
                        ChatMessage(role: .user, content: .text(answer)),
                    ]),
                    image: ui.map { Image(uiImage: $0) }, uiImage: ui,
                    date: date, caption: caption,
                    placeholder: [Pal.tones[0].bg, MemoryTheme.edgeBlue])
}
