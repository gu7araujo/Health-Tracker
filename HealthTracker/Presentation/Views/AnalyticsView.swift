//
//  AnalyticsView.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import SwiftUI

/// Main analytics view displaying health metrics charts and statistics
struct AnalyticsView: View {
    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView(String(localized: "loading"))
                } else if let analytics = viewModel.analyticsData {
                    analyticsContent(analytics)
                } else {
                    emptyState
                }
            }
            .navigationTitle(String(localized: "analytics_title"))
            .onAppear {
                viewModel.loadAnalytics()
            }
        }
    }

    // MARK: - Content Views

    private func analyticsContent(_ analytics: AnalyticsData) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period selector
                PeriodSelector(selectedPeriod: $viewModel.selectedPeriod)
                    .padding(.horizontal)

                // Overall health section
                overallHealthSection(analytics.overallAnalytics)

                // Meals section
                mealsSection(analytics.mealAnalytics)

                // Water section
                waterSection(analytics.waterAnalytics)

                // Workouts section
                workoutsSection(analytics.workoutAnalytics)

                // Mood section
                moodSection(analytics.moodAnalytics)
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(String(localized: "no_data_title"))
                .font(.title2)
                .fontWeight(.semibold)
            Text(String(localized: "no_data_message"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Section Views

    private func overallHealthSection(_ analytics: OverallAnalytics) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "overall_health_section"))
                    .font(.title2)
                    .fontWeight(.bold)

                if analytics.daysTracked > 0 {
                    // Chart
                    OverallHealthRingChart(statusDistribution: analytics.statusDistribution)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statItem(String(localized: "days_tracked"), value: "\(analytics.daysTracked)")
                        statItem(String(localized: "optimal_days"), value: "\(analytics.optimalDays)")
                        statItem(String(localized: "health_score"), value: String(format: "%.0f", analytics.healthScore))
                        statItem(String(localized: "current_streak"), value: "\(analytics.currentOptimalStreak)")
                    }
                } else {
                    sectionEmptyState(
                        icon: "heart.text.square",
                        message: String(localized: "empty_overall_health")
                    )
                }
            }
            .padding()
        }
    }

    private func mealsSection(_ analytics: MealAnalytics) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "meals_section"))
                    .font(.title2)
                    .fontWeight(.bold)

                if analytics.totalMeals > 0 {
                    // Chart
                    if !analytics.quantityDistribution.isEmpty {
                        MealsBarChart(quantityDistribution: analytics.quantityDistribution)
                    }

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statItem(String(localized: "total"), value: "\(analytics.totalMeals)")
                        statItem(String(localized: "average_satisfaction"), value: String(format: "%.0f%%", analytics.averageSatisfaction))
                        statItem(String(localized: "optimal_days"), value: "\(analytics.optimalDaysCount)")
                        statItem(String(localized: "common_size"), value: mostCommonQuantity(analytics.quantityDistribution))
                    }
                } else {
                    sectionEmptyState(
                        icon: "fork.knife",
                        message: String(localized: "empty_meals")
                    )
                }
            }
            .padding()
        }
    }

    private func waterSection(_ analytics: WaterAnalytics) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "water_section"))
                    .font(.title2)
                    .fontWeight(.bold)

                if !analytics.dailyIntake.isEmpty {
                    // Chart
                    WaterLineChart(
                        dailyIntake: analytics.dailyIntake,
                        dateRange: viewModel.selectedPeriod.dateRange
                    )

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statItem(String(localized: "daily_average"), value: String(format: "%.1fL", analytics.averageIntake))
                        statItem(String(localized: "days_above_optimal"), value: "\(analytics.daysAboveOptimal)")
                        statItem(String(localized: "maximum"), value: String(format: "%.1fL", analytics.maxIntake))
                        statItem(String(localized: "consistency"), value: String(format: "%.0f", analytics.consistencyScore))
                    }
                } else {
                    sectionEmptyState(
                        icon: "drop",
                        message: String(localized: "empty_water")
                    )
                }
            }
            .padding()
        }
    }

    private func workoutsSection(_ analytics: WorkoutAnalytics) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "workouts_analytics_section"))
                    .font(.title2)
                    .fontWeight(.bold)

                if analytics.totalWorkouts > 0 {
                    // Chart
                    if !analytics.weeklyVolume.isEmpty {
                        WorkoutsBarChart(weeklyVolume: analytics.weeklyVolume)
                    }

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statItem(String(localized: "total"), value: "\(analytics.totalWorkouts)")
                        statItem(String(localized: "total_minutes"), value: "\(analytics.totalMinutes)")
                        statItem(String(localized: "average_duration"), value: "\(analytics.averageDuration)min")
                        statItem(String(localized: "current_streak"), value: "\(analytics.currentStreak)")
                    }
                } else {
                    sectionEmptyState(
                        icon: "figure.run",
                        message: String(localized: "empty_workouts")
                    )
                }
            }
            .padding()
        }
    }

    private func moodSection(_ analytics: MoodAnalytics) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "mood_section"))
                    .font(.title2)
                    .fontWeight(.bold)

                if !analytics.dailyMood.isEmpty {
                    // Chart
                    MoodBarChart(distribution: analytics.distribution)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statItem(String(localized: "good_days"), value: String(format: "%.0f%%", analytics.goodDaysPercentage))
                        statItem(String(localized: "good_mood"), value: "\(analytics.distribution[.good] ?? 0)")
                        statItem(String(localized: "neutral_mood"), value: "\(analytics.distribution[.neutral] ?? 0)")
                        statItem(String(localized: "sad_mood"), value: "\(analytics.distribution[.sad] ?? 0)")
                    }
                } else {
                    sectionEmptyState(
                        icon: "face.smiling",
                        message: String(localized: "empty_mood")
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Views

    private func statItem(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }

    private func sectionEmptyState(icon: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Helper Functions

    private func mostCommonQuantity(_ distribution: [Meal.Quantity: Int]) -> String {
        guard let mostCommon = distribution.max(by: { $0.value < $1.value })?.key else {
            return String(localized: "chart_no_data")
        }
        return mostCommon.localizedName
    }
}

#Preview {
    AnalyticsView()
}
