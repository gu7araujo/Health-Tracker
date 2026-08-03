//
//  UserNotificationCentering.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 08/03/26.
//

import Foundation
import UserNotifications

/// Narrow abstraction over `UNUserNotificationCenter` exposing only the operations
/// `NotificationService` needs. It returns constructible types (`UNAuthorizationStatus`
/// rather than the un-instantiable `UNNotificationSettings`), which lets the service be
/// unit-tested with a fake center.
///
/// Together with `NotificationService`, this file is scoped to the UserNotifications framework.
protocol UserNotificationCentering {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func authorizationStatus() async -> UNAuthorizationStatus
    func add(_ request: UNNotificationRequest) async throws
    func removeAllPendingNotificationRequests()
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

/// `UNUserNotificationCenter` already provides every requirement except a bare
/// authorization-status accessor; bridge it through `notificationSettings()`.
extension UNUserNotificationCenter: UserNotificationCentering {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }
}
