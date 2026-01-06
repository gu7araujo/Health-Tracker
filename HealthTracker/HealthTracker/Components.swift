//
//  Components.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/21/25.
//

import SwiftUI

struct CardView<Content: View>: View {

    @ViewBuilder var content: Content
    @Binding var backgroundColor: Color?

    private let internalPadding: EdgeInsets
    private let applyGlassEffect: Bool
    private let action: (() -> Void)?

    init(internalPadding: EdgeInsets? = nil, applyGlassEffect: Bool = true, backgroundColor: Binding<Color?> = .constant(nil), action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.internalPadding = internalPadding ?? EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        self.action = action
        self.applyGlassEffect = applyGlassEffect
        self._backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        Button(action: action ?? {}, label: {
            content
                .padding(internalPadding)
                .if(applyGlassEffect, transform: { view in
                    view
                        .glassEffect(in: .rect(cornerRadius: 16))
                })
                .background(backgroundColor)
                .cornerRadius(applyGlassEffect ? 0 : 16)
        })
        .buttonStyle(.plain)
    }
}

struct HeaderListView: View {

    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .bold()
            Spacer()
            Button("", systemImage: icon, action: action)
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
    }
}

struct CardListView<Content: View>: View {

    @ViewBuilder var content: Content

    let isFirst: Bool
    let isUnique: Bool

    init(isFirst: Bool = false, isUnique: Bool = false, @ViewBuilder content: () -> Content) {
        self.isFirst = isFirst
        self.isUnique = isUnique
        self.content = content()
    }

    var body: some View {
        CardView {
            HStack {
                content
                Spacer()
            }
        }
        .if(isUnique, transform: { view in
            view
                .frame(width: UIScreen.main.bounds.width-40)
        })
        .if(!isUnique, transform: { view in
            view
                .frame(maxWidth: UIScreen.main.bounds.width-40)
        })
        .padding(.leading, isFirst ? 20 : 0)
    }
}

struct CalendarStrip: View {
    @State private var dates: [Date] = []
    @State private var isLoadingPast = false
    @State private var oldestLoadedDate: Date? = nil

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(dates, id: \.self) { date in
                        CalendarStripDay(weekdayLetter: getWeekdayLetter(from: date),
                                         dayNumber: getDayNumber(from: date))
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
                    // Scroll to current week start after loading
                    if let startOfCurrentWeek = getBrazilianCalendar().dateInterval(of: .weekOfYear, for: Date())?.start {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(startOfCurrentWeek, anchor: .leading)
                        }
                    }
                }
            }
        }
    }

    private func getBrazilianCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "pt_BR")
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        calendar.firstWeekday = 2 // Monday as first day of week
        return calendar
    }

    private func getWeekdayLetter(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        formatter.dateFormat = "EEEEE" // Single letter: D, S, T, Q, Q, S, S
        return formatter.string(from: date)
    }

    private func getDayNumber(from date: Date) -> Int {
        let calendar = getBrazilianCalendar()
        return calendar.component(.day, from: date)
    }

    private func loadInitialDates() {
        let calendar = getBrazilianCalendar()
        let today = Date()

        // Get the start of the current week (Sunday in Brazil)
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

    private func checkAndLoadPast(for date: Date) {
        // Only trigger if we're within 3 days of the oldest date we've loaded
        guard !isLoadingPast,
              let oldest = oldestLoadedDate else {
            return
        }

        let calendar = getBrazilianCalendar()
        let daysSinceOldest = calendar.dateComponents([.day], from: date, to: oldest).day ?? 0

        // Load more when user gets within 3 days of the oldest ever loaded date
        if abs(daysSinceOldest) <= 3 {
            loadPastWeeks()
        }
    }

    private func loadPastWeeks() {
        guard let firstDate = dates.first else { return }
        isLoadingPast = true

        let calendar = getBrazilianCalendar()
        var newDates: [Date] = []

        // Load 1 week (7 days) before the current first date
        for dayOffset in (1...7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: firstDate) {
                newDates.append(date)
            }
        }

        dates = newDates + dates

        // Update the oldest date we've ever loaded
        oldestLoadedDate = dates.first

        // Small delay before allowing next load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoadingPast = false
        }
    }
}

struct CalendarStripDay: View {
    var weekdayLetter: String
    var dayNumber: Int

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
