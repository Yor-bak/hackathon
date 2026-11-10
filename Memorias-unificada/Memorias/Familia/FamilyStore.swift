import SwiftUI
import UIKit

// MARK: - Modelo del árbol genealógico de Carmen

struct FamilyMember: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var relation: String          // «Hija», «Esposo», «Nieto»… (texto libre)
    var bio: String               // biografía que se ve al abrir a la persona
    var photo: Data?              // JPEG; nil = se muestra la inicial sobre un color
    var x: Double                 // posición en el lienzo (centro)
    var y: Double
    var tone: Int = 0

    var initial: String { String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased() }
    var uiImage: UIImage? { photo.flatMap(UIImage.init(data:)) }
}

struct FamilyLink: Identifiable, Codable, Equatable {
    enum Kind: String, Codable { case parentChild, partner }
    var id = UUID()
    var a: UUID                   // padre/madre (parentChild) o una de las dos parejas
    var b: UUID                   // hijo/a (parentChild) o la otra pareja
    var kind: Kind
}

/// Cómo se conecta una persona nueva con otra que ya está en el árbol.
enum FamilyConnection: String, CaseIterable, Identifiable {
    case childOf = "Es hijo/a de"
    case parentOf = "Es padre/madre de"
    case partnerOf = "Es pareja de"
    case none = "Sin conexión"
    var id: String { rawValue }
}

// MARK: - Almacén (se guarda en el dispositivo)

@MainActor
final class FamilyStore: ObservableObject {
    /// Una sola lista para Carmen y para el cuidador: lo que uno cambia, el otro lo ve.
    static let shared = FamilyStore()

    @Published private(set) var members: [FamilyMember] = []
    @Published private(set) var links: [FamilyLink] = []

    private var saveTask: Task<Void, Never>?
    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("familia3.json")
    }

    private struct Saved: Codable { var members: [FamilyMember]; var links: [FamilyLink] }

    init() {
        if let data = try? Data(contentsOf: Self.fileURL),
           let saved = try? JSONDecoder().decode(Saved.self, from: data) {
            members = saved.members; links = saved.links
        } else {
            seed()
        }
    }

    func member(_ id: UUID) -> FamilyMember? { members.first { $0.id == id } }

    // MARK: Cambios

    func add(_ m: FamilyMember, connectedTo other: UUID?, as kind: FamilyConnection) {
        var m = m
        if let other, let o = member(other), kind != .none {
            switch kind {
            case .childOf:   m.x = o.x;        m.y = o.y + 200
            case .parentOf:  m.x = o.x;        m.y = max(o.y - 200, 110)
            case .partnerOf: m.x = o.x + 190;  m.y = o.y
            case .none: break
            }
        } else {
            m.x = 160; m.y = 140
        }
        // Que no caiga encima de otra persona.
        while members.contains(where: { hypot($0.x - m.x, $0.y - m.y) < 120 }) { m.x += 150 }
        members.append(m)
        if let other, kind != .none {
            switch kind {
            case .childOf:   links.append(FamilyLink(a: other, b: m.id, kind: .parentChild))
            case .parentOf:  links.append(FamilyLink(a: m.id, b: other, kind: .parentChild))
            case .partnerOf: links.append(FamilyLink(a: other, b: m.id, kind: .partner))
            case .none: break
            }
        }
        save()
    }

    func move(_ id: UUID, to p: CGPoint) {
        guard let i = members.firstIndex(where: { $0.id == id }) else { return }
        members[i].x = max(70, p.x); members[i].y = max(70, p.y)
        save()
    }

    func update(_ m: FamilyMember) {
        guard let i = members.firstIndex(where: { $0.id == m.id }) else { return }
        members[i] = m
        save()
    }

    func remove(_ id: UUID) {
        members.removeAll { $0.id == id }
        links.removeAll { $0.a == id || $0.b == id }
        save()
    }

    // MARK: Guardado

    private func save() {
        saveTask?.cancel()
        let snapshot = Saved(members: members, links: links)
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            if let data = try? JSONEncoder().encode(snapshot) { try? data.write(to: Self.fileURL, options: .atomic) }
        }
    }

    // MARK: Ejemplo (sintético)

    private func seed() {
        let carmen = FamilyMember(name: "Carmen", relation: "Tú",
            bio: "Naciste en Puebla y creciste en una casa con patio y una higuera. Fuiste maestra de primaria durante treinta años y te encanta cocinar para toda la familia los domingos.",
            x: 330, y: 720, tone: 0)
        let ramon = FamilyMember(name: "Ramón", relation: "Esposo",
            bio: "Tu esposo desde 1971. Se conocieron en un baile en la plaza. Le gusta el café con pan y arreglar relojes.",
            x: 520, y: 720, tone: 2)
        let ana = FamilyMember(name: "Ana", relation: "Hija",
            bio: "Tu hija mayor. Vive cerca y te llama todas las tardes. Trabaja como enfermera y siempre te acompaña a tus citas.",
            x: 250, y: 530, tone: 1)
        let luis = FamilyMember(name: "Luis", relation: "Hijo",
            bio: "Tu hijo menor. Toca la guitarra y vive en la Ciudad de México. Viene a verte cada mes.",
            x: 590, y: 530, tone: 3)
        let sofia = FamilyMember(name: "Sofía", relation: "Nieta",
            bio: "La hija de Ana. Tiene siete años, dibuja flores y te pide siempre que le cuentes del patio de la casa de Puebla.",
            x: 250, y: 340, tone: 0)
        members = [carmen, ramon, ana, luis, sofia]
        links = [
            FamilyLink(a: carmen.id, b: ramon.id, kind: .partner),
            FamilyLink(a: carmen.id, b: ana.id, kind: .parentChild),
            FamilyLink(a: carmen.id, b: luis.id, kind: .parentChild),
            FamilyLink(a: ana.id, b: sofia.id, kind: .parentChild),
        ]
    }
}
