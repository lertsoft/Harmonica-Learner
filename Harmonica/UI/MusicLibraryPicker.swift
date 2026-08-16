import MediaPlayer
import SwiftUI

struct MusicLibraryPicker: UIViewControllerRepresentable {
    let onPick: (URL, String) -> Void
    let onFailure: (String) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onFailure: onFailure, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.delegate = context.coordinator
        picker.allowsPickingMultipleItems = false
        picker.prompt = "Choose a downloaded, unprotected song"
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}

    final class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        private let onPick: (URL, String) -> Void
        private let onFailure: (String) -> Void
        private let onCancel: () -> Void

        init(
            onPick: @escaping (URL, String) -> Void,
            onFailure: @escaping (String) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onPick = onPick
            self.onFailure = onFailure
            self.onCancel = onCancel
        }

        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            mediaPicker.dismiss(animated: true)
            guard let item = mediaItemCollection.items.first,
                  let assetURL = item.assetURL else {
                onFailure("That song is protected, belongs to Apple Music, or is not downloaded on this device. Choose an unprotected local song instead.")
                return
            }
            onPick(assetURL, item.title ?? "Music Library Song")
        }

        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            mediaPicker.dismiss(animated: true)
            onCancel()
        }
    }
}
