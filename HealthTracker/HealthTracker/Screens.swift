//
//  ContentView.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationStack {
            List {

            }
            .navigationTitle("Olá! 👋")
            .safeAreaInset(edge: .bottom, alignment: .center) {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 50)
            }
        }
    }
}

#Preview {
    MainView()
}
