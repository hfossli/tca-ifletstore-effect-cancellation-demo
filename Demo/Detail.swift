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
    var bag = CancellationBag.autoId()
    var me: AvatarEnvironment { .init(bag: .autoId(childOf: bag)) }
    var peer: AvatarEnvironment { .init(bag: .autoId(childOf: bag)) }
}

let detailReducer = Reducer<DetailState, DetailAction, DetailEnvironment>.combine(
    avatarReducer.pullback(
        state: \.me,
        action: /DetailAction.me,
        environment: { $0.me }
    ),
    avatarReducer.pullback(
        state: \.peer,
        action: /DetailAction.peer,
        environment: { $0.peer }
    ),
    Reducer { state, action, env in
        
        enum CancellationID: Hashable, CaseIterable {
            case timer
        }
        
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
        .catchToEffect()
        .cancellable(id: CancellationID.timer, bag: env.bag)
        .map { _ in DetailAction.timerTicked }
            
        case .onDisappear:
            return .cancel(ids: CancellationID.allCases, bag: env.bag)
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
