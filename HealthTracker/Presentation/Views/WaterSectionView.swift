//
//  WaterSectionView.swift
//  HealthTracker
//

import SwiftUI

struct WaterSectionView: View {
    let water: Double
    let waterIntake: Double
    let onUpdateWater: (Double) -> Void

    var body: some View {
        Group {
            Text(String(localized: "water_section"))
                .font(.title2)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            CardView(
                internalPadding: .init(top: 15, leading: 15, bottom: 15, trailing: 15),
                applyGlassEffect: false,
                backgroundColor: .constant(Color(.secondarySystemBackground))
            ) {
                VStack {
                    (Text(water, format: .number.precision(.fractionLength(1)))
                        + Text(String(localized: "water_unit")))
                        .font(.title)
                        .bold()
                        .accessibilityIdentifier(AccessibilityID.waterValueLabel)
                    Slider(
                        value: Binding(get: { waterIntake }, set: { onUpdateWater($0) }),
                        in: 0 ... 5,
                        step: 0.1
                    ) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text(String(localized: "water_min_label")).font(.caption)
                    } maximumValueLabel: {
                        Text(String(localized: "water_max_label")).font(.caption)
                    }
                    .accessibilityIdentifier(AccessibilityID.waterSlider)
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 15, trailing: 20))
        }
    }
}
