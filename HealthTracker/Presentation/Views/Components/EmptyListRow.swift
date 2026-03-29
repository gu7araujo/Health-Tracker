//
//  EmptyListRow.swift
//  HealthTracker
//

import SwiftUI

struct EmptyListRow: View {
    var body: some View {
        HStack {
            Spacer()
            Text(String(localized: "empty_list"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
    }
}
