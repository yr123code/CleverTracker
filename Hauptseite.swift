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
    
    @State private var selectedMeal: String? = nil
    @State private var meals: [String: [String]] = [
        "Frühstück": [],
        "Mittagessen": [],
        "Abendessen": [],
        "Snacks": []
    ]
    
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
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.blue
                .ignoresSafeArea()
            VStack(spacing:20) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .overlay(
                        VStack {
                            Text("Dein Bedarf: \(Int(calories) - consumedCalories) kcal")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            ForEach(meals.values.flatMap { $0 }, id: \.self) { item in
                                Text("• \(item)")
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 125)
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
            NavigationLink(
                destination: AddFoodView(selectedMeal: $selectedMeal, meals: $meals),
                isActive: Binding(
                    get: { selectedMeal != nil },
                    set: { if !$0 { selectedMeal = nil } }
                )
            ) {
                EmptyView()
            }
        }
    }
}

struct AddFoodView: View {
    @Binding var selectedMeal: String?
    @Binding var meals: [String: [String]]
    @State private var bananaCount = 1

    var body: some View {
        VStack(spacing: 20) {
            Text("Lebensmittel auswählen")
                .font(.largeTitle)

            List {
                HStack {
                    Text("Banane")

                    Spacer()

                    Stepper(value: $bananaCount, in: 1...10) {
                        Text("\(bananaCount)")
                    }

                    Button("✓") {
                        let kcal = bananaCount * 100
                        let text = "Banane x\(bananaCount) = \(kcal) kcal"

                        if let meal = selectedMeal {
                            meals[meal, default: []].append(text)
                        }

                        selectedMeal = nil
                    }
                    .foregroundColor(.green)
                }
            }
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
