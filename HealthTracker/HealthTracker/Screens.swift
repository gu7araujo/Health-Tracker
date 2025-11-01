//
//  ContentView.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

struct MainView: View {

    @State var store = Store()
    @State var selectedDateData: Store.DayData?
    @State var selectedDate = Date()
    @State var isAddModalPresented = false
    @State var modalSection: Section?
    @State var editModalData: Store.DayData.Item?

    var waterBinding: Binding<Double> {
        Binding<Double>(
            get: { selectedDateData?.water ?? 0 },
            set: { selectedDateData?.water = $0 }
        )
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

                HeaderListView(title: "Refeições", icon: "plus", action: {
                    modalSection = .meal
                    isAddModalPresented = true
                })

                if selectedDateData?.meals.isEmpty == false {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(selectedDateData?.meals ?? []).enumerated(), id: \.offset) { index, element in
                                CardListView(isFirst: index == 0, isUnique: selectedDateData?.meals.count == 1) {
                                    VStack(alignment: .leading) {
                                        Text(element.description)
                                            .padding(.bottom, 5)
                                        Text("Quantidade: ")
                                            .font(.subheadline)
                                        Text("Satisfeito(a): ")
                                            .font(.subheadline)
                                    }
                                }
                                .onTapGesture(count: 2) {
                                    modalSection = .meal
                                    editModalData = element
                                }
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                } else {
                    HStack {
                        Spacer()
                        Text("Lista vazia!")
                        Spacer()
                    }
                }

                Text("Água")
                    .font(.title3)
                    .bold()
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

                CardView {
                    HStack {
                        Spacer()
                        VStack {
                            Text(String(format: "%.1f L", selectedDateData?.water ?? 0))
                                .font(.title2)
                            Stepper(value: waterBinding, in: 0...10, step: 0.1, label: { }) { changed in
                                guard changed else { return }
                                if changed, let dayIndex = store.days.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                                    store.days[dayIndex].water = selectedDateData?.water
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20))

                HeaderListView(title: "Exercícios", icon: "plus", action: {
                    modalSection = .workout
                    isAddModalPresented = true
                })

                if selectedDateData?.workouts.isEmpty == false {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(selectedDateData?.workouts ?? []).enumerated(), id: \.offset) { index, element in
                                CardListView(isFirst: index == 0, isUnique: selectedDateData?.workouts.count == 1) {
                                    VStack(alignment: .leading) {
                                        Text(element.description)
                                            .padding(.bottom, 5)
                                        Text("Tempo: ")
                                            .font(.subheadline)
                                    }
                                }
                                .onTapGesture(count: 2) {
                                    modalSection = .workout
                                    editModalData = element
                                }
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                } else {
                    HStack {
                        Spacer()
                        Text("Lista vazia!")
                        Spacer()
                    }
                }

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
                            CardView(applyGlassEffect: selectedDateData?.mood == "Good" ? false : true, backgroundColor: .constant(selectedDateData?.mood == "Good" ? .green : nil)) {
                                guard let dayIndex = store.days.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) else { return }
                                store.days[dayIndex].mood = "Good"
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


                            CardView(applyGlassEffect: selectedDateData?.mood == "Neutral" ? false : true, backgroundColor: .constant(selectedDateData?.mood == "Neutral" ? .orange : nil)) {
                                guard let dayIndex = store.days.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) else { return }
                                store.days[dayIndex].mood = "Neutral"
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


                            CardView(applyGlassEffect: selectedDateData?.mood == "Sad" ? false : true, backgroundColor: .constant(selectedDateData?.mood == "Sad" ? .red : nil)) {
                                guard let dayIndex = store.days.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) else { return }
                                store.days[dayIndex].mood = "Sad"
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
        .onFirstAppear {
            if let data = UserDefaults.standard.data(forKey: "store") {
                let decoder = JSONDecoder()
                if let store = try? decoder.decode(Store.self, from: data) {
                    self.store = store
                }
            }

            if store.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) == nil {
                let newDate = Store.DayData(date: Date(), meals: [], workouts: [], water: nil, mood: nil)
                selectedDateData = newDate
                store.days.append(newDate)
                let encoder = JSONEncoder()
                let data = try? encoder.encode(store)
                UserDefaults.standard.set(data, forKey: "store")
            } else {
                selectedDateData = store.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })
            }
        }
        .onChange(of: selectedDate, { _, newValue in
            guard let dayData = store.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) else {
                let newDate = Store.DayData(date: selectedDate, meals: [], workouts: [], water: nil, mood: nil)
                selectedDateData = newDate
                store.days.append(newDate)
                return
            }
            selectedDateData = dayData
        })
        .onChange(of: store.days, { _, _ in
            let encoder = JSONEncoder()
            let data = try? encoder.encode(store)
            UserDefaults.standard.set(data, forKey: "store")
            selectedDateData = store.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })
        })
        .sheet(isPresented: $isAddModalPresented) {
            AddEditModal(date: selectedDate, section: modalSection ?? .meal)
                .environment(store)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editModalData) { item in
            AddEditModal(date: selectedDate, section: modalSection ?? .meal, itemID: item.id)
                .environment(store)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

struct AddEditModal: View {

    @Environment(\.dismiss) var dismiss
    @Environment(Store.self) var store
    @State var text: String

    var date: Date
    var section: Section
    var itemID: UUID?

    init(date: Date, section: Section, itemID: UUID? = nil) {
        self.date = date
        self.section = section
        self.itemID = itemID
        self.text = ""
    }

    var body: some View {
        VStack {
            TextEditor(text: $text)
                .frame(height: 150)
                .padding()
            Button("Salvar") {
                guard let dayIndex = store.days.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return }

                if let itemID { // edit
                    if section == .meal {
                        guard let itemIndex = store.days[dayIndex].meals.firstIndex(where: { $0.id == itemID }) else { return }
                        store.days[dayIndex].meals[itemIndex].description = text
                    } else {
                        guard let itemIndex = store.days[dayIndex].workouts.firstIndex(where: { $0.id == itemID }) else { return }
                        store.days[dayIndex].workouts[itemIndex].description = text
                    }
                } else { // add
                    if section == .meal {
                        store.days[dayIndex].meals.append(.init(description: text))
                    } else {
                        store.days[dayIndex].workouts.append(.init(description: text))
                    }
                }

                dismiss()
            }
        }
        .onAppear {
            if section == .meal {
                text = store.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.meals.first(where: { $0.id == itemID })?.description ?? ""
            } else {
                text = store.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.workouts.first(where: { $0.id == itemID })?.description ?? ""
            }
        }
    }
}

//#Preview {
//    MainView()
//}
