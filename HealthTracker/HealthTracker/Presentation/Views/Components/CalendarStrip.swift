//
//  CalendarStrip.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

/// A horizontally scrollable calendar strip showing days of the week.
struct CalendarStrip: View {

    @Binding var selectedDate: Date
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
        GeometryReader { outerGeometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(dates, id: \.self) { date in
                            let isSelected = brazilianCalendar.isDate(date, inSameDayAs: selectedDate)
                            CalendarStripDay(
                                weekdayLetter: weekdayLetter(from: date),
                                dayNumber: dayNumber(from: date),
                                isSelected: isSelected
                            ) {
                                selectedDate = date
                            }
                            .frame(width: outerGeometry.size.width / 8)
                            .id(date)
                            .onAppear {
                                checkAndLoadPast(for: date)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .onAppear {
                    if dates.isEmpty {
                        loadInitialDates()
                        scrollToCurrentWeek(using: proxy)
                    }
                }
                .onChange(of: selectedDate) { _, newDate in
                    scrollToSelectedDate(newDate, using: proxy)
                }
            }
        }.frame(height: 65)
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

    private func scrollToSelectedDate(_ date: Date, using proxy: ScrollViewProxy) {
        // Ensure the date exists in the dates array, if not, load more dates
        let dateExists = dates.contains { brazilianCalendar.isDate($0, inSameDayAs: date) }
        
        if !dateExists {
            // Load dates around the selected date
            loadDatesAround(date)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            proxy.scrollTo(date, anchor: .center)
        }
    }

    private func loadDatesAround(_ date: Date) {
        let calendar = brazilianCalendar
        var newDates: [Date] = []
        
        // Load 7 days before and 7 days after the selected date
        for dayOffset in -7...7 {
            if let newDate = calendar.date(byAdding: .day, value: dayOffset, to: date) {
                newDates.append(newDate)
            }
        }
        
        // Merge with existing dates, avoiding duplicates
        let existingDateSet = Set(dates.map { calendar.startOfDay(for: $0) })
        let newDateSet = Set(newDates.map { calendar.startOfDay(for: $0) })
        let uniqueNewDates = newDates.filter { !existingDateSet.contains(calendar.startOfDay(for: $0)) }
        
        dates = (dates + uniqueNewDates).sorted()
        oldestLoadedDate = dates.first
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
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack {
            Text(weekdayLetter)
                .font(.title3)
                .padding(7)
                .background(
                    Circle()
                        .fill(isSelected ? Color.green : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(Color.green, lineWidth: isSelected ? 2 : 3)
                        )
                )
                .foregroundColor(isSelected ? .white : .primary)

            Text("\(dayNumber)")
                .font(.title3)
                .foregroundColor(isSelected ? .green : .primary)
        }
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    CalendarStrip(selectedDate: .constant(Date()))
}
