//
//  PeriodSelector.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import SwiftUI

/// Period selector component for analytics view
struct PeriodSelector: View {
    @Binding var selectedPeriod: AnalyticsPeriod
    @State private var showingCustomPicker = false
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var pickerSelection: PickerOption = .last7Days

    var body: some View {
        Picker("Período", selection: $pickerSelection) {
            ForEach(PickerOption.allCases) { option in
                Text(option.displayName)
                    .tag(option)
            }
        }
        .pickerStyle(.menu)
        .onChange(of: pickerSelection) { _, newValue in
            handlePickerChange(newValue)
        }
        .onAppear {
            // Initialize picker selection based on current period
            pickerSelection = PickerOption.from(selectedPeriod)
        }
        .sheet(isPresented: $showingCustomPicker) {
            CustomDateRangePicker(
                startDate: $customStartDate,
                endDate: $customEndDate,
                onApply: {
                    selectedPeriod = .custom(start: customStartDate, end: customEndDate)
                    pickerSelection = .custom(selectedPeriod.displayName)
                    showingCustomPicker = false
                }
            )
        }
    }

    private func handlePickerChange(_ option: PickerOption) {
        switch option {
        case .thisWeek:
            selectedPeriod = .thisWeek
        case .last7Days:
            selectedPeriod = .last7Days
        case .last30Days:
            selectedPeriod = .last30Days
        case .customPlaceholder:
            // Initialize dates
            if case let .custom(start, end) = selectedPeriod {
                customStartDate = start
                customEndDate = end
            } else {
                customEndDate = Date()
                customStartDate = Calendar.current.date(byAdding: .day, value: -6, to: customEndDate) ?? Date()
            }
            showingCustomPicker = true
        case .custom:
            // Already selected custom range, just reopen picker
            if case let .custom(start, end) = selectedPeriod {
                customStartDate = start
                customEndDate = end
            }
            showingCustomPicker = true
        }
    }
}

/// Picker option enum to handle both predefined and custom periods
private enum PickerOption: Hashable, Identifiable, CaseIterable {
    case thisWeek
    case last7Days
    case last30Days
    case customPlaceholder
    case custom(String)

    var id: String {
        switch self {
        case .thisWeek:
            "thisWeek"
        case .last7Days:
            "last7Days"
        case .last30Days:
            "last30Days"
        case .customPlaceholder:
            "customPlaceholder"
        case let .custom(name):
            "custom_\(name)"
        }
    }

    var displayName: String {
        switch self {
        case .thisWeek:
            "Esta Semana"
        case .last7Days:
            "Últimos 7 Dias"
        case .last30Days:
            "Últimos 30 Dias"
        case .customPlaceholder:
            "Período Personalizado..."
        case let .custom(name):
            name
        }
    }

    static var allCases: [PickerOption] {
        [.thisWeek, .last7Days, .last30Days, .customPlaceholder]
    }

    static func from(_ period: AnalyticsPeriod) -> PickerOption {
        switch period {
        case .thisWeek:
            .thisWeek
        case .last7Days:
            .last7Days
        case .last30Days:
            .last30Days
        case .custom:
            .custom(period.displayName)
        }
    }
}

/// Custom date range picker view
private struct CustomDateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Data Inicial", selection: $startDate, displayedComponents: .date)
                        .onChange(of: startDate) { _, newValue in
                            // Ensure start is not after end
                            if newValue > endDate {
                                endDate = newValue
                            }
                        }

                    DatePicker("Data Final", selection: $endDate, displayedComponents: .date)
                        .onChange(of: endDate) { _, newValue in
                            // Ensure end is not before start
                            if newValue < startDate {
                                startDate = newValue
                            }
                        }
                } header: {
                    Text("Selecione o Período")
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Dias selecionados: \(daysBetween)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Período Personalizado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar", systemImage: "checkmark") {
                        onApply()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(.systemBlue))
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var daysBetween: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0 + 1
    }
}
