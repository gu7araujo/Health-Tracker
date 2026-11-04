//
//  IntentUseCaseFactory.swift
//  HealthTracker
//

import Foundation

extension Notification.Name {
    /// Posted on the main actor after an App Intent (or its undo) writes the store, so an open `MainView` reloads.
    static let healthDataDidChange = Notification.Name("healthDataDidChange")
}

/// Builds the live use cases App Intents run against.
/// Intents can't take injected dependencies, so their testable logic receives these as parameters instead.
enum IntentUseCaseFactory {
    static func makeUpdateDayDataUseCase() -> UpdateDayDataUseCase {
        UpdateDayDataUseCase(
            repository: UITestingSupport.makeRepository(),
            logger: LoggerFactory.domainLogger(category: "Data.Update")
        )
    }

    static func makeLoadDayDataUseCase() -> LoadDayDataUseCase {
        LoadDayDataUseCase(
            repository: UITestingSupport.makeRepository(),
            logger: LoggerFactory.domainLogger(category: "Data.Load")
        )
    }

    /// Cancels today's reminders after a log, as `MainViewModel.persistChanges()` does.
    static func cancelTodaysNotifications() async {
        let useCase = CancelNotificationsUseCase(
            // The intents' composition root, like `MainViewModel`'s convenience init.
            // swiftlint:disable:next presentation_no_data_layer
            notificationService: NotificationService(),
            logger: LoggerFactory.domainLogger(category: "Notifications.Cancel")
        )
        do {
            try await useCase.execute()
        } catch {
            LoggerFactory.presentationLogger(category: "Intents")
                .error("Failed to cancel notifications: \(error.localizedDescription)")
        }
    }
}

extension UpdateDayDataUseCase {
    /// The write path for every intent and undo: applies the change, then tells an open `MainView` to reload
    /// so its stale in-memory copy can't overwrite this write on its next save. A no-op change posts nothing.
    @discardableResult
    func executeAndNotify(for date: Date, _ change: (inout DayData) -> Void) -> DayDataChange {
        let result = execute(for: date, change)
        if result.after != result.before {
            NotificationCenter.default.post(name: .healthDataDidChange, object: nil)
        }
        return result
    }

    /// Registers `change` as the intent's undo, run through `executeAndNotify` when the system undoes.
    /// `UndoManager` doesn't retain its target, so the undo manager is the target and the handler keeps this
    /// use case alive: the intent's own reference is gone once `perform()` returns.
    @MainActor
    func registerUndo(on undoManager: UndoManager?, for date: Date, _ change: @escaping (inout DayData) -> Void) {
        guard let undoManager else { return }
        undoManager.registerUndo(withTarget: undoManager) { _ in self.executeAndNotify(for: date, change) }
    }
}
