import SwiftUI
import Vision
import UIKit

/// Detecta, por cada persona de la foto, su cara y su cuerpo (Vision, en el dispositivo).
/// Los rectángulos salen normalizados (0–1) con origen arriba a la izquierda.
enum PersonDetector {
    static func detect(in image: UIImage) async -> [FaceTag] {
        guard let cg = image.cgImage else { return [] }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        return await Task.detached(priority: .userInitiated) {
            let faceReq = VNDetectFaceRectanglesRequest()
            let humanReq = VNDetectHumanRectanglesRequest()
            humanReq.upperBodyOnly = false
            let handler = VNImageRequestHandler(cgImage: cg, orientation: orientation)
            try? handler.perform([faceReq, humanReq])

            func flip(_ r: CGRect) -> CGRect {
                CGRect(x: r.minX, y: 1 - r.maxY, width: r.width, height: r.height)
            }
            let faces = (faceReq.results ?? []).map { flip($0.boundingBox) }
            var humans = (humanReq.results ?? []).map { flip($0.boundingBox) }

            var tags: [FaceTag] = []
            // Cada cara se une al cuerpo que la contiene; si no hay, se estima uno.
            for face in faces.sorted(by: { $0.minX < $1.minX }) {
                let center = CGPoint(x: face.midX, y: face.midY)
                var person: CGRect
                if let i = humans.firstIndex(where: { $0.contains(center) }) {
                    person = humans.remove(at: i)
                } else {
                    person = CGRect(x: face.midX - face.width * 1.2, y: face.minY - face.height * 0.3,
                                    width: face.width * 2.4, height: face.height * 5)
                        .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
                }
                tags.append(FaceTag(name: "Persona \(tags.count + 1)", face: face, person: person))
            }
            // Cuerpos sin cara visible (de espaldas, de perfil lejano…).
            for person in humans.sorted(by: { $0.minX < $1.minX }) {
                let face = CGRect(x: person.midX - person.width * 0.2, y: person.minY,
                                  width: person.width * 0.4, height: person.width * 0.4)
                tags.append(FaceTag(name: "Persona \(tags.count + 1)", face: face, person: person))
            }
            return tags
        }.value
    }
}

private extension CGImagePropertyOrientation {
    init(_ o: UIImage.Orientation) {
        switch o {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
