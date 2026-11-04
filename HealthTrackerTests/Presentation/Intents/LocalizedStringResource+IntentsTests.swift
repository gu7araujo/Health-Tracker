//
//  LocalizedStringResource+IntentsTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

extension LocalizedStringResource {
    /// How a host process in a language other than the app's reads this resource,
    /// as the Shortcuts runner does when it falls back to English on a Portuguese device.
    var readByForeignHost: String {
        var copy = self
        let appLanguage = Bundle.main.preferredLocalizations.first ?? "en"
        copy.locale = Locale(identifier: appLanguage.hasPrefix("en") ? "pt_BR" : "en")
        return String(localized: copy)
    }
}

struct LocalizedStringResourceIntentsTests {
    @Test func resolvedInApp_readsInTheAppsLanguageInAnyHost() {
        let resource: LocalizedStringResource = "intent_log_mood_dialog \("X")"

        #expect(resource.resolvedInApp.readByForeignHost == String(localized: resource))
        #expect(resource.readByForeignHost != String(localized: resource))
    }

    @Test func resolvedInApp_keepsPercentSignsVerbatim() {
        let resource: LocalizedStringResource = "intent_add_meal_dialog \("Rice 100%")"

        #expect(resource.resolvedInApp.readByForeignHost == String(localized: resource))
    }
}
