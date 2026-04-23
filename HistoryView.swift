import SwiftUI

// Zeigt gespeicherte Mahlzeiten nach Datum sortiert an.
struct HistoryView: View {
    var mealsByDate: [String: [String: [String]]]
    var calorieDifferenceByDate: [String: Int]

    var body: some View {
        List {
            ForEach(mealsByDate.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date)) {
                    let meals = mealsByDate[date] ?? [:]
                    let difference = calorieDifferenceByDate[date]

                    if let difference {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Überschuss / Defizit")
                                .font(.headline)

                            Text("\(abs(difference)) kcal \(difference > 0 ? "Überschuss" : "Defizit")")
                                .foregroundColor(difference > 0 ? .green : .red)
                        }
                        .padding(.bottom, 6)
                    }

                    ForEach(["Frühstück", "Mittagessen", "Abendessen", "Snacks"], id: \.self) { meal in
                        if let items = meals[meal], !items.isEmpty {
                            Text(meal)
                                .font(.headline)

                            ForEach(items, id: \.self) { item in
                                Text("• \(item)")
                            }
                        }
                    }
                }
            }
        }
    }
}
