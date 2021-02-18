import ComposableArchitecture
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        struct CancellationId: Hashable {}
        let view = AppView(store: Store(
            initialState: .init(),
            reducer: appReducer,
            environment: AppEnvironment(cancellationId: CancellationId())
        ))
        window?.rootViewController = UIHostingController(rootView: view)
        window?.makeKeyAndVisible()
    }

}
