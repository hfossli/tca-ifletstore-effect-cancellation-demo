import ComposableArchitecture
import SwiftUI

struct DetailState: Equatable {
    var time: Int = 0
    var me: AvatarState = AvatarState()
    var peer = AvatarState()
}

enum DetailAction: Equatable {
    case timerTicked
    case me(AvatarAction)
    case peer(AvatarAction)
}

struct TimerId: Hashable {}



let detailReducer = Reducer<DetailState, DetailAction, Void>.combine(
    avatarReducer.pullback(
        state: \.me,
        action: /DetailAction.me,
        environment: { env in
            struct Cancellation: Hashable {}
            return AvatarEnvironment(cancellationId: Cancellation())
        }
    ),
    avatarReducer.pullback(
        state: \.peer,
        action: /DetailAction.peer,
        environment: { env in
            struct Cancellation: Hashable {}
            return AvatarEnvironment(cancellationId: Cancellation())
        }
    ),
    Reducer { state, action, _ in
        switch action {
        case .timerTicked:
            state.time += 1
            return .none
            
        case .me(_):
            return .none
            
        case .peer(_):
            return .none
        }
    }
)
.lifecycle(onAppear: {
    Effect.timer(id: TimerId(), every: 1, tolerance: .zero, on: DispatchQueue.main)
        .map { _ in DetailAction.timerTicked }
}, onDisappear: {
    .cancel(id: TimerId())
})

struct DetailView: View {
    let store: Store<DetailState, LifecycleAction<DetailAction>>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                VStack {
                    AvatarView(
                        store: self.store.scope(
                            state: \.me,
                            action: { .action(DetailAction.me($0)) }
                        )
                    )
                    Text("Me").font(.title)
                }
                
                HStack {
                    Image(systemName: "waveform")
                    Text("Talking for \(viewStore.time) seconds")
                }
                
                VStack {
                    AvatarView(
                        store: self.store.scope(
                            state: \.me,
                            action: { .action(DetailAction.me($0)) }
                        )
                    )
                    Text("Peer").font(.title)
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
