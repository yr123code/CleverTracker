import SwiftUI
import FirebaseAuth
import Firebase

// Hauptansicht für die Eingabe der Körperdaten und die Kalorienberechnung.
struct Hauptseite: View {
    // Legt fest, in welchem Schritt des Kalorienrechners sich der Nutzer gerade befindet.
    enum Step: Int, CaseIterable {
        case weight
        case height
        case age
        case gender
        case activity
        case overview
    }

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
    // Liste der Bilder, die oben nacheinander angezeigt werden.
    // Die Namen müssen exakt den Asset-Namen in Assets.xcassets entsprechen.
    private let headerImages = ["SlidesPicture", "SlidePictureNew"]
    // Liste der Bilder für die frühere weiche Wechselanimation unterhalb des Katalogs.
    private let animatedImages = ["HomeIconNew", "logo-colored-icons", "IconApple"]
    // Speichert, welches Bild aktuell sichtbar ist.
    // 0 bedeutet das erste Bild der Liste, 1 das zweite usw.
    @State private var currentHeaderImageIndex = 0
    // Speichert, welches Bild in der unteren Animation gerade sichtbar ist.
    @State private var currentAnimatedImageIndex = 0
    // Steuert die Ein- und Ausblendung des unteren Bildes.
    @State private var animatedImageOpacity = 1.0

    // Ergebnis und Navigation in die Ergebnisansicht.
    @State private var resultCalories: Double = 0
    @State private var navigateToResult = false

    // Steuert das Info-Sheet für das Aktivitätslevel.
    @State private var showInfo = false
    // Speichert, welcher Schritt aktuell angezeigt wird.
    @State private var currentStep: Step = .weight

    // Zugriff auf Auth-Status und Firestore-Funktionen.
    @EnvironmentObject var authVM: AuthViewModel
    // Steuert, welches Eingabefeld gerade den Fokus hat.
    @FocusState private var focusedField: Field?

    private var showsFinalImages: Bool {
        currentStep == .overview
    }

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
                    VStack(){
                        Text("Willkommen!!")
                            .font(.system(size: 25))
                            .foregroundColor(Color.white)
                            .bold()
                            .frame(maxWidth: .infinity,alignment: .top)
                        if showsFinalImages {
                            ZStack {
                                TabView(selection: $currentHeaderImageIndex) {
                                    ForEach(Array(headerImages.enumerated()), id: \.offset) { index, imageName in
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFill()
                                            .tag(index)
                                            .frame(maxWidth: .infinity)
                                            .clipped()
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .automatic))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(16 / 9, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 18))

                                HStack {
                                    Button(action: showPreviousHeaderImage) {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .bold))
                                            .frame(width: 36, height: 36)
                                            .background(Color.black.opacity(0.35))
                                            .clipShape(Circle())
                                    }

                                    Spacer()

                                    Button(action: showNextHeaderImage) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .bold))
                                            .frame(width: 36, height: 36)
                                            .background(Color.black.opacity(0.35))
                                            .clipShape(Circle())
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    Spacer()

                    // CALCULATOR
                    VStack(spacing:18,) {
                        if showsFinalImages {
                            // Frühere weich animierte Bildanzeige unterhalb des neuen Katalogs.
                            Image(animatedImages[currentAnimatedImageIndex])
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 180, maxHeight: 180)
                                .opacity(animatedImageOpacity)
                        }

                        // Zeigt den Inhalt des aktuellen Schritts an.
                        stepContent
                    }
                    Spacer()
                }
                .padding()
                .navigationBarBackButtonHidden(true)
                .onAppear {
                    // Lädt vorhandene Profildaten des Nutzers beim Öffnen der View.
                    loadData()
                }
                .task {
                    // Startet die frühere Bildanimation unterhalb des Katalogs erneut.
                    await startAnimatedImageRotation()
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

    // Springt im Katalog ein Bild nach links.
    func showPreviousHeaderImage() {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentHeaderImageIndex = currentHeaderImageIndex == 0
                ? headerImages.count - 1
                : currentHeaderImageIndex - 1
        }
    }

    // Springt im Katalog ein Bild nach rechts.
    func showNextHeaderImage() {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentHeaderImageIndex = (currentHeaderImageIndex + 1) % headerImages.count
        }
    }

    // Lässt das untere Bild dauerhaft weich zwischen mehreren Bildern wechseln.
    func startAnimatedImageRotation() async {
        guard animatedImages.count > 1 else { return }

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2.5))

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animatedImageOpacity = 0
                }
            }

            try? await Task.sleep(for: .seconds(0.6))

            await MainActor.run {
                currentAnimatedImageIndex = (currentAnimatedImageIndex + 1) % animatedImages.count

                withAnimation(.easeInOut(duration: 0.6)) {
                    animatedImageOpacity = 1
                }
            }
        }
    }

    // Zeigt je nach Schritt nur das aktuell relevante Eingabeelement an.
    @ViewBuilder
    var stepContent: some View {
        switch currentStep {
        case .weight:
            // Erster Schritt: Eingabe des Körpergewichts.
            TextField("Gewicht (kg)", text: $weight)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .weight)

            Button("Weiter") {
                // Schließt die Tastatur, speichert den aktuellen Stand und springt zum nächsten Schritt.
                focusedField = nil
                saveCurrentProgress()
                currentStep = .height
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.blue)
            .disabled(weight.isEmpty)

        case .height:
            // Zweiter Schritt: Eingabe der Körpergröße.
            TextField("Größe (cm)", text: $height)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .height)

            stepButtons(back: .weight, next: .age, disableNext: height.isEmpty)

        case .age:
            // Dritter Schritt: Eingabe des Alters.
            TextField("Alter", text: $age)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .age)

            stepButtons(back: .height, next: .gender, disableNext: age.isEmpty)

        case .gender:
            // Vierter Schritt: Auswahl des Geschlechts.
            Picker("Geschlecht", selection: $gender) {
                Text("Mann").tag("male")
                Text("Frau").tag("female")
            }
            .pickerStyle(.segmented)

            stepButtons(back: .age, next: .activity, disableNext: false)

        case .activity:
            // Fünfter Schritt: Auswahl des Aktivitätslevels über einen Slider.
            Slider(value: $activity, in: 1.2...1.9, step: 0.1)

            HStack {
                Text("Aktivität: \(activity, specifier: "%.1f")")
                    .foregroundColor(.white)

                Button(action: {
                    // Öffnet ein Infofenster zur Erklärung des Aktivitätslevels.
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

            HStack(spacing: 12) {
                Button("Zurück") {
                    // Springt wieder zum vorherigen Schritt zurück.
                    currentStep = .gender
                }
                .buttonStyle(.bordered)

                Button("Abschließen") {
                    // Berechnet am Ende den Kalorienbedarf und zeigt danach die Übersichtsstufe an.
                    calculateCalories()
                    saveCurrentProgress()
                    currentStep = .overview
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.blue)
            }

        case .overview:
            // Letzter Schritt: Zeigt das berechnete Ergebnis und den Einstieg in die Übersicht.
            Text("Bedarf: \(Int(resultCalories)) kcal")
                .font(.title2)
                .bold()
                .foregroundColor(.white)

            Button("Zu meiner Übersicht") {
                // Falls noch keine Berechnung vorliegt, wird sie beim Öffnen der Übersicht nachgeholt.
                if resultCalories == 0 {
                    calculateCalories()
                }
                // Öffnet die Ergebnisansicht.
                navigateToResult = true
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .foregroundColor(.blue)
            .cornerRadius(12)
        }
    }

    // Gemeinsame Zurück-/Weiter-Buttons für die Zwischenschritte.
    @ViewBuilder
    func stepButtons(back: Step, next: Step, disableNext: Bool) -> some View {
        HStack(spacing: 12) {
            Button("Zurück") {
                // Entfernt den Tastaturfokus und springt einen Schritt zurück.
                focusedField = nil
                currentStep = back
            }
            .buttonStyle(.bordered)

            Button("Weiter") {
                // Entfernt den Tastaturfokus, speichert Zwischendaten und springt einen Schritt weiter.
                focusedField = nil
                saveCurrentProgress()
                currentStep = next
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.blue)
            .disabled(disableNext)
        }
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

    // Speichert bereits eingegebene Zwischenschritte des Onboardings in Firebase.
    func saveCurrentProgress() {
        authVM.saveOnboardingProgress(
            weight: Double(weight),
            height: Double(height),
            age: Int(age),
            gender: gender,
            activity: activity,
            calories: resultCalories
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

                if let g = data["gender"] as? String {
                    gender = g
                }

                if let act = data["activityLevel"] as? Double {
                    activity = act
                }

                if let c = data["calories"] as? Double {
                    resultCalories = c
                }

                // Wenn bereits Profildaten existieren, wird direkt der Übersichts-Button gezeigt.
                if !weight.isEmpty && !height.isEmpty && !age.isEmpty {
                    currentStep = .overview
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
