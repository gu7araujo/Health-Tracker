//
//  ContentView.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

struct MainView: View {

    @State private var store = Store()
    @State var selectedMood: String = ""
    @State var selectedDate = Date()
    @State var isAddEditModalPresented = false
    @State var waterQuantity = 1.0

    init() {
        guard let data = UserDefaults.standard.data(forKey: "store") else { return }
        let decoder = JSONDecoder()
        if let store = try? decoder.decode(Store.self, from: data) {
            self._store = State(initialValue: store)
        }
    }

    func displayMealModal() {
        isAddEditModalPresented.toggle()
    }

    var body: some View {
        NavigationStack {
            List {
                DatePicker(selection: $selectedDate, displayedComponents: [.date]) {
                    Text("Selecione a data")
                        .font(.title3)
                        .bold()
                }
                .datePickerStyle(.compact)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 30, leading: 20, bottom: 30, trailing: 20))

                HeaderListView(title: "Refeições", icon: "plus", action: displayMealModal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        CardListView(isFirst: true, isUnique: false, action: displayMealModal) {
                            VStack(alignment: .leading) {
                                Text("Arroz, feijão, carne e salada")
                                    .padding(.bottom, 5)
                                Text("Quantidade: média")
                                    .font(.subheadline)
                                Text("Satisfeito(a): 80%")
                                    .font(.subheadline)
                            }
                        }

                        CardListView(action: displayMealModal) {
                            VStack(alignment: .leading) {
                                Text("Arroz, feijão, carne e salada")
                                    .padding(.bottom, 5)
                                Text("Quantidade: média")
                                    .font(.subheadline)
                                Text("Satisfeito(a): 80%")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))

                Text("Água")
                    .font(.title3)
                    .bold()
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

                CardView {
                    HStack {
                        Spacer()
                        VStack {
                            Text(String(format: "%.1f L", waterQuantity))
                                .font(.title2)
                            Stepper(value: $waterQuantity, in: 0...10, step: 0.1, label: { })
                        }
                        Spacer()
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20))

                HeaderListView(title: "Exercícios", icon: "plus", action: displayMealModal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        CardListView(isFirst: true, isUnique: false, action: displayMealModal) {
                            VStack(alignment: .leading) {
                                Text("Caminhada")
                                    .padding(.bottom, 5)
                                Text("Tempo: 40m")
                                    .font(.subheadline)
                            }
                        }

                        CardListView(action: displayMealModal) {
                            VStack(alignment: .leading) {
                                Text("Caminhada")
                                    .padding(.bottom, 5)
                                Text("Tempo: 40m")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))

                Text("Humor")
                    .font(.title3)
                    .bold()
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
            .navigationTitle("Monitore sua saúde")
            .listStyle(.plain)
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $isAddEditModalPresented) {
            AddEditModal()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

struct AddEditModal: View {

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
