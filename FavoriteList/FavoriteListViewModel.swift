//
//  Created by Кирилл Кошкарёв on 11.02.2024.
//

import SwiftUI

class FavoriteListViewModel: ViewModel {

    @Published var state: FavoriteListState

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM HH:mm"
        return dateFormatter
    }()

    // MARK: - Init

    init(state: FavoriteListState = .initial) {
        self.state = state
    }

    func handle(action: FavoriteListAction) {
        switch action {
        case .firstAppear:
            state.favorites = SharedEntities.favorites.map { data in
                FavoriteItem(
                    id: data.id,
                    useCase: data.useCase,
                    topic: data.topic,
                    date: dateFormatter.string(from: data.date)
                )
            }

        case let .deleteItem(index):
            state.favorites.remove(at: index)

        case .screenClosed:
            state.presentedScreen = .none

        case let .selectItem(item):
            let viewModel = FavoriteViewModel(state: .initial(with: item))
            state.presentedScreen = .favoritePost(viewModel)
        }
    }
}

struct FavoriteData {
    let id: String
    let useCase: UseCase
    let topic: String
    let text: AttributedString
    let date: Date

    init(
        id: String = UUID().uuidString,
        useCase: UseCase,
        topic: String,
        text: AttributedString,
        date: Date
    ) {
        self.id = id
        self.useCase = useCase
        self.topic = topic
        self.text = text
        self.date = date
    }
}
