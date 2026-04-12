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
                        
                        Text("Aktivität: \(activity, specifier: "%.1f")")
                            .foregroundColor(.white)
                        
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
                        Text("Dein Bedarf: \(Int(calories)) kcal")
                            .font(.system(size: 28, weight: .bold))
                            .bold()
                            .foregroundColor(.white)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
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
                            Text("Frühstück")
                                .font(.system(size:20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(20)
                            Color.white
                                .frame(height: 5)
                                .frame(maxWidth: .infinity)
                            Text("Mittagessen")
                                .font(.system(size:20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(20)
                            Color.white
                                .frame(height: 5)
                                .frame(maxWidth: .infinity)
                            Text("Abendessen")
                                .font(.system(size:20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(20)
                            Color.white
                                .frame(height: 5)
                                .frame(maxWidth: .infinity)
                            Text("Snacks")
                                .font(.system(size:20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(20)
                        },
                        alignment: .topLeading
                    )
            }
        }
    }
}
