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

    func getQuantityLabel(_ element: Store.DayData.Item) -> String {
        if element.quantity == 0 {
            return "Muito pequena"
        } else if element.quantity == 1 {
            return "Pequena"
        } else if element.quantity == 2 {
            return "Média"
        } else if element.quantity == 3 {
            return "Grande"
        } else {
            return ""
        }
    }

    func getSatisfactionLabel(_ element: Store.DayData.Item) -> String {
        if element.satisfaction == 0 {
            return "30%"
        } else if element.satisfaction == 1 {
            return "50%"
        } else if element.satisfaction == 2 {
            return "80%"
        } else if element.satisfaction == 3 {
            return "100%"
        } else {
            return ""
        }
    }

    func getDurationLabel(_ element: Store.DayData.Item) -> String {
        if element.time == 0 {
            return "15m"
        } else if element.time == 1 {
            return "30m"
        } else if element.time == 2 {
            return "1h"
        } else if element.time == 3 {
            return "1h30m"
        } else {
            return ""
        }
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
                                        Text("Quantidade: \(getQuantityLabel(element))")
                                            .font(.subheadline)
                                        Text("Satisfeito(a): \(getSatisfactionLabel(element))")
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
                                        Text("Tempo: \(getDurationLabel(element))")
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
    @State var selectedQuantity: Int = 1
    @State var selectedSatisfied: Int = 1
    @State var selectedTime: Int = 1

    var date: Date
    var section: Section
    var itemID: UUID?

    init(date: Date, section: Section, itemID: UUID? = nil) {
        self.date = date
        self.section = section
        self.itemID = itemID
        self.text = ""
        print("Gustavo - \(section)")
    }

    var body: some View {
        List {
            TextEditor(text: $text)
                .frame(height: 40)

            if section == .meal {
                Picker("Quantidade", selection: $selectedQuantity) {
                    Text("Muito pequena").tag(0)
                    Text("Pequena").tag(1)
                    Text("Média").tag(2)
                    Text("Grande").tag(3)
                }

                Picker("Satisfeito(a)", selection: $selectedSatisfied) {
                    Text("30%").tag(0)
                    Text("50%").tag(1)
                    Text("80%").tag(2)
                    Text("100%").tag(3)
                }
            } else {
                Picker("Tempo", selection: $selectedTime) {
                    Text("15m").tag(0)
                    Text("30m").tag(1)
                    Text("1h").tag(2)
                    Text("1h30m").tag(3)
                }
            }

            Button("Salvar") {
                guard let dayIndex = store.days.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return }

                if let itemID { // edit
                    if section == .meal {
                        guard let itemIndex = store.days[dayIndex].meals.firstIndex(where: { $0.id == itemID }) else { return }
                        store.days[dayIndex].meals[itemIndex].description = text
                        store.days[dayIndex].meals[itemIndex].quantity = selectedQuantity
                        store.days[dayIndex].meals[itemIndex].satisfaction = selectedSatisfied
                    } else {
                        guard let itemIndex = store.days[dayIndex].workouts.firstIndex(where: { $0.id == itemID }) else { return }
                        store.days[dayIndex].workouts[itemIndex].description = text
                        store.days[dayIndex].workouts[itemIndex].time = selectedTime
                    }
                } else { // add
                    if section == .meal {
                        store.days[dayIndex].meals.append(.init(description: text, quantity: selectedQuantity, satisfaction: selectedSatisfied))
                    } else {
                        store.days[dayIndex].workouts.append(.init(description: text, time: selectedTime))
                    }
                }

                dismiss()
            }
        }
        .onAppear {
            if section == .meal {
                text = store.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.meals.first(where: { $0.id == itemID })?.description ?? ""
                selectedQuantity = store.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.meals.first(where: { $0.id == itemID })?.quantity ?? 1
                selectedSatisfied = store.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.meals.first(where: { $0.id == itemID })?.satisfaction ?? 1
            } else {
                text = store.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.workouts.first(where: { $0.id == itemID })?.description ?? ""
                selectedTime = store.days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.workouts.first(where: { $0.id == itemID })?.time ?? 1
            }
        }
    }
}

//#Preview {
//    MainView()
//}
