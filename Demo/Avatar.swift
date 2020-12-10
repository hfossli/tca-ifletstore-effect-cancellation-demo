import ComposableArchitecture
import Combine
import SwiftUI

struct AvatarState: Equatable {
    var image: UIImage?
    var error: AvatarError?
}

enum AvatarAction: Equatable {
    case onAppear
    case onDisappear
    case load
    case loaded(UIImage)
    case failed(AvatarError)
}

enum AvatarError: Error, Equatable {
    case network
}

let avatarReducer = Reducer<AvatarState, AvatarAction, Void> { state, action, env in
    
    struct Cancellation: Hashable {}
    
    switch action {
    
    case .load:
        return Just(UIImage(systemName: "faceid")!)
            .map { AvatarAction.loaded($0) }
            .replaceError(with: AvatarAction.failed(.network))
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToEffect()
        
    case .loaded(let image):
        state.image = image
        return .none
        
    case .failed(let error):
        state.error = error
        return .none
        
    case .onAppear:
        return .init(value: .load)
        
    case .onDisappear:
        return .cancel(id: Cancellation())
    }
}

struct AvatarView: View {
    let store: Store<AvatarState, AvatarAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 16) {
                if let _ = viewStore.error {
                    Image(systemName: "person.crop.circle.badge.xmark")
                } else if let image = viewStore.image {
                    Image(uiImage: image)
                } else {
                    Image(systemName: "clock")
                }
            }.onAppear {
                viewStore.send(.onAppear)
            }.onDisappear {
                viewStore.send(.onDisappear)
            }
        }
    }
}

#if DEBUG
struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(store: Store(
            initialState: .init(),
            reducer: .empty,
            environment: ()
        ))
    }
}
#endif
