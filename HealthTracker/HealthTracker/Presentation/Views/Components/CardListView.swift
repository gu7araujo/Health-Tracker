//
//  CardListView.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

/// A card designed for horizontal scrolling lists with dynamic sizing.
struct CardListView<Content: View>: View {

    @ViewBuilder var content: Content

    let isFirst: Bool
    let isUnique: Bool

    init(
        isFirst: Bool = false,
        isUnique: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.isFirst = isFirst
        self.isUnique = isUnique
        self.content = content()
    }

    var body: some View {
        CardView {
            HStack {
                content
                Spacer()
            }
        }
        .if(isUnique) { view in
            view.frame(width: UIScreen.main.bounds.width - 40)
        }
        .if(!isUnique) { view in
            view.frame(maxWidth: UIScreen.main.bounds.width - 40)
        }
        .padding(.leading, isFirst ? 20 : 0)
    }
}
