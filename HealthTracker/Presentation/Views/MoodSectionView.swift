//
//  MoodSectionView.swift
//  HealthTracker
//

import SwiftUI

struct MoodSectionView: View {
    let currentMood: Mood?
    let onUpdateMood: (Mood) -> Void

    var body: some View {
        Group {
            Text(String(localized: "mood_section"))
                .font(.title2)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            CardView(
                internalPadding: .init(top: 15, leading: 15, bottom: 15, trailing: 15),
                applyGlassEffect: false,
                backgroundColor: .constant(Color(.secondarySystemBackground))
            ) {
                VStack(alignment: .leading) {
                    Text(String(localized: "mood_prompt"))
                        .font(.headline)
                        .padding(.bottom, 15)
                    HStack {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            moodButton(for: mood)
                        }
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        }
    }

    private func moodButton(for mood: Mood) -> some View {
        let isSelected = currentMood == mood
        return CardView(
            applyGlassEffect: true,
            glassTint: isSelected ? mood.color : nil
        ) {
            onUpdateMood(mood)
        } content: {
            HStack {
                Spacer()
                VStack {
                    Text(mood.emoji).font(.title)
                    Text(mood.localizedName).font(.caption)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AccessibilityID.moodButton(mood))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
