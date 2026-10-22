//
//  DataMigrationTests+FileMigration.swift
//  HealthTrackerTests
//

@testable import HealthTracker

/// The three file migrations, as `@Test` arguments. Kept nonisolated so the macro can build the
/// argument list; the main-actor `DataMigration` keys are read inside the test body.
enum FileMigration: CaseIterable {
    case duration, mealItems, intensity

    @MainActor var key: String {
        switch self {
        case .duration: DataMigration.durationMigrationKey
        case .mealItems: DataMigration.mealItemsMigrationKey
        case .intensity: DataMigration.workoutIntensityMigrationKey
        }
    }
}
