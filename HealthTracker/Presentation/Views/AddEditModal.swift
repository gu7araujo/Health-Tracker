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
    @State private var mealItems: [String] = [""]
    @State private var selectedQuantity: Meal.Quantity = .small
    @State private var selectedSatisfaction: Meal.Satisfaction = .fifty
    @State private var satisfactionWasManuallySet: Bool = false
    @State private var selectedDuration: Date = {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = 0
        components.minute = 30
        return calendar.date(from: components) ?? Date()
    }()

    @State private var selectedIntensity: Workout.Intensity = .medium

    private let maxMealItems = 5

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

    private var navigationTitle: String {
        switch (section, isEditing) {
        case (.meal, false): String(localized: "add_meal_title")
        case (.meal, true): String(localized: "edit_meal_title")
        case (.workout, false): String(localized: "add_workout_title")
        case (.workout, true): String(localized: "edit_workout_title")
        }
    }

    private var sectionIcon: String {
        section == .meal ? "fork.knife" : "figure.run"
    }

    private var sectionIconColor: Color {
        section == .meal ? .orange : .green
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack {
                        Image(systemName: sectionIcon)
                            .font(.system(size: 40))
                            .foregroundStyle(sectionIconColor)
                            .frame(width: 80, height: 80)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                Section {
                    if section == .meal {
                        mealDescriptionFields
                    } else {
                        TextField(
                            String(localized: "workout_description_placeholder"),
                            text: $text
                        )
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier(AccessibilityID.workoutDescriptionField)
                    }
                }

                Section {
                    if section == .meal {
                        mealFields
                    } else {
                        workoutFields
                    }
                }
            }
            .listStyle(.insetGrouped)
            .accessibilityIdentifier(AccessibilityID.modalList)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "close_button"), systemImage: "xmark") {
                        dismiss()
                    }
                    .accessibilityIdentifier(AccessibilityID.modalCancelButton)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save_button"), systemImage: "checkmark") {
                        saveEntry()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(.systemBlue))
                    .accessibilityIdentifier(AccessibilityID.modalSaveButton)
                }
            }
            .onAppear {
                loadExistingData()
            }
        }
    }

    // MARK: - Meal Fields

    private var satisfactionBinding: Binding<Meal.Satisfaction> {
        Binding(
            get: { selectedSatisfaction },
            set: { newValue in
                selectedSatisfaction = newValue
                satisfactionWasManuallySet = true
            }
        )
    }

    private var mealDescriptionFields: some View {
        Group {
            ForEach(mealItems.indices, id: \.self) { index in
                TextField(
                    String(localized: "meal_description_placeholder"),
                    text: Binding(
                        get: { mealItems[index] },
                        set: { mealItems[index] = $0 }
                    )
                )
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(AccessibilityID.mealItemField(index))
                .overlay(alignment: .trailing) {
                    if index > 0 {
                        Button {
                            mealItems.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(String(localized: "delete_action"))
                        .accessibilityIdentifier(AccessibilityID.mealItemDeleteButton(index))
                    }
                }
            }

            if mealItems.count < maxMealItems {
                Button {
                    mealItems.append("")
                } label: {
                    Label(String(localized: "add_meal_item_button"), systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier(AccessibilityID.addMealItemButton)
            }
        }
    }

    private var mealFields: some View {
        Group {
            Picker(String(localized: "quantity_picker_label"), selection: $selectedQuantity) {
                ForEach(Meal.Quantity.allCases, id: \.self) { quantity in
                    Text(quantity.localizedName).tag(quantity)
                }
            }
            .accessibilityIdentifier(AccessibilityID.quantityPicker)
            .onChange(of: selectedQuantity) { _, newQuantity in
                if !satisfactionWasManuallySet {
                    selectedSatisfaction = newQuantity.defaultSatisfaction
                }
            }

            Picker(String(localized: "satisfaction_picker_label"), selection: satisfactionBinding) {
                ForEach(Meal.Satisfaction.allCases, id: \.self) { satisfaction in
                    Text(satisfaction.localizedName).tag(satisfaction)
                }
            }
            .accessibilityIdentifier(AccessibilityID.satisfactionPicker)
        }
    }

    // MARK: - Workout Fields

    private var workoutFields: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "time_label"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                DatePicker(
                    String(localized: "duration_picker_label"),
                    selection: $selectedDuration,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(AccessibilityID.durationPicker)
            }

            Picker(String(localized: "intensity_picker_label"), selection: $selectedIntensity) {
                ForEach(Workout.Intensity.allCases, id: \.self) { intensity in
                    Text(intensity.localizedName).tag(intensity)
                }
            }
            .accessibilityIdentifier(AccessibilityID.intensityPicker)
        }
    }
}

// MARK: - Data Operations

private extension AddEditModal {
    func loadExistingData() {
        if section == .meal, let mealId, let meal = viewModel.meal(withId: mealId) {
            mealItems = meal.items
            selectedQuantity = meal.quantity
            selectedSatisfaction = meal.satisfaction
            satisfactionWasManuallySet = false
        } else if section == .workout, let workoutId, let workout = viewModel.workout(withId: workoutId) {
            text = workout.description
            // Convert minutes to Date
            let calendar = Calendar.current
            var components = DateComponents()
            components.hour = workout.duration.minutes / 60
            components.minute = workout.duration.minutes % 60
            selectedDuration = calendar.date(from: components) ?? Date()
            selectedIntensity = workout.intensity
        }
    }

    func saveEntry() {
        switch section {
        case .meal:
            saveMeal()
        case .workout:
            saveWorkout()
        }
    }

    func saveMeal() {
        // Drop blank added fields; the first field is always kept, matching the
        // previous single-field behavior of not requiring non-empty text
        let itemsToSave = mealItems.enumerated()
            .filter { index, item in index == 0 || !item.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map(\.element)

        if let mealId, var existingMeal = viewModel.meal(withId: mealId) {
            // Update existing meal
            existingMeal.items = itemsToSave
            existingMeal.quantity = selectedQuantity
            existingMeal.satisfaction = selectedSatisfaction
            viewModel.updateMeal(existingMeal)
        } else {
            // Add new meal
            let meal = Meal(
                items: itemsToSave,
                quantity: selectedQuantity,
                satisfaction: selectedSatisfaction
            )
            viewModel.addMeal(meal)
        }
    }

    func saveWorkout() {
        // Extract minutes from DatePicker
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedDuration)
        let totalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let duration = Workout.Duration(minutes: max(1, totalMinutes))

        if let workoutId, var existingWorkout = viewModel.workout(withId: workoutId) {
            // Update existing workout
            existingWorkout.description = text
            existingWorkout.duration = duration
            existingWorkout.intensity = selectedIntensity
            viewModel.updateWorkout(existingWorkout)
        } else {
            // Add new workout
            let workout = Workout(
                description: text,
                duration: duration,
                intensity: selectedIntensity
            )
            viewModel.addWorkout(workout)
        }
    }
}
