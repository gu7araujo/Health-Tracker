//
//  View+Extensions.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

// MARK: - First Appear Modifier

extension View {
    /// Performs an action only on the first appearance of the view.
    /// Useful for one-time initialization that shouldn't repeat on view reappearance.
    /// - Parameter action: The action to perform on first appearance.
    /// - Returns: A view with the first-appear modifier applied.
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }
}

/// A view modifier that tracks first appearance and executes an action only once.
struct FirstAppearModifier: ViewModifier {
    @State private var hasAppeared = false
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasAppeared {
                    hasAppeared = true
                    action()
                }
            }
    }
}
