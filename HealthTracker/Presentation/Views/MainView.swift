//
//  MainView.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

struct MainView: View {
    @State private var viewModel = MainViewModel()
    @State private var addingSection: HealthSection?
    @State private var editingMealId: UUID?
    @State private var editingWorkoutId: UUID?
    @State private var showAddSelectionAlert = false

    var body: some View {
        NavigationStack {
            List {
                datePickerSection
                MealsSectionView(
                    meals: viewModel.currentDayData?.meals ?? [],
                    editingMealId: $editingMealId,
                    onDelete: { viewModel.deleteMeal(withId: $0) }
                )
                WaterSectionView(
                    water: viewModel.currentDayData?.water ?? 0,
                    waterIntake: viewModel.waterIntake,
                    onUpdateWater: { viewModel.updateWater($0) }
                )
                WorkoutsSectionView(
                    workouts: viewModel.currentDayData?.workouts ?? [],
                    editingWorkoutId: $editingWorkoutId,
                    onDelete: { viewModel.deleteWorkout(withId: $0) }
                )
                MoodSectionView(
                    currentMood: viewModel.currentDayData?.mood,
                    onUpdateMood: { viewModel.updateMood($0) }
                )
                DayStatusExplanationView(
                    explanation: viewModel.currentDayExplanation,
                    status: viewModel.currentDayStatus
                )
            }
            .navigationTitle(String(localized: "app_title"))
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "add_button"), systemImage: "plus") {
                        showAddSelectionAlert = true
                    }
                }
            }
            .alert(String(localized: "add_record_title"), isPresented: $showAddSelectionAlert) {
                Button(String(localized: "meal_option")) {
                    addingSection = .meal
                }
                Button(String(localized: "workout_option")) {
                    addingSection = .workout
                }
                Button(String(localized: "cancel_button"), role: .cancel) {}
            } message: {
                Text(String(localized: "add_record_message"))
            }
        }
        .onFirstAppear {
            viewModel.loadData()
        }
        .sheet(item: $addingSection) { section in
            AddEditModal(
                viewModel: viewModel,
                section: section,
                mealId: nil,
                workoutId: nil
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingMealId) { mealId in
            AddEditModal(
                viewModel: viewModel,
                section: .meal,
                mealId: mealId,
                workoutId: nil
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingWorkoutId) { workoutId in
            AddEditModal(
                viewModel: viewModel,
                section: .workout,
                mealId: nil,
                workoutId: workoutId
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Date Picker Section

    private var datePickerSection: some View {
        CalendarStrip(selectedDate: $viewModel.selectedDate, days: viewModel.days)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 30, leading: 0, bottom: 30, trailing: 0))
    }
}

// MARK: - Meals Section

private struct MealsSectionView: View {
    let meals: [Meal]
    @Binding var editingMealId: UUID?
    let onDelete: (UUID) -> Void

    var body: some View {
        Group {
            Text(String(localized: "meals_section"))
                .font(.title2)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            if !meals.isEmpty {
                ForEach(meals) { meal in
                    CardView(
                        internalPadding: .init(
                            top: 15,
                            leading: 15,
                            bottom: 15,
                            trailing: 15
                        ),
                        applyGlassEffect: false,
                        backgroundColor: .constant(
                            Color(
                                .secondarySystemBackground
                            )
                        )
                    ) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(meal.description)
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                Text(String(localized: "quantity_label", defaultValue: "Quantity: \(meal.quantity.localizedName)"))
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                Text(String(localized: "satisfaction_label", defaultValue: "Satisfied: \(meal.satisfaction.localizedName)"))
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(meal.id)
                        } label: {
                            Label(String(localized: "delete_action"), systemImage: "trash")
                        }
                        Button {
                            editingMealId = meal.id
                        } label: {
                            Label(String(localized: "edit_action"), systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20))
                }
            } else {
                EmptyListRow()
            }
        }
    }
}

// MARK: - Water Section

private struct WaterSectionView: View {
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
                internalPadding: .init(
                    top: 15,
                    leading: 15,
                    bottom: 15,
                    trailing: 15
                ),
                applyGlassEffect: false,
                backgroundColor: .constant(
                    Color(
                        .secondarySystemBackground
                    )
                )
            ) {
                VStack {
                    (Text(water, format: .number.precision(.fractionLength(1)))
                        + Text(" L"))
                        .font(.title)
                        .bold()
                    Slider(
                        value: Binding(
                            get: { waterIntake },
                            set: { onUpdateWater($0) }
                        ),
                        in: 0 ... 5,
                        step: 0.1
                    ) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text("0 L")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("5 L")
                            .font(.caption)
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 15, trailing: 20))
        }
    }
}

// MARK: - Workouts Section

private struct WorkoutsSectionView: View {
    let workouts: [Workout]
    @Binding var editingWorkoutId: UUID?
    let onDelete: (UUID) -> Void

    var body: some View {
        Group {
            Text(String(localized: "workouts_section"))
                .font(.title2)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            if !workouts.isEmpty {
                ForEach(workouts) { workout in
                    CardView(
                        internalPadding: .init(
                            top: 15,
                            leading: 15,
                            bottom: 15,
                            trailing: 15
                        ),
                        applyGlassEffect: false,
                        backgroundColor: .constant(
                            Color(
                                .secondarySystemBackground
                            )
                        )
                    ) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(workout.description)
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                Text("Tempo: \(workout.duration.localizedName)")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(workout.id)
                        } label: {
                            Label(String(localized: "delete_action"), systemImage: "trash")
                        }
                        Button {
                            editingWorkoutId = workout.id
                        } label: {
                            Label(String(localized: "edit_action"), systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20))
                }
            } else {
                EmptyListRow()
            }
        }
    }
}

// MARK: - Mood Section

private struct MoodSectionView: View {
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
                internalPadding: .init(
                    top: 15,
                    leading: 15,
                    bottom: 15,
                    trailing: 15
                ),
                applyGlassEffect: false,
                backgroundColor: .constant(
                    Color(
                        .secondarySystemBackground
                    )
                )
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
            applyGlassEffect: !isSelected,
            backgroundColor: .constant(isSelected ? mood.color : nil)
        ) {
            onUpdateMood(mood)
        } content: {
            HStack {
                Spacer()
                VStack {
                    Text(mood.emoji)
                        .font(.title)
                    Text(mood.localizedName)
                        .font(.caption)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Day Status Explanation Section

private struct DayStatusExplanationView: View {
    let explanation: String?
    let status: DayStatus

    var body: some View {
        Group {
            if let explanation, status != .noData, status != .incomplete {
                Section {
                    Text(explanation)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .listRowBackground(Color.secondary.opacity(0.2))
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }
    }
}

// MARK: - Empty List Row

private struct EmptyListRow: View {
    var body: some View {
        HStack {
            Spacer()
            Text(String(localized: "empty_list"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
    }
}

// MARK: - UUID Identifiable Extension

extension UUID: @retroactive Identifiable {
    public var id: UUID {
        self
    }
}
