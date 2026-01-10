//
//  CalendarStrip.swift
//  HealthTracker
//
//  Presentation Layer - Horizontal calendar strip component
//

import SwiftUI

/// A horizontally scrollable calendar strip showing days of the week.
struct CalendarStrip: View {

    @State private var dates: [Date] = []
    @State private var isLoadingPast = false
    @State private var oldestLoadedDate: Date?

    /// Brazilian calendar configuration with safe timezone initialization.
    private var brazilianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "pt_BR")
        // Safe timezone initialization - falls back to current timezone if invalid
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .current
        calendar.firstWeekday = 2 // Monday as first day of week
        return calendar
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(dates, id: \.self) { date in
                        CalendarStripDay(
                            weekdayLetter: weekdayLetter(from: date),
                            dayNumber: dayNumber(from: date)
                        )
                        .id(date)
                        .onAppear {
                            checkAndLoadPast(for: date)
                        }
                    }
                }
                .scrollTargetLayout()
                .padding()
            }
            .scrollTargetBehavior(.paging)
            .onAppear {
                if dates.isEmpty {
                    loadInitialDates()
                    scrollToCurrentWeek(using: proxy)
                }
            }
        }
    }

    // MARK: - Date Formatting

    private func weekdayLetter(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .current
        formatter.dateFormat = "EEEEE" // Single letter: D, S, T, Q, Q, S, S
        return formatter.string(from: date)
    }

    private func dayNumber(from date: Date) -> Int {
        brazilianCalendar.component(.day, from: date)
    }

    // MARK: - Date Loading

    private func loadInitialDates() {
        let calendar = brazilianCalendar
        let today = Date()

        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return
        }

        var tempDates: [Date] = []

        // Load PAST week (7 days before current week)
        for dayOffset in -7..<0 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                tempDates.append(date)
            }
        }

        // Load CURRENT week (7 days starting from current week)
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                tempDates.append(date)
            }
        }

        dates = tempDates
        oldestLoadedDate = dates.first
    }

    private func scrollToCurrentWeek(using proxy: ScrollViewProxy) {
        if let startOfCurrentWeek = brazilianCalendar.dateInterval(of: .weekOfYear, for: Date())?.start {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                proxy.scrollTo(startOfCurrentWeek, anchor: .leading)
            }
        }
    }

    private func checkAndLoadPast(for date: Date) {
        guard !isLoadingPast, let oldest = oldestLoadedDate else {
            return
        }

        let calendar = brazilianCalendar
        let daysSinceOldest = calendar.dateComponents([.day], from: date, to: oldest).day ?? 0

        // Load more when user gets within 3 days of the oldest loaded date
        if abs(daysSinceOldest) <= 3 {
            loadPastWeeks()
        }
    }

    private func loadPastWeeks() {
        guard let firstDate = dates.first else { return }
        isLoadingPast = true

        let calendar = brazilianCalendar
        var newDates: [Date] = []

        // Load 1 week (7 days) before the current first date
        for dayOffset in (1...7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: firstDate) {
                newDates.append(date)
            }
        }

        dates = newDates + dates
        oldestLoadedDate = dates.first

        // Small delay before allowing next load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoadingPast = false
        }
    }
}

// MARK: - Calendar Strip Day

/// Individual day view in the calendar strip.
struct CalendarStripDay: View {

    let weekdayLetter: String
    let dayNumber: Int

    var body: some View {
        VStack {
            Text(weekdayLetter)
                .font(.title3)
                .padding(7)
                .background(
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                )

            Text("\(dayNumber)")
                .font(.title3)
        }
    }
}

#Preview {
    CalendarStrip()
}
