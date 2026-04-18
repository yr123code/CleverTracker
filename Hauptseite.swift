import SwiftUI
import FirebaseAuth
import Firebase

struct Hauptseite: View {
    
    @State private var weight = ""
    @State private var height = ""
    @State private var age = ""
    @State private var gender = "male"
    @State private var activity: Double = 1.2
    @State private var resultCalories: Double = 0
    @State private var navigateToResult = false
    @State private var showInfo = false
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.blue
                    .ignoresSafeArea()
                VStack(spacing: 15) {
                    // HEADER
                    HStack {
                        Text("Heute \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 10) {
                            Button(action: {
                                signOut()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "power")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            
                            Text(authVM.user?.email ?? "Keine Email")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top)
                    }
                    
                    Spacer()
                    
                    
                    // CALCULATOR
                    VStack(spacing: 15) {
                        HStack{
                            Button("Zu meiner Übersicht"){
                                navigateToResult = true
                            }
                            .padding()
                            .foregroundStyle(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                        }
                        
                        Text("Kalorien Rechner")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        
                        TextField("Gewicht (kg)", text: $weight)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                        
                        TextField("Größe (cm)", text: $height)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                        
                        TextField("Alter", text: $age)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        
                        Picker("Geschlecht", selection: $gender) {
                            Text("Mann").tag("male")
                            Text("Frau").tag("female")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Slider(value: $activity, in: 1.2...1.9, step: 0.1)
                        
                        HStack{
                            Text("Aktivität: \(activity, specifier: "%.1f")")
                                .foregroundColor(.white)
                            Button(action: {
                                showInfo = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 24, height: 24)
                                    Image(systemName: "info")
                                        .foregroundColor(.white)
                                        .font(.system(size: 12, weight: .bold))
                                }
                            }
                        }
                        .sheet(isPresented: $showInfo) {
                            InfoView()
                        }
                        .presentationBackground(.clear)
                        Button("Kalorien berechnen") {
                            calculateCalories()
                            navigateToResult = true
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        
                        Text("Bedarf: \(Int(resultCalories)) kcal")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding()
                .navigationBarBackButtonHidden(true)
                .onAppear {
                    loadData()
                }
            }
            // Navigation zum ErgebnisView
            NavigationLink("", isActive: $navigateToResult) {
                ErgebnisView(calories: resultCalories)
                    .environmentObject(authVM)
            }
        }
    .background(Color.blue.ignoresSafeArea())
    }

    // MARK: Berechnung
    func calculateCalories() {
        guard let w = Double(weight),
              let h = Double(height),
              let a = Int(age) else { return }

        let bmr: Double

        if gender == "male" {
            bmr = 10 * w + 6.25 * h - 5 * Double(a) + 5
        } else {
            bmr = 10 * w + 6.25 * h - 5 * Double(a) - 161
        }

        let tdee = bmr * activity
        resultCalories = tdee

        authVM.saveUserData(
            weight: w,
            height: h,
            age: a,
            gender: gender,
            activity: activity,
            calories: tdee
        )
    }

    // MARK: - LOAD
    func loadData() {
        authVM.loadUserData { data in
            if let data = data {
                
                if let w = data["weight"] as? Double {
                    weight = String(w)
                }

                if let h = data["height"] as? Double {
                    height = String(h)
                }

                if let a = data["age"] as? Int {
                    age = String(a)
                }

                if let c = data["calories"] as? Double {
                    resultCalories = c
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            authVM.user = nil
        } catch {
            print("Fehler beim Logout: \(error.localizedDescription)")
        }
    }
}

// MARK: - RESULT VIEW
struct ErgebnisView: View {
    var calories: Double
    
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var selectedMeal: String? = nil
    @State private var mealsByDate: [String: [String: [String]]] = [:]
    
    var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
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
    
    func saveMeals() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).setData([
            "mealsByDate": mealsByDate
        ], merge: true)
    }

    func loadMeals() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data(),
               let saved = data["mealsByDate"] as? [String: [String: [String]]] {
                mealsByDate = saved
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.blue
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing:20) {
                    NavigationLink(destination: HistoryView(mealsByDate: mealsByDate)) {
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

                            ForEach(["Frühstück","Mittagessen","Abendessen","Snacks"], id: \.self) { meal in
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
                    .padding()
                    Text("Ernährung")
                        .font(.system(size:28, weight: .bold))
                        .padding()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    RoundedRectangle(cornerRadius:20)
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
                                        .font(.system(size:20, weight: .bold))
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
                                        .font(.system(size:20, weight: .bold))
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
                                        .font(.system(size:20, weight: .bold))
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
                                        .font(.system(size:20, weight: .bold))
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
                loadMeals()
            }
            NavigationLink(
                destination: AddFoodView(
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
                    .environmentObject(authVM),
                isActive: Binding(
                    get: { selectedMeal != nil },
                    set: { if !$0 { selectedMeal = nil } }
                )
            ) {
                EmptyView()
            }
            .opacity(0)
            .allowsHitTesting(false)
        }
    }
}

struct AddFoodView: View {
    @Binding var selectedMeal: String?
    @Binding var meals: [String: [String]]
    @Binding var mealsByDate: [String: [String: [String]]]

    var body: some View {
        VStack(spacing: 20) {
            Text("Lebensmittel auswählen")
                .font(.largeTitle)

            List {
                FoodRowView(name: "Banane", kcalPerUnit: 100, selectedMeal: $selectedMeal, meals: $meals, mealsByDate: $mealsByDate)
                FoodRowView(name: "Reis (gekocht, Handvoll)", kcalPerUnit: 130, selectedMeal: $selectedMeal, meals: $meals, mealsByDate: $mealsByDate)
                FoodRowView(name: "Hähnchenbrust (150g)", kcalPerUnit: 250, selectedMeal: $selectedMeal, meals: $meals, mealsByDate: $mealsByDate)
                FoodRowView(name: "Brokkoli (Portion)", kcalPerUnit: 50, selectedMeal: $selectedMeal, meals: $meals, mealsByDate: $mealsByDate)
                FoodRowView(name: "Avocado (halbe)", kcalPerUnit: 120, selectedMeal: $selectedMeal, meals: $meals, mealsByDate: $mealsByDate)
                FoodRowView(name: "Schokolade (Riegel)", kcalPerUnit: 230, selectedMeal: $selectedMeal, meals: $meals, mealsByDate: $mealsByDate)
            }
        }
    }
}

struct FoodRowView: View {
    let name: String
    let kcalPerUnit: Int
    @Binding var selectedMeal: String?
    @Binding var meals: [String: [String]]
    @Binding var mealsByDate: [String: [String: [String]]]
    @State private var count = 1

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Stepper(value: $count, in: 1...10) {
                Text("\(count)")
            }
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
struct InfoView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Aktivitätslevel Info")
                    .font(.headline)
                    .bold()

                Text("1.2 = wenig Bewegung\n1.5 = moderat aktiv\n1.9 = sehr aktiv")
                    .multilineTextAlignment(.center)

                Button("Schließen") {
                    dismiss()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .frame(maxWidth: 300)
        }
        .presentationBackground(.clear)
    }
    

    @Environment(\.dismiss) var dismiss
}
#Preview {
    Hauptseite()
        .environmentObject(AuthViewModel())
}

struct HistoryView: View {
    var mealsByDate: [String: [String: [String]]]

    var body: some View {
        List {
            ForEach(mealsByDate.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date)) {
                    let meals = mealsByDate[date] ?? [:]

                    ForEach(["Frühstück","Mittagessen","Abendessen","Snacks"], id: \.self) { meal in
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

