//
//  ContentView.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

struct MainView: View {

    @State var selectedMood: String = ""

    var body: some View {
        NavigationStack {
            List {
                CardView(internalPadding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
                    VStack(alignment: .leading) {
                        Text("Como você está?")
                            .padding(.bottom, 15)
                            .font(.headline)

                        HStack {
                            CardView(applyGlassEffect: selectedMood == "Good" ? false : true, backgroundColor: .constant(selectedMood == "Good" ? .green : nil)) {
                                selectedMood = "Good"
                            } content: {
                                HStack {
                                    Spacer()
                                    VStack {
                                        Text("😁")
                                        Text("Bom")
                                    }
                                    Spacer()
                                }
                            }


                            CardView(applyGlassEffect: selectedMood == "Neutral" ? false : true, backgroundColor: .constant(selectedMood == "Neutral" ? .orange : nil)) {
                                selectedMood = "Neutral"
                            } content: {
                                HStack {
                                    Spacer()
                                    VStack {
                                        Text("😐")
                                        Text("Neutro")
                                    }
                                    Spacer()
                                }
                            }


                            CardView(applyGlassEffect: selectedMood == "Sad" ? false : true, backgroundColor: .constant(selectedMood == "Sad" ? .red : nil)) {
                                selectedMood = "Sad"
                            } content: {
                                HStack {
                                    Spacer()
                                    VStack {
                                        Text("😔")
                                        Text("Ruim")
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            }
            .navigationTitle("Olá! 👋")
            .listStyle(.plain)
            .listRowSpacing(10)
        }
    }
}

#Preview {
    MainView()
}
