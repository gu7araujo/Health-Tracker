//
//  LocalizedStringResource+Intents.swift
//  HealthTracker
//

import Foundation

extension LocalizedStringResource {
    /// This string resolved now, in the app's language, wrapped so any process shows it verbatim.
    /// A plain resource is a key that Siri and Shortcuts look up in their own process and language, which
    /// can differ from the app's (the iOS 27 simulator's Shortcuts runner reads no preferences and falls
    /// back to English), so dialogs and prompts an intent sends at run time carry text, not keys.
    nonisolated var resolvedInApp: LocalizedStringResource {
        "\(String(localized: self))"
    }
}
