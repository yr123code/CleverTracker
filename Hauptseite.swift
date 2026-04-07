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
    
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()
            VStack(spacing: 15) {
                HStack {
                    Text("Heute \(Date().formatted(date: .abbreviated, time: .omitted))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                        .foregroundColor(.white)
                    
                    Text(authVM.user?.email ?? "Keine Email")
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .padding(.top)
                        .foregroundColor(.white)
                }
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6).opacity(0.1))
                    .stroke(Color.white
                            //Muss noch weitergeschrieben werden
                
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
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                
                Text("Bedarf: \(Int(resultCalories)) kcal")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden(true)
            .onAppear {
                loadData()
            }
        }
    }
    
    // MARK: - Berechnung
    
    func calculateCalories() {
        
        guard let w = Double(weight),
              let h = Double(height),
              let a = Int(age) else { return }
        
        var bmr: Double
        
        if gender == "male" {
            bmr = 10 * w + 6.25 * h - 5 * Double(a) + 5
        } else {
            bmr = 10 * w + 6.25 * h - 5 * Double(a) - 161
        }
        
        let tdee = bmr * activity
        resultCalories = tdee
        
        // speichern in Firebase
        authVM.saveUserData(
            weight: w,
            height: h,
            age: a,
            gender: gender,
            activity: activity,
            calories: tdee
        )
    }
    
    // MARK: - Laden
    
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
}
