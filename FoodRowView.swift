import SwiftUI
import Firebase
import FirebaseAuth

// Eine einzelne Zeile in der Lebensmittelliste mit Menge und Hinzufügen-Button.
struct FoodRowView: View {
    let name: String
    let kcalPerUnit: Int
    @Binding var selectedMeal: String?
    @Binding var meals: [String: [String]]
    @Binding var mealsByDate: [String: [String: [String]]]
    // Menge des ausgewählten Lebensmittels.
    @State private var count = 1

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Stepper(value: $count, in: 1...10) {
                Text("\(count)")
            }
            // Fügt das Lebensmittel der gewählten Mahlzeit hinzu und speichert in Firestore.
            Button("✓") {
                let kcal = count * kcalPerUnit
                let text = "\(name) x\(count) = \(kcal) kcal"

                if let meal = selectedMeal {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let today = formatter.string(from: Date())
                    var updated = mealsByDate[today] ?? [
                        "Frühstück": [],
                        "Mittagessen": [],
                        "Abendessen": [],
                        "Snacks": []
                    ]

                    updated[meal, default: []].append(text)
                    mealsByDate[today] = updated

                    if let uid = Auth.auth().currentUser?.uid {
                        Firestore.firestore().collection("users").document(uid).setData([
                            "mealsByDate": mealsByDate
                        ], merge: true)
                    }
                }

                selectedMeal = nil
                count = 1
            }
            .foregroundColor(.green)
        }
    }
}
