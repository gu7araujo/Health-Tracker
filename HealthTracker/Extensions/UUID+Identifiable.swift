//
//  UUID+Identifiable.swift
//  HealthTracker
//

import Foundation

extension UUID: @retroactive Identifiable {
    public var id: UUID {
        self
    }
}
