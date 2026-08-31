import SwiftUI
import UIKit

/// Re-enables the interactive edge-swipe pop gesture for views that hide the
/// navigation bar (SwiftUI disables it whenever the bar is hidden).
struct InteractivePopGestureEnabler: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        Task { @MainActor in
            context.coordinator.attach(from: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.restore()
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var navigationController: UINavigationController?
        private weak var originalDelegate: (any UIGestureRecognizerDelegate)?

        func attach(from view: UIView) {
            var responder: UIResponder? = view
            while let next = responder?.next {
                if let navigationController = next as? UINavigationController {
                    self.navigationController = navigationController
                    let gesture = navigationController.interactivePopGestureRecognizer
                    originalDelegate = gesture?.delegate
                    gesture?.delegate = self
                    gesture?.isEnabled = true
                    return
                }
                responder = next
            }
        }

        func restore() {
            let gesture = navigationController?.interactivePopGestureRecognizer
            gesture?.delegate = originalDelegate
            gesture?.isEnabled = originalDelegate != nil
            navigationController = nil
            originalDelegate = nil
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let navigationController else { return false }
            return navigationController.viewControllers.count > 1
        }
    }
}
