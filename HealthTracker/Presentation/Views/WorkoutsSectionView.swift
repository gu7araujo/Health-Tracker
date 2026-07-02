//
//  WorkoutsSectionView.swift
//  HealthTracker
//

import SwiftUI

struct WorkoutsSectionView: View {
    let workouts: [Workout]
    @Binding var editingWorkoutId: UUID?
    let onDelete: (UUID) -> Void
    let onMove: (IndexSet, Int) -> Void

    var body: some View {
        Group {
            Text(String(localized: "workouts_section"))
                .font(.title2)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            if !workouts.isEmpty {
                ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                    CardView(
                        internalPadding: .init(top: 15, leading: 15, bottom: 15, trailing: 15),
                        applyGlassEffect: false,
                        backgroundColor: .constant(Color(.secondarySystemBackground))
                    ) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(workout.description)
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                Text(String(
                                    format: String(localized: "workout_time_label"),
                                    workout.duration.localizedName
                                ))
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(AccessibilityID.workoutCard(index))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(workout.id)
                        } label: {
                            Label(String(localized: "delete_action"), systemImage: "trash")
                        }
                        .accessibilityIdentifier(AccessibilityID.workoutDeleteButton(index))
                        Button {
                            editingWorkoutId = workout.id
                        } label: {
                            Label(String(localized: "edit_action"), systemImage: "pencil")
                        }
                        .tint(.blue)
                        .accessibilityIdentifier(AccessibilityID.workoutEditButton(index))
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                }
                .onMove(perform: onMove)
            } else {
                EmptyListRow()
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(AccessibilityID.workoutsEmptyState)
            }
        }
    }
}
