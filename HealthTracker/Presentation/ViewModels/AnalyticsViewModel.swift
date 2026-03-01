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
    private let logger: LoggerProtocol

    // MARK: - State

    private(set) var analyticsData: AnalyticsData?
    private(set) var isLoading = false

    var selectedPeriod: AnalyticsPeriod = .last7Days {
        didSet {
            if selectedPeriod != oldValue {
                logger.debug("Period changed from \(oldValue) to \(selectedPeriod)")
                loadAnalytics()
            }
        }
    }

    // MARK: - Initialization

    init(
        calculateAnalyticsUseCase: CalculateAnalyticsUseCase,
        logger: LoggerProtocol = LoggerFactory.presentationLogger(category: "AnalyticsViewModel")
    ) {
        self.calculateAnalyticsUseCase = calculateAnalyticsUseCase
        self.logger = logger
    }

    /// Convenience initializer with default dependencies.
    convenience init(repository: HealthDataRepositoryProtocol = HealthDataRepository()) {
        self.init(
            calculateAnalyticsUseCase: CalculateAnalyticsUseCase(
                repository: repository,
                logger: LoggerFactory.domainLogger(category: "Analytics")
            )
        )
    }

    // MARK: - Public Methods

    /// Loads analytics data for the currently selected period.
    func loadAnalytics() {
        logger.debug("Loading analytics for period: \(selectedPeriod)")
        isLoading = true

        do {
            analyticsData = calculateAnalyticsUseCase.execute(for: selectedPeriod)
            logger.info("Analytics loaded successfully for period: \(selectedPeriod)")
        } catch {
            logger.error("Failed to load analytics: \(error.localizedDescription)")
            analyticsData = nil
        }

        isLoading = false
    }
}
