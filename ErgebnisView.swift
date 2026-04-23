import SwiftUI
import Firebase
import FirebaseAuth

// Zeigt den berechneten Bedarf, gegessene Mahlzeiten und die Tagesübersicht.
struct ErgebnisView: View {
    // Übergabe des berechneten Kalorienbedarfs aus der Hauptansicht.
    var calories: Double

    @EnvironmentObject var authVM: AuthViewModel

    // Steuert, für welche Mahlzeit gerade Lebensmittel hinzugefügt werden.
    @State private var selectedMeal: String? = nil
    // Speichert alle Mahlzeiten gruppiert nach Datum und Mahlzeitentyp.
    @State private var mealsByDate: [String: [String: [String]]] = [:]
    // Speichert den täglichen Überschuss- oder Defizitwert nach Datum.
    @State private var calorieDifferenceByDate: [String: Int] = [:]

    // Liefert den heutigen Tag als Schlüssel für mealsByDate.
    var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // Greift nur auf die Mahlzeiten des heutigen Tages zu.
    var meals: [String: [String]] {
        get {
            mealsByDate[todayKey] ?? [
                "Frühstück": [],
                "Mittagessen": [],
                "Abendessen": [],
                "Snacks": []
            ]
        }
        set {
            mealsByDate[todayKey] = newValue
        }
    }

    // Addiert die Kalorien aller gespeicherten Einträge des heutigen Tages.
    var consumedCalories: Int {
        meals.values.flatMap { $0 }.reduce(0) { total, item in
            if let kcalString = item.components(separatedBy: "=").last {
                let cleaned = kcalString
                    .replacingOccurrences(of: "kcal", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if let kcal = Int(cleaned) {
                    return total + kcal
                }
            }
            return total
        }
    }

    // Vergleicht gegessene Kalorien mit dem Sollwert.
    var calorieDifference: Int {
        consumedCalories - Int(calories)
    }

    // Einfache Vorschläge abhängig davon, wie viele Kalorien noch offen sind.
    var mealSuggestions: [String] {
        let remaining = Int(calories) - consumedCalories

        if remaining <= 0 {
            return ["Kein weiterer Bedarf heute"]
        } else if remaining < 300 {
            return ["Apfel (80 kcal)", "Joghurt (120 kcal)"]
        } else if remaining < 600 {
            return ["Banane + Joghurt (220 kcal)", "Avocado Snack (250 kcal)"]
        } else if remaining < 1000 {
            return ["Hähnchen mit Brokkoli (400 kcal)", "Reis mit Gemüse (500 kcal)"]
        } else {
            return ["Ausgewogene Mahlzeit (Protein, Kohlenhydrate, Fett)"]
        }
    }

    // Aktualisiert den Verlaufseintrag für den aktuellen Tag.
    func updateCurrentDayDifference() {
        calorieDifferenceByDate[todayKey] = calorieDifference
    }

    // Speichert Mahlzeiten und Tagesdifferenz des Nutzers in Firestore.
    func saveMeals() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).setData([
            "mealsByDate": mealsByDate,
            "calorieDifferenceByDate": calorieDifferenceByDate
        ], merge: true)
    }

    // Lädt bereits gespeicherte Mahlzeiten und Tagesdifferenzen des Nutzers aus Firestore.
    func loadMeals() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                if let savedMeals = data["mealsByDate"] as? [String: [String: [String]]] {
                    mealsByDate = savedMeals
                }

                if let savedDifferences = data["calorieDifferenceByDate"] as? [String: Int] {
                    calorieDifferenceByDate = savedDifferences
                }
            }

            updateCurrentDayDifference()
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.blue
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 15) {
                    NavigationLink(
                        destination: HistoryView(
                            mealsByDate: mealsByDate,
                            calorieDifferenceByDate: calorieDifferenceByDate
                        )
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.white)
                            Text("Verlauf")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                    }
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 3)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dein Bedarf: \(Int(calories) - consumedCalories) kcal")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            ForEach(["Frühstück", "Mittagessen", "Abendessen", "Snacks"], id: \.self) { meal in
                                if let items = meals[meal], !items.isEmpty {
                                    Text(meal + ":")
                                        .bold()
                                        .foregroundColor(.white)

                                    ForEach(items, id: \.self) { item in
                                        Text("• \(item)")
                                            .foregroundColor(.white)
                                    }
                                }
                            }

                            Text("Mahlzeitenvorschläge:")
                                .bold()
                                .foregroundColor(.white)
                                .padding(.top, 10)

                            ForEach(mealSuggestions, id: \.self) { suggestion in
                                Text("• \(suggestion)")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                calorieDifference > 0
                                ? Color.green.opacity(0.6)
                                : Color.red.opacity(0.6)
                            )

                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 3)

                        VStack(spacing: 8) {
                            Text("Überschuss / Defizit")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            Text("\(abs(calorieDifference)) kcal")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text(calorieDifference > 0 ? "Überschuss" : "Defizit")
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    NavigationLink(destination: InfoDeficitView()) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                            .padding(.vertical, 5)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("Ernährung")
                        .font(.system(size: 28, weight: .bold))
                        .padding()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .frame(maxWidth: .infinity)
                        .frame(height: 330)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .overlay(
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Frühstück")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button("+") {
                                        selectedMeal = "Frühstück"
                                    }
                                    .foregroundColor(.white)
                                }
                                .padding(20)
                                Color.white
                                    .frame(height: 5)
                                    .frame(maxWidth: .infinity)
                                HStack {
                                    Text("Mittagessen")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button("+") {
                                        selectedMeal = "Mittagessen"
                                    }
                                    .foregroundColor(.white)
                                }
                                .padding(20)
                                Color.white
                                    .frame(height: 5)
                                    .frame(maxWidth: .infinity)
                                HStack {
                                    Text("Abendessen")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button("+") {
                                        selectedMeal = "Abendessen"
                                    }
                                    .foregroundColor(.white)
                                }
                                .padding(20)
                                Color.white
                                    .frame(height: 5)
                                    .frame(maxWidth: .infinity)
                                HStack {
                                    Text("Snacks")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button("+") {
                                        selectedMeal = "Snacks"
                                    }
                                    .foregroundColor(.white)
                                }
                                .padding(20)
                            },
                            alignment: .topLeading
                        )
                }
            }
            .onAppear {
                // Holt die Mahlzeiten beim Öffnen der Ansicht.
                loadMeals()
            }
            .onChange(of: mealsByDate) { _, _ in
                // Speichert bei Änderungen der Mahlzeiten auch den aktuellen Tageswert.
                updateCurrentDayDifference()
                saveMeals()
            }
        }
        // Öffnet die Auswahlansicht, sobald eine Mahlzeit ausgewählt wurde.
        .navigationDestination(
            isPresented: Binding(
                get: { selectedMeal != nil },
                set: { if !$0 { selectedMeal = nil } }
            )
        ) {
            AddFoodView(
                selectedMeal: $selectedMeal,
                meals: Binding(
                    get: {
                        mealsByDate[todayKey] ?? [
                            "Frühstück": [],
                            "Mittagessen": [],
                            "Abendessen": [],
                            "Snacks": []
                        ]
                    },
                    set: { newValue in
                        mealsByDate[todayKey] = newValue
                    }
                ),
                mealsByDate: $mealsByDate
            )
            .environmentObject(authVM)
        }
    }
}
