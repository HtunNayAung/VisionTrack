import SwiftUI
import UIKit

struct LiveMetalCameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LiveMetalCameraViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        print("Available Storyboard Identifiers: \(storyboard)")

        guard let viewController = storyboard.instantiateViewController(withIdentifier: "LiveMetalCameraViewController") as? LiveMetalCameraViewController else {
            fatalError("🚨 Error: Could not find 'LiveMetalCameraViewController' in Main.storyboard")
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: LiveMetalCameraViewController, context: Context) {}
}
