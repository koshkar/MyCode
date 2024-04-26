//
//  FavoriteViewModel.swift
//
//
//  Created by Кирилл Кошкарёв on 14.02.2024.
//

import SwiftUI

final class FavoriteViewModel: ViewModel {

    @Published var state: FavoriteState

    private var savedText: AttributedString

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM HH:mm"
        return dateFormatter
    }()

    init(state: FavoriteState) {
        self.state = state
        savedText = state.text
    }

    func handle(action: FavoriteAction) {
        switch action {
        case .firstAppear:
            loadText()

        case let .textChanged(text):
            state.text = text

        case .copy:
            UIPasteboard.general.string = String(state.text.characters)

        case .editingButtonPressed:
            state.isEditing = true

        case .acceptButtonPressed:
            replaceText()
            state.isEditing = false

        case .disappear:
            state.isEditing = false
        }
    }
}

private extension FavoriteViewModel {

    func loadText() {
        guard let data = SharedEntities.favorites.first(where: { $0.id == state.item.id }) else {
            return
        }

        state.text = data.text
    }

    func replaceText() {
        guard let dataIndex = SharedEntities.favorites.firstIndex(where: { $0.id == state.item.id }),
              let data = SharedEntities.favorites[safe: dataIndex]
        else {
            return
        }

        let newData = FavoriteData(
            id: data.id,
            useCase: data.useCase,
            topic: data.topic,
            text: state.text,
            date: data.date
        )
        SharedEntities.favorites.replaceSubrange(dataIndex ... dataIndex, with: [newData])
    }
}
