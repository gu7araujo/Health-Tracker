//
//  MealsSectionView.swift
//  HealthTracker
//

import SwiftUI

struct MealsSectionView: View {
    let meals: [Meal]
    @Binding var editingMealId: UUID?
    let onDelete: (UUID) -> Void
    let onMove: (IndexSet, Int) -> Void

    var body: some View {
        Group {
            Text(String(localized: "meals_section"))
                .font(.title2)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            if !meals.isEmpty {
                ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                    CardView(
                        internalPadding: .init(top: 15, leading: 15, bottom: 15, trailing: 15),
                        applyGlassEffect: false,
                        backgroundColor: .constant(Color(.secondarySystemBackground))
                    ) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(meal.description)
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                Text(String(
                                    format: String(localized: "quantity_label"),
                                    meal.quantity.localizedName
                                ))
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                Text(String(
                                    format: String(localized: "satisfaction_label"),
                                    meal.satisfaction.localizedName
                                ))
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(AccessibilityID.mealCard(index))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(meal.id)
                        } label: {
                            Label(String(localized: "delete_action"), systemImage: "trash")
                        }
                        .accessibilityIdentifier(AccessibilityID.mealDeleteButton(index))
                        Button {
                            editingMealId = meal.id
                        } label: {
                            Label(String(localized: "edit_action"), systemImage: "pencil")
                        }
                        .tint(.blue)
                        .accessibilityIdentifier(AccessibilityID.mealEditButton(index))
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                }
                .onMove(perform: onMove)
            } else {
                EmptyListRow()
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(AccessibilityID.mealsEmptyState)
            }
        }
    }
}
