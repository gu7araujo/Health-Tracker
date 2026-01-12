//
//  AddEditModal.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

struct AddEditModal: View {

    @Environment(\.dismiss) private var dismiss

    private let viewModel: MainViewModel
    private let section: HealthSection
    private let mealId: UUID?
    private let workoutId: UUID?

    @State private var text: String = ""
    @State private var selectedQuantity: Meal.Quantity = .small
    @State private var selectedSatisfaction: Meal.Satisfaction = .fifty
    @State private var selectedDuration: Workout.Duration = .thirtyMin

    private var isEditing: Bool {
        mealId != nil || workoutId != nil
    }

    init(
        viewModel: MainViewModel,
        section: HealthSection,
        mealId: UUID?,
        workoutId: UUID?
    ) {
        self.viewModel = viewModel
        self.section = section
        self.mealId = mealId
        self.workoutId = workoutId
    }

    var body: some View {
        List {
            TextEditor(text: $text)
                .frame(height: 40)

            if section == .meal {
                mealFields
            } else {
                workoutFields
            }

            Button("Salvar") {
                saveEntry()
                dismiss()
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Meal Fields

    private var mealFields: some View {
        Group {
            Picker("Quantidade", selection: $selectedQuantity) {
                ForEach(Meal.Quantity.allCases, id: \.self) { quantity in
                    Text(quantity.localizedName).tag(quantity)
                }
            }

            Picker("Satisfeito(a)", selection: $selectedSatisfaction) {
                ForEach(Meal.Satisfaction.allCases, id: \.self) { satisfaction in
                    Text(satisfaction.localizedName).tag(satisfaction)
                }
            }
        }
    }

    // MARK: - Workout Fields

    private var workoutFields: some View {
        Picker("Tempo", selection: $selectedDuration) {
            ForEach(Workout.Duration.allCases, id: \.self) { duration in
                Text(duration.localizedName).tag(duration)
            }
        }
    }

    // MARK: - Data Operations

    private func loadExistingData() {
        if section == .meal, let mealId, let meal = viewModel.meal(withId: mealId) {
            text = meal.description
            selectedQuantity = meal.quantity
            selectedSatisfaction = meal.satisfaction
        } else if section == .workout, let workoutId, let workout = viewModel.workout(withId: workoutId) {
            text = workout.description
            selectedDuration = workout.duration
        }
    }

    private func saveEntry() {
        switch section {
        case .meal:
            saveMeal()
        case .workout:
            saveWorkout()
        }
    }

    private func saveMeal() {
        if let mealId, var existingMeal = viewModel.meal(withId: mealId) {
            // Update existing meal
            existingMeal.description = text
            existingMeal.quantity = selectedQuantity
            existingMeal.satisfaction = selectedSatisfaction
            viewModel.updateMeal(existingMeal)
        } else {
            // Add new meal
            let meal = Meal(
                description: text,
                quantity: selectedQuantity,
                satisfaction: selectedSatisfaction
            )
            viewModel.addMeal(meal)
        }
    }

    private func saveWorkout() {
        if let workoutId, var existingWorkout = viewModel.workout(withId: workoutId) {
            // Update existing workout
            existingWorkout.description = text
            existingWorkout.duration = selectedDuration
            viewModel.updateWorkout(existingWorkout)
        } else {
            // Add new workout
            let workout = Workout(
                description: text,
                duration: selectedDuration
            )
            viewModel.addWorkout(workout)
        }
    }
}
