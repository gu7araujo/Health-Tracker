//
//  MainView.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

struct MainView: View {

    @State private var viewModel = MainViewModel()
    @State private var isAddModalPresented = false
    @State private var modalSection: HealthSection = .meal
    @State private var editingMealId: UUID?
    @State private var editingWorkoutId: UUID?

    var body: some View {
        NavigationStack {
            List {
                datePickerSection
                mealsSection
                waterSection
                workoutsSection
                moodSection
            }
            .navigationTitle("Monitore sua saúde")
            .listStyle(.plain)
            .scrollIndicators(.hidden)
        }
        .onFirstAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $isAddModalPresented) {
            AddEditModal(
                viewModel: viewModel,
                section: modalSection,
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
        CalendarStrip(selectedDate: $viewModel.selectedDate)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 30, leading: 0, bottom: 30, trailing: 0))
    }

    // MARK: - Meals Section

    private var mealsSection: some View {
        Group {
            HeaderListView(title: "Refeições", icon: "plus") {
                modalSection = .meal
                isAddModalPresented = true
            }

            if let meals = viewModel.currentDayData?.meals, !meals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                            CardListView(isFirst: index == 0, isUnique: meals.count == 1) {
                                VStack(alignment: .leading) {
                                    Text(meal.description)
                                        .padding(.bottom, 5)
                                    Text("Quantidade: \(meal.quantity.localizedName)")
                                        .font(.subheadline)
                                    Text("Satisfeito(a): \(meal.satisfaction.localizedName)")
                                        .font(.subheadline)
                                }
                            }
                            .onTapGesture(count: 2) {
                                editingMealId = meal.id
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0))
            } else {
                emptyListRow
            }
        }
    }

    // MARK: - Water Section

    private var waterSection: some View {
        Group {
            Text("Água")
                .font(.title3)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            CardView {
                HStack {
                    Spacer()
                    VStack {
                        Text(String(format: "%.1f L", viewModel.currentDayData?.water ?? 0))
                            .font(.title2)
                        Stepper(
                            value: Binding(
                                get: { viewModel.waterIntake },
                                set: { viewModel.updateWater($0) }
                            ),
                            in: 0...10,
                            step: 0.1,
                            label: { }
                        )
                    }
                    Spacer()
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 15, trailing: 20))
        }
    }

    // MARK: - Workouts Section

    private var workoutsSection: some View {
        Group {
            HeaderListView(title: "Exercícios", icon: "plus") {
                modalSection = .workout
                isAddModalPresented = true
            }

            if let workouts = viewModel.currentDayData?.workouts, !workouts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                            CardListView(isFirst: index == 0, isUnique: workouts.count == 1) {
                                VStack(alignment: .leading) {
                                    Text(workout.description)
                                        .padding(.bottom, 5)
                                    Text("Tempo: \(workout.duration.localizedName)")
                                        .font(.subheadline)
                                }
                            }
                            .onTapGesture(count: 2) {
                                editingWorkoutId = workout.id
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0))
            } else {
                emptyListRow
            }
        }
    }

    // MARK: - Mood Section

    private var moodSection: some View {
        Group {
            Text("Humor")
                .font(.title3)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            CardView(internalPadding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
                VStack(alignment: .leading) {
                    Text("Como está o seu humor hoje?")
                        .padding(.bottom, 15)
                        .font(.headline)

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

    // MARK: - Helper Views

    private var emptyListRow: some View {
        HStack {
            Spacer()
            Text("Lista vazia!")
            Spacer()
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
    }

    private func moodButton(for mood: Mood) -> some View {
        let isSelected = viewModel.currentDayData?.mood == mood

        return CardView(
            applyGlassEffect: !isSelected,
            backgroundColor: .constant(isSelected ? mood.color : nil)
        ) {
            viewModel.updateMood(mood)
        } content: {
            HStack {
                Spacer()
                VStack {
                    Text(mood.emoji)
                    Text(mood.localizedName)
                }
                Spacer()
            }
        }
    }
}

// MARK: - UUID Identifiable Extension

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
