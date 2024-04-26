//
//  FavoriteView.swift
//
//
//  Created by Кирилл Кошкарёв on 14.02.2024.
//

import SwiftUI

struct FavoriteView<VM: ViewModel>: View
    where VM.State == FavoriteState, VM.Action == FavoriteAction
{

    @ObservedObject var viewModel: VM

    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.state.item.topic)
                .font(.system(size: 30))
                .fontWeight(.bold)
                .lineLimit(1)

            Text(viewModel.state.item.date)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)

        ScrollView {
            Group {
                if viewModel.state.isEditing {
                    let textBinding = Binding(
                        get: { viewModel.state.text },
                        set: { viewModel.handle(action: .textChanged($0)) }
                    )
                    MessageTextView(text: .editable(textBinding))
                } else {
                    MessageTextView(text: .static(viewModel.state.text))
                }
            }
            .padding(.horizontal, 16)
            HStack {
                Spacer()
                copyButton
                    .padding(.bottom, 16)
                    .padding(.trailing, 30)
            }
        }
        .navigationTitle(viewModel.state.item.useCase.navigationTitle)
        .toolbar {
            if !viewModel.state.isEditing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.handle(action: .editingButtonPressed)
                    } label: {
                        Text("favorite_edit")
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.handle(action: .acceptButtonPressed)
                    } label: {
                        Text("favorite_done")
                    }
                }
            }
        }
        .onFirstAppear {
            viewModel.handle(action: .firstAppear)
        }
        .onDisappear {
            viewModel.handle(action: .disappear)
        }
    }

    @ViewBuilder
    private var copyButton: some View {
        if viewModel.state.isCopied {
            HStack {
                Text("chat_copiedLabel_title")
                    .foregroundColor(.primaryText)
                    .font(.subheadline)

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
            .frame(alignment: .trailing)
        } else {
            Button {
                viewModel.handle(action: .copy)

                withAnimation {
                    viewModel.state.isCopied = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        viewModel.state.isCopied = false
                    }
                }
            } label: {
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 25))
                    .foregroundColor(.accentColor)
            }
        }
    }

}

// MARK: - Bindings

struct FavoriteState: Equatable {
    let item: FavoriteItem

    var text: AttributedString
    var isCopied: Bool
    var isEditing: Bool
}

enum FavoriteAction: Equatable {
    case firstAppear
    case textChanged(AttributedString)
    case copy
    case editingButtonPressed
    case acceptButtonPressed
    case disappear
}

extension FavoriteState {

    static func initial(with item: FavoriteItem) -> Self {
        Self(
            item: item,
            text: AttributedString(),
            isCopied: false,
            isEditing: false
        )
    }
}
