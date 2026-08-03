//
//  MockMigrationFlagStore.swift
//  HealthTrackerTests
//
//  Created by Gustavo Araujo Santos on 08/03/26.
//

import Foundation
@testable import HealthTracker

/// In-memory `MigrationFlagStore` for testing `DataMigration` without touching real `UserDefaults`.
/// Seed completed flags via `init(done:)`, then assert with `isDone(_:)` after running a migration.
final class MockMigrationFlagStore: MigrationFlagStore {
    private var doneKeys: Set<String>
    private(set) var clearLegacyStoreCalled = false

    init(done: Set<String> = []) {
        doneKeys = done
    }

    func isDone(_ key: String) -> Bool {
        doneKeys.contains(key)
    }

    func markDone(_ key: String) {
        doneKeys.insert(key)
    }

    func clearLegacyStore() {
        clearLegacyStoreCalled = true
    }
}
