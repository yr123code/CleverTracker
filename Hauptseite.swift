import SwiftUI
import FirebaseAuth
import Firebase

// Hauptansicht für die Eingabe der Körperdaten und die Kalorienberechnung.
struct Hauptseite: View {
    // Definiert die Eingabefelder, damit der Fokus gezielt gesetzt oder entfernt werden kann.
    enum Field {
        case weight
        case height
        case age
    }
    
    // Eingaben für den Kalorienrechner.
    @State private var weight = ""
    @State private var height = ""
    @State private var age = ""
    @State private var gender = "male"
    @State private var activity: Double = 1.2
    
    // Ergebnis und Navigation in die Ergebnisansicht.
    @State private var resultCalories: Double = 0
    @State private var navigateToResult = false
    
    // Steuert das Info-Sheet für das Aktivitätslevel.
    @State private var showInfo = false
    @State private var showInfoFood = false
    
    // Zugriff auf Auth-Status und Firestore-Funktionen.
    @EnvironmentObject var authVM: AuthViewModel
    // Steuert, welches Eingabefeld gerade den Fokus hat.
    @FocusState private var focusedField: Field?

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
                            // Verknüpft das Gewichtsfeld mit dem Fokusstatus der Tastatur.
                            .focused($focusedField, equals: .weight)
                        
                        TextField("Größe (cm)", text: $height)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            // Verknüpft das Größenfeld mit dem Fokusstatus der Tastatur.
                            .focused($focusedField, equals: .height)
                        
                        TextField("Alter", text: $age)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            // Verknüpft das Altersfeld mit dem Fokusstatus der Tastatur.
                            .focused($focusedField, equals: .age)
                        
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
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Fertig") {
                            // Entfernt den Fokus vom aktiven Feld und schließt damit die Tastatur.
                            focusedField = nil
                        }
                    }
                }
                // Navigation zum ErgebnisView.
                .navigationDestination(isPresented: $navigateToResult) {
                    ErgebnisView(calories: resultCalories)
                }
            }
        }
        .background(Color.blue.ignoresSafeArea())
    }

    // MARK: Berechnung
    // Berechnet den täglichen Kalorienbedarf und speichert das Ergebnis in Firestore.
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
    // Lädt bereits gespeicherte Nutzerdaten und füllt damit die Eingabefelder.
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
    
    // Meldet den aktuellen Nutzer ab und setzt den lokalen Auth-Zustand zurück.
    func signOut() {
        do {
            try Auth.auth().signOut()
            authVM.user = nil
        } catch {
            print("Fehler beim Logout: \(error.localizedDescription)")
        }
    }
}

#Preview {
    Hauptseite()
        .environmentObject(AuthViewModel())
}
