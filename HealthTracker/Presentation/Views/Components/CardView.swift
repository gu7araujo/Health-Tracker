//
//  CardView.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

/// A reusable card component with optional glass effect and tap action.
struct CardView<Content: View>: View {
    @ViewBuilder var content: Content
    @Binding var backgroundColor: Color?

    private let internalPadding: EdgeInsets
    private let applyGlassEffect: Bool
    private let action: (() -> Void)?

    init(
        internalPadding: EdgeInsets? = nil,
        applyGlassEffect: Bool = true,
        backgroundColor: Binding<Color?> = .constant(nil),
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.internalPadding = internalPadding ?? EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        self.action = action
        self.applyGlassEffect = applyGlassEffect
        _backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        if let action {
            Button(action: action, label: { card })
                .contentShape(.rect(cornerRadius: 16))
                .buttonStyle(.plain)
        } else {
            card
        }
    }

    @ViewBuilder
    private var card: some View {
        if applyGlassEffect {
            content
                .padding(internalPadding)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
                .background(backgroundColor)
        } else {
            content
                .padding(internalPadding)
                .background(backgroundColor)
                .clipShape(.rect(cornerRadius: 16))
        }
    }
}
