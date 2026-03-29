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
                .padding(.bottom, 8)
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
                Button(String(localized: "meal_option")) { addingSection = .meal }
                Button(String(localized: "workout_option")) { addingSection = .workout }
                Button(String(localized: "cancel_button"), role: .cancel) {}
            } message: {
                Text(String(localized: "add_record_message"))
            }
        }
        .onFirstAppear { viewModel.loadData() }
        .sheet(item: $addingSection) { section in
            AddEditModal(viewModel: viewModel, section: section, mealId: nil, workoutId: nil)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingMealId) { mealId in
            AddEditModal(viewModel: viewModel, section: .meal, mealId: mealId, workoutId: nil)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingWorkoutId) { workoutId in
            AddEditModal(viewModel: viewModel, section: .workout, mealId: nil, workoutId: workoutId)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Date Picker Section

    private var datePickerSection: some View {
        VStack {
            CalendarStrip(selectedDate: $viewModel.selectedDate, days: viewModel.days)
            if let explanation = viewModel.currentDayExplanation,
               viewModel.currentDayStatus != .noData,
               viewModel.currentDayStatus != .incomplete,
               viewModel.currentDayStatus != .optimal
            {
                Text(explanation)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 28)
                    .transition(.opacity)
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 15, leading: 0, bottom: 23, trailing: 0))
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentDayStatus)
    }
}
