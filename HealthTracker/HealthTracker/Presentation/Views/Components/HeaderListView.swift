//
//  HeaderListView.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

/// A section header with title and action button.
struct HeaderListView: View {

    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .bold()
            Spacer()
            Button("", systemImage: icon, action: action)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
    }
}
