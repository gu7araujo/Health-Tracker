//
//  AnalyticsViewModel.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Foundation

/// ViewModel for the analytics view.
/// Manages period selection and analytics data loading.
@Observable
final class AnalyticsViewModel {
    // MARK: - Dependencies

    private let calculateAnalyticsUseCase: CalculateAnalyticsUseCase

    // MARK: - State

    private(set) var analyticsData: AnalyticsData?
    private(set) var isLoading = false

    var selectedPeriod: AnalyticsPeriod = .last7Days {
        didSet {
            if selectedPeriod != oldValue {
                loadAnalytics()
            }
        }
    }

    // MARK: - Initialization

    init(calculateAnalyticsUseCase: CalculateAnalyticsUseCase) {
        self.calculateAnalyticsUseCase = calculateAnalyticsUseCase
    }

    /// Convenience initializer with default dependencies.
    convenience init(repository: HealthDataRepositoryProtocol = HealthDataRepository()) {
        self.init(
            calculateAnalyticsUseCase: CalculateAnalyticsUseCase(repository: repository)
        )
    }

    // MARK: - Public Methods

    /// Loads analytics data for the currently selected period.
    func loadAnalytics() {
        isLoading = true
        analyticsData = calculateAnalyticsUseCase.execute(for: selectedPeriod)
        isLoading = false
    }
}
