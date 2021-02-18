import ComposableArchitecture
import SwiftUI

struct AppState: Equatable {
    var detail1: DetailState?
    var detail2: DetailState? = DetailState()
}

enum AppAction {
    case presentDetail1
    case dismissDetail1
    case detail1(DetailAction)
    case detail2(DetailAction)
}

struct AppEnvironment {
    let cancellationId: AnyHashable
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    Reducer { state, action, env in
        switch action {
        case .presentDetail1:
            state.detail1 = .init()
            return .none

        case .dismissDetail1:
            state.detail1 = nil
            return .none
            
        case .detail1(.onDisappear):
            state.detail1 = nil
            return .none

        case .detail1(_):
            return .none
            
        case .detail2(_):
            return .none
        }
    }.presents(
        detailReducer,
        cancelEffectsOnDismiss: true,
        state: \.detail1,
        action: /AppAction.detail1,
        environment: { env in
            DetailEnvironment(cancellationId: [env.cancellationId, 1])
        }
    ).presents(
        detailReducer,
        cancelEffectsOnDismiss: true,
        state: \.detail2,
        action: /AppAction.detail2,
        environment: { env in
            DetailEnvironment(cancellationId: [env.cancellationId, 2])
        }
    )
)

struct AppView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 16) {
                Text("App").font(.title).padding(.top, 100)
                if viewStore.state.detail1 != nil {
                    Button(action: { viewStore.send(.dismissDetail1) }) {
                        Text("Dismiss Detail")
                    }
                } else {
                    Button(action: { viewStore.send(.presentDetail1) }) {
                        Text("Present Detail")
                    }
                }
                
                IfLetStore(self.store.scope(
                    state: \.detail1,
                    action: AppAction.detail1
                )) { detailStore in
                    DetailView(store: detailStore)
                }
                
                IfLetStore(self.store.scope(
                    state: \.detail2,
                    action: AppAction.detail2
                )) { detailStore in
                    DetailView(store: detailStore)
                }
                
                Spacer()
            }
        }
    }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(store: Store(
            initialState: .init(),
            reducer: .empty,
            environment: ()
        ))
    }
}
#endif
