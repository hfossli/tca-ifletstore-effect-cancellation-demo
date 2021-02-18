import ComposableArchitecture
import SwiftUI
import Combine

struct DetailState: Equatable {
    var time: Int = 0
    var me: AvatarState = AvatarState()
    var peer = AvatarState()
}

enum DetailAction: Equatable {
    case timerTicked
    case me(AvatarAction)
    case peer(AvatarAction)
    case onAppear
    case onDisappear
}

struct TimerId: Hashable {}

struct DetailEnvironment {
    var cancellationId: AnyHashable
}

let detailReducer = Reducer<DetailState, DetailAction, DetailEnvironment>.combine(
    avatarReducer.pullback(
        state: \.me,
        action: /DetailAction.me,
        environment: { env in
            AvatarEnvironment(cancellationId: [env.cancellationId, "me"])
        }
    ),
    avatarReducer.pullback(
        state: \.peer,
        action: /DetailAction.peer,
        environment: { env in
            AvatarEnvironment(cancellationId: [env.cancellationId, "peer"])
        }
    ),
    Reducer { state, action, env in
        
        switch action {
        case .timerTicked:
            state.time += 1
            return .none
            
        case .me(_):
            return .none
            
        case .peer(_):
            return .none
            
        case .onAppear:
            return Publishers.Timer(
                every: 1,
                tolerance: .zero,
                scheduler: DispatchQueue.main,
                options: nil
            )
            .autoconnect()
            .handleEvents(receiveSubscription: { (sub) in
                print("receiveSubscription peer (\(env.cancellationId))")
            }, receiveOutput: { (output) in
                print("receiveOutput peer (\(env.cancellationId))")
            }, receiveCompletion: { (completion) in
                print("receiveCompletion peer (\(env.cancellationId))")
            }, receiveCancel: {
                print("receiveCancel peer (\(env.cancellationId))")
            }, receiveRequest: { (demand) in
                print("receiveRequest peer (\(env.cancellationId))")
            })
            .catchToEffect()
            .map { _ in DetailAction.timerTicked }
            .cancellable(id: env.cancellationId)
            
        case .onDisappear:
            return .cancel(id: env.cancellationId)
        }
    }
)

struct DetailView: View {
    var store: Store<DetailState, DetailAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                HStack {
                    AvatarView(
                        store: self.store.scope(
                            state: \.me,
                            action: { .me($0) }
                        )
                    )
                    Text("Me").font(.title)
                }
                
                HStack {
                    Image(systemName: "waveform")
                    Text("Talking for \(viewStore.time) seconds")
                }
                
                HStack {
                    AvatarView(
                        store: self.store.scope(
                            state: \.peer,
                            action: { .peer($0) }
                        )
                    )
                    Text("Peer").font(.title)
                }
            }.onAppear {
                viewStore.send(.onAppear)
            }
            .onDisappear {
                viewStore.send(.onDisappear)
            }
        }
    }
}

#if DEBUG
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(store: Store(
            initialState: .init(),
            reducer: .empty,
            environment: ()
        ))
    }
}
#endif
