//
//  Created by Кирилл Кошкарёв on 09.02.2024.
//

import SwiftUI

struct FavoriteList<VM: ViewModel>: View
    where VM.State == FavoriteListState, VM.Action == FavoriteListAction
{

    @ObservedObject var viewModel: VM

    var body: some View {
        let isNavigationDestinationPresented = Binding<Bool>(
            get: { viewModel.state.presentedScreen.isNavigationDestination },
            set: { if !$0 { viewModel.handle(action: .screenClosed) } }
        )

        NavigationStack {
            Form {
                List {
                    ForEach(viewModel.state.favorites, id: \.self) { (item: FavoriteItem) in
                        element(item: item)
                            .onTapGesture {
                                viewModel.handle(action: .selectItem(item))
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.handle(action: .deleteItem(index))
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("useCases_favoritePostsButton_title")
                        .frame(alignment: .leading)
                        .font(.title2.weight(.bold))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton()
                }
            }
            .navigationDestination(isPresented: isNavigationDestinationPresented) {
                if case let .favoritePost(vm) = viewModel.state.presentedScreen {
                    FavoriteView(viewModel: vm)
                }
            }
            .onFirstAppear {
                viewModel.handle(action: .firstAppear)
            }
        }
    }

    private func element(item: FavoriteItem) -> some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .foregroundColor(.secondaryBackground)
                    .frame(width: 50, height: 50)

                Image(systemName: item.useCase.imageName)
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading) {
                Text(item.topic)
                    .lineLimit(1)
                    .font(.headline)

                Text(item.date)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }
        }
    }
}

// MARK: - Bindings

struct FavoriteListState: Equatable {
    var favorites: [FavoriteItem]
    var presentedScreen: PresentedScreen
}

struct FavoriteItem: Identifiable, Hashable {
    let id: String
    let useCase: UseCase
    let topic: String
    let date: String
}

extension FavoriteListState.PresentedScreen {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none),
             (.favoritePost, .favoritePost):
            true
        default:
            false
        }
    }
}

enum FavoriteListAction: Equatable {
    case firstAppear
    case selectItem(FavoriteItem)
    case deleteItem(Int)
    case screenClosed
}

extension FavoriteListState {

    static var initial: Self {
        Self(
            favorites: [],
            presentedScreen: .none
        )
    }

    enum PresentedScreen: Equatable {
        case none
        case favoritePost(FavoriteViewModel)

        var isNavigationDestination: Bool {
            switch self {
            case .none:
                false
            case .favoritePost:
                true
            }
        }
    }
}
