//
//  ContentView.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

struct MainView: View {

    @State var selectedMood: String = ""
    @State var selectedDate = Date()
    @State var isMealModalPresented = false

    var body: some View {
        NavigationStack {
            List {
                DatePicker(selection: $selectedDate, displayedComponents: [.date]) {
                    Text("Selecione a data")
                        .font(.title)
                }
                .datePickerStyle(.compact)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

                CardView(internalPadding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
                    VStack(alignment: .leading) {
                        Text("🍴 Refeições")
                            .padding(.bottom, 15)
                            .font(.headline)

                        CardView {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Arroz, feijão, carne e salada")
                                        .padding(.bottom, 5)
                                    Text("Quantidade: média")
                                        .font(.subheadline)
                                    Text("Satisfeito(a): 80%")
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                        }

                        CardView {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Arroz, feijão, carne e salada")
                                        .padding(.bottom, 5)
                                    Text("Quantidade: média")
                                        .font(.subheadline)
                                    Text("Satisfeito(a): 80%")
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                        }

                        HStack {
                            Spacer()
                            Button("+", action: { isMealModalPresented = true })
                                .buttonStyle(.glass)
                            Spacer()
                        }
                        .padding(.top, 15)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

                CardView(internalPadding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
                    VStack(alignment: .leading) {
                        Text("🏋 Exercícios")
                            .padding(.bottom, 15)
                            .font(.headline)

                        CardView {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Caminhada")
                                        .padding(.bottom, 5)
                                    Text("40m")
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                        }

                        CardView {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Academia")
                                        .padding(.bottom, 5)
                                    Text("40m")
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                        }

                        HStack {
                            Spacer()
                            Button("+", action: { })
                                .buttonStyle(.glass)
                            Spacer()
                        }
                        .padding(.top, 15)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

                CardView(internalPadding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
                    VStack(alignment: .leading) {
                        Text("Como está o seu humor hoje?")
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
            .listRowSpacing(20)
        }
        .sheet(isPresented: $isMealModalPresented) {
            MealView()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

struct MealView: View {

    @State private var text = ""
    @State var selectedSize: String = ""

    var body: some View {
        TextEditor(text: $text)
            .frame(height: 150)
            .padding()
    }
}

//#Preview {
//    MainView()
//}
