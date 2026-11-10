import SwiftUI
import PhotosUI
import UIKit

extension UIImage {
    /// Reduce la foto (y la deja derecha, sin giros ocultos) para que el libro no se trabe con fotos de 12 megapíxeles.
    func downscaled(maxSide: CGFloat = 1600) -> UIImage {
        let k = min(1, maxSide / max(size.width, size.height))
        let target = CGSize(width: (size.width * k).rounded(), height: (size.height * k).rounded())
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 1
        return UIGraphicsImageRenderer(size: target, format: fmt).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

/// Cámara del sistema (solo si el dispositivo la tiene).
struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = .camera
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ p: CameraPicker) { parent = p }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onImage(img) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

/// Botón «+» que deja subir una foto de la galería o tomarla con la cámara.
struct PhotoAddButton: View {
    var size: CGFloat = 88
    var onImage: (UIImage) -> Void

    @State private var showOptions = false
    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var item: PhotosPickerItem?

    var body: some View {
        Button { showOptions = true } label: {
            Image(systemName: "plus")
                .font(.system(size: size * 0.45, weight: .heavy))
                .foregroundStyle(MemoryTheme.onAccent)
                .frame(width: size, height: size)
                .background(Circle().fill(MemoryTheme.amber))
        }
        .buttonStyle(ChunkyPress(edge: MemoryTheme.edgeAmber))
        .accessibilityLabel("Agregar foto")
        .accessibilityHint("Elige una foto de la galería o toma una nueva")
        .confirmationDialog("Agregar foto", isPresented: $showOptions, titleVisibility: .visible) {
            Button("Elegir de la galería") { showLibrary = true }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Tomar foto") { showCamera = true }
            }
            Button("Cancelar", role: .cancel) {}
        }
        .photosPicker(isPresented: $showLibrary, selection: $item, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(onImage: { onImage($0.downscaled()) }).ignoresSafeArea()
        }
        .onChange(of: item) { _, new in
            Task {
                if let data = try? await new?.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                    onImage(ui.downscaled())
                }
                item = nil
            }
        }
    }
}
