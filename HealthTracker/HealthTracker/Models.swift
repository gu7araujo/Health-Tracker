//
//  Models.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/21/25.
//

import SwiftUI

@Observable
class Store: Codable {

    struct DayData: Codable {
        struct Item: Codable {
            let id: UUID
            let description: String

            init(description: String) {
                self.id = UUID()
                self.description = description
            }
        }

        public var date: Date
        public var meals: [Item]
        public var workouts: [Item]
        public var water: Double

        init(date: Date, meals: [Item], workouts: [Item], water: Double) {
            self.date = date
            self.meals = meals
            self.workouts = workouts
            self.water = water
        }
    }

    public var days: [DayData] = []

}
