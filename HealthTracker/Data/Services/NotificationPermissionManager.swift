//
//  NotificationPermissionManager.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 02/28/26.
//

import Foundation

/// Actor responsible for managing first-launch notification permission request.
///
/// This actor coordinates the permission request flow that happens once on app first launch.
/// It uses UserDefaults to track whether permission has been requested before, ensuring
/// the request only happens on the first app launch (following iOS best practices).
///
/// The actor ensures thread-safe access to UserDefaults and gracefully handles permission
/// denial and errors without crashing the app (NOTIF-03 requirement).
actor NotificationPermissionManager {
    // MARK: - Constants

    /// UserDefaults key for tracking if notification permission has been requested
    private static let hasRequestedKey = "hasRequestedNotificationPermission"

    // MARK: - Public Methods

    /// Requests notification permission on first launch only.
    ///
    /// This method checks UserDefaults to see if permission has been requested before.
    /// If not, it creates a NotificationService and RequestNotificationPermissionUseCase
    /// to handle the permission request. The result (granted or denied) is logged but
    /// the app continues normally in either case.
    ///
    /// Permission denial or errors are handled gracefully - they are logged but do NOT
    /// crash the app. This satisfies NOTIF-03 (graceful degradation requirement).
    ///
    /// After the request (regardless of result), this method sets the UserDefaults flag
    /// to prevent future permission requests.
    @MainActor
    static func requestIfFirstLaunch() async {
        // Check if we've already requested permission
        let hasRequested = UserDefaults.standard.bool(forKey: hasRequestedKey)

        if hasRequested {
            // Permission already requested in a previous launch, skip
            return
        }

        // First launch - request notification permission
        let notificationService = NotificationService()
        let useCase = RequestNotificationPermissionUseCase(notificationService: notificationService)

        do {
            let granted = try await useCase.execute()
            print("[NotificationPermissionManager] Notification permission: \(granted ? "granted" : "denied")")

            // Set delegate for future notification handling (Phase 2 will implement actual delegate)
            notificationService.setDelegate(nil)
        } catch {
            // Log error but DON'T crash - graceful degradation per NOTIF-03
            print("[NotificationPermissionManager] Failed to request notification permission: \(error)")
        }

        // Mark as requested regardless of result (granted, denied, or error)
        // This prevents repeated permission dialogs on subsequent launches
        UserDefaults.standard.set(true, forKey: hasRequestedKey)
    }
}
