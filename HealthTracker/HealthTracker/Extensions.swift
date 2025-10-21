//
//  Extensions.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/21/25.
//

import SwiftUI

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
