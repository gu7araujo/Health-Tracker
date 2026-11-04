//
//  ParameterSummary+Testing.swift
//  HealthTrackerTests
//

import AppIntents

/// What the Shortcuts editor shows for an intent's `parameterSummary`. AppIntents exposes none of
/// it publicly, so these read `IntentParameterSummary`'s stored properties by reflection; a nil
/// result means the framework renamed them, and the test fails rather than passing vacuously.
extension ParameterSummary {
    /// The sentence's localization key, with `${parameterN}` where each bound parameter goes.
    var sentenceFormat: String? {
        Mirror(reflecting: self).descendant("string", "some", "formatString") as? String
    }

    /// The parameters bound into the sentence, in order.
    func sentenceParameters<Intent>(of _: Intent.Type) -> [PartialKeyPath<Intent>]? {
        Mirror(reflecting: self).descendant("string", "some", "keyPaths") as? [PartialKeyPath<Intent>]
    }

    /// The parameters listed under the sentence, in order.
    func listedParameters<Intent>(of _: Intent.Type) -> [PartialKeyPath<Intent>]? {
        Mirror(reflecting: self).descendant("additionalParameterKeyPaths") as? [PartialKeyPath<Intent>]
    }
}
