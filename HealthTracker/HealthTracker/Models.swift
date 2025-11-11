//
//  Models.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/21/25.
//

import SwiftUI

@Observable
class Store: Codable, Equatable {

    struct DayData: Codable, Equatable {
        struct Item: Codable, Equatable, Identifiable {
            let id: UUID
            var description: String
            var quantity: Int?
            var satisfaction: Int?
            var time: Int?

            init(description: String, quantity: Int? = nil, satisfaction: Int? = nil, time: Int? = nil) {
                self.id = UUID()
                self.description = description
                self.quantity = quantity
                self.satisfaction = satisfaction
                self.time = time
            }
        }

        public var date: Date
        public var meals: [Item]
        public var workouts: [Item]
        public var water: Double?
        public var mood: String?

        init(date: Date, meals: [Item], workouts: [Item], water: Double?, mood: String?) {
            self.date = date
            self.meals = meals
            self.workouts = workouts
            self.water = water
            self.mood = mood
        }

        static func == (lhs: DayData, rhs: DayData) -> Bool {
            lhs.date == rhs.date &&
            lhs.meals == rhs.meals &&
            lhs.workouts == rhs.workouts &&
            lhs.water == rhs.water &&
            lhs.mood == rhs.mood
        }
    }

    public var days: [DayData] = []

    static func == (lhs: Store, rhs: Store) -> Bool {
        lhs.days == rhs.days
    }
}


enum Section {
    case meal
    case workout
}
