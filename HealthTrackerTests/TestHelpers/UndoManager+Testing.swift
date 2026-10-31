//
//  UndoManager+Testing.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

extension UndoManager {
    /// Runs `register` inside an explicit undo group with a use case over `repository`, then undoes it once
    /// nothing but the registration holds that use case, as when the system undoes after `perform()` returns.
    /// Unit tests have no run loop to close the automatic per-event group, so grouping is manual.
    @MainActor
    static func registerAndUndo(
        against repository: HealthDataRepositoryProtocol,
        _ register: (UndoManager, UpdateDayDataUseCase) -> Void
    ) throws {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        undoManager.beginUndoGrouping()
        weak var registered: UpdateDayDataUseCase?
        do {
            let useCase = UpdateDayDataUseCase(repository: repository, logger: MockLogger())
            registered = useCase
            register(undoManager, useCase)
        }
        undoManager.endUndoGrouping()
        // `UndoManager` doesn't retain its target, so undoing against a freed use case would crash the runner
        try #require(registered != nil, "The registered undo must keep its use case alive")
        undoManager.undo()
    }
}
