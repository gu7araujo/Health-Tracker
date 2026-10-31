//
//  AddWorkoutIntentTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct AddWorkoutIntentTests {
    // Swift Testing builds a fresh suite instance per test, so each test gets its own mock
    private let mockRepository = MockHealthDataRepository()
    private let useCase: UpdateDayDataUseCase

    init() {
        useCase = UpdateDayDataUseCase(repository: mockRepository, logger: MockLogger())
    }

    private func makeIntent(
        name: String,
        minutes: Int = 30,
        intensity: WorkoutIntensityAppEnum = .medium
    ) -> AddWorkoutIntent {
        let intent = AddWorkoutIntent()
        intent.name = name
        intent.minutes = minutes
        intent.intensity = intensity
        return intent
    }

    @Test func run_appendsTrimmedWorkoutWithDurationAndIntensity() throws {
        let intent = makeIntent(name: "  Run ", minutes: 45, intensity: .high)

        try intent.run(with: useCase, on: TestDataBuilder.fixedDate)

        let workout = try #require(mockRepository.saveDayDataCalledWith?.dayData.workouts.first)
        #expect(workout.description == "Run")
        #expect(workout.duration.minutes == 45)
        #expect(workout.intensity == .high)
        #expect(mockRepository.dayDataForDateCalledWith == TestDataBuilder.fixedDate)
    }

    @Test func run_clampsDurationToThreeHundredMinutes() throws {
        let intent = makeIntent(name: "Hike", minutes: 500)

        try intent.run(with: useCase, on: TestDataBuilder.fixedDate)

        let workout = try #require(mockRepository.saveDayDataCalledWith?.dayData.workouts.first)
        #expect(workout.duration.minutes == 300)
    }

    @Test func run_blankName_throwsWithoutSaving() {
        let intent = makeIntent(name: "   ")

        #expect(throws: (any Error).self) {
            try intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        }
        #expect(mockRepository.saveDayDataCalledWith == nil)
        #expect(mockRepository.saveCalledWithDays == nil)
    }

    @Test func registerUndo_removesOnlyTheAddedWorkout() throws {
        let intent = makeIntent(name: "Swim")
        let run = Workout(description: "Run")
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, workouts: [run])
        )
        let change = try intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        // A workout logged in the app after the intent ran must survive the undo
        let yoga = Workout(description: "Yoga")
        var current = try #require(mockRepository.saveDayDataCalledWith?.dayData)
        current.addWorkout(yoga)
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(current)

        try UndoManager.registerAndUndo(against: mockRepository) {
            intent.registerUndo(on: $0, useCase: $1, change: change)
        }

        let workouts = try #require(mockRepository.saveDayDataCalledWith?.dayData.workouts)
        #expect(workouts == [run, yoga])
    }

    @Test func parameterSummary_bindsNameAndListsMinutesAndIntensity() {
        let summary = AddWorkoutIntent.parameterSummary

        #expect(summary.sentenceFormat == "intent_add_workout_summary ${parameter0}")
        #expect(summary.sentenceParameters(of: AddWorkoutIntent.self) == [\AddWorkoutIntent.$name])
        let listed: [PartialKeyPath<AddWorkoutIntent>] = [\AddWorkoutIntent.$minutes, \AddWorkoutIntent.$intensity]
        #expect(summary.listedParameters(of: AddWorkoutIntent.self) == listed)
    }
}
