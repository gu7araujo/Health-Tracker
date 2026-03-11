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
    let days: [DayData]

    @State private var dates: [Date] = []
    @State private var isLoadingPast = false
    @State private var needsMorePastDates = false

    /// Calendar configuration using system locale and timezone, with Monday as first day of week.
    private var brazilianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone.current
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
                            let isFuture = isFutureDate(date)
                            let status = dayStatus(for: date)
                            CalendarStripDay(
                                weekdayLetter: weekdayLetter(from: date),
                                dayNumber: dayNumber(from: date),
                                isSelected: isSelected,
                                isFuture: isFuture,
                                status: status
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
            }
        }.frame(height: 65)
    }

    // MARK: - Date Formatting

    private func isFutureDate(_ date: Date) -> Bool {
        let calendar = brazilianCalendar
        let normalizedDate = calendar.startOfDay(for: date)
        let normalizedToday = calendar.startOfDay(for: Date())
        return normalizedDate > normalizedToday
    }

    private func dayStatus(for date: Date) -> DayStatus {
        guard let dayData = days.first(where: { brazilianCalendar.isDate($0.date, inSameDayAs: date) }) else {
            return .noData
        }
        return dayData.status
    }

    private func weekdayLetter(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "EEEEE" // Single letter weekday initial
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
        for dayOffset in -7 ..< 0 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                tempDates.append(date)
            }
        }

        // Load CURRENT week (7 days starting from current week)
        for dayOffset in 0 ..< 7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                tempDates.append(date)
            }
        }

        dates = tempDates
    }

    private func scrollToCurrentWeek(using proxy: ScrollViewProxy) {
        if let startOfCurrentWeek = brazilianCalendar.dateInterval(of: .weekOfYear, for: Date())?.start {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                proxy.scrollTo(startOfCurrentWeek, anchor: .leading)
            }
        }
    }

    private func checkAndLoadPast(for date: Date) {
        // Find the index of the appearing date in the array
        guard let index = dates.firstIndex(where: { brazilianCalendar.isDate($0, inSameDayAs: date) }) else {
            return
        }

        // Load more when user sees one of the first 3 dates in the list
        guard index < 3 else { return }

        if isLoadingPast {
            // Mark that we need more dates after current load finishes
            needsMorePastDates = true
        } else {
            loadPastWeeks()
        }
    }

    private func loadPastWeeks() {
        guard let firstDate = dates.first else { return }
        isLoadingPast = true
        needsMorePastDates = false

        let calendar = brazilianCalendar
        var newDates: [Date] = []

        // Load 1 week (7 days) before the current first date
        for dayOffset in (1 ... 7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: firstDate) {
                newDates.append(date)
            }
        }

        dates = newDates + dates

        // Small delay before allowing next load, then check if more needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isLoadingPast = false
            if needsMorePastDates {
                loadPastWeeks()
            }
        }
    }
}

// MARK: - Calendar Strip Day

/// Individual day view in the calendar strip.
struct CalendarStripDay: View {
    let weekdayLetter: String
    let dayNumber: Int
    let isSelected: Bool
    let isFuture: Bool
    let status: DayStatus
    let onTap: () -> Void

    var body: some View {
        VStack {
            Text(weekdayLetter)
                .font(.title3)
                .padding(7)
                .background(circleBackground)
                .foregroundColor(isFuture ? .gray : .primary)

            Text("\(dayNumber)")
                .font(.title3)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isFuture ? .gray : .primary)
        }
        .onTapGesture {
            if !isFuture {
                onTap()
            }
        }
    }

    @ViewBuilder
    private var circleBackground: some View {
        if !isFuture, let circleColor = status.color {
            if status == .incomplete {
                // Right-half semicircle for incomplete days
                RightSemicircle()
                    .stroke(circleColor, lineWidth: 2)
            } else {
                // Full circle for complete days
                Circle()
                    .fill(Color.clear)
                    .overlay(
                        Circle()
                            .stroke(circleColor, lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - Right Semicircle Shape

/// A shape that draws only the right half of a circle (from top to bottom).
struct RightSemicircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Draw arc from top (270°) to bottom (90°) on the right side
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )

        return path
    }
}

#Preview {
    CalendarStrip(selectedDate: .constant(Date()), days: [])
}
