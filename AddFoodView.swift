import SwiftUI

// Liste zur Auswahl von Lebensmitteln für eine bestimmte Mahlzeit.
struct AddFoodView: View {
    // Übergabe der aktuell ausgewählten Mahlzeit aus der Ergebnisansicht.
    @Binding var selectedMeal: String?
    // Heutige Mahlzeiten des aktuellen Tages.
    @Binding var meals: [String: [String]]
    // Gesamte Mahlzeitenhistorie über mehrere Tage.
    @Binding var mealsByDate: [String: [String: [String]]]
    // Suchtext für das Filtern der Lebensmittel.
    @State private var searchText = ""

    // Feste Liste vordefinierter Lebensmittel mit Kalorienangaben.
    var allFoods: [(name: String, kcal: Int)] {
        [
            ("Banane", 100),
            ("Reis (gekocht, Handvoll)", 130),
            ("Hähnchenbrust (100g)", 165),
            ("Walnüsse Eine Handvoll (30g)", 200),
            ("Magerquark (100g)", 67),
            ("Ei (M)", 75),
            ("Avocado (halbe)", 120),
            ("Teelöffel Butter", 40),
            ("Teelöffel Olivenöl", 45),
            ("Schokolade (Riegel)", 230),
            ("Franzbrötchen 1 Brötchen (80g)", 280),
            ("Butter 1 Aufstrich (10g)", 74),
            ("Latte Macchiato 1 Glas (300ml)", 123),
            ("Sesambrötchen 1 Brot (60g)", 172),
            ("Sucuk 1 Wurst (80g)", 272),
            ("Apfel (1 Stück, mittel)", 80),
            ("Gurke (1 Stück, mittel)", 30),
            ("Tomate (1 Stück, mittel)", 25),
            ("Gouda Käse (1 Scheibe)", 110),
            ("Lachs (1 Filet, ca. 120g)", 200),
            ("Kartoffeln (1 Portion, gekocht ca. 200g)", 150),
            ("Haferflocken (1 Schale, ca. 50g)", 185),
            ("Vollkornbrot (1 Scheibe)", 110),
            ("Naturjoghurt (1 Becher, ca. 150g)", 95),
            ("Milch (1 Glas, ca. 250ml)", 155),
            ("Pasta (gekocht, 1 Teller ca. 200g)", 300),
            ("Rinderhackfleisch (100g, gebraten)", 250),
            ("Thunfisch (1 Dose in Wasser, abgetropft)", 130),
            ("Müsli (1 Schale ca. 60g)", 230),
            ("Pizza Margherita (1 Stück)", 250),
            ("Karotte (1 Stück, mittel)", 40),
            ("Orange (1 Stück, mittel)", 70),
            ("Erdnussbutter (1 EL ca. 15g)", 95),
            ("Mozzarella (1 Kugel ca. 125g)", 280),
            ("Brötchen (1 Stück, hell)", 160)
        ]
    }

    // Filtert die Lebensmittelliste anhand der Sucheingabe.
    var filteredFoods: [(name: String, kcal: Int)] {
        if searchText.isEmpty {
            return allFoods
        } else {
            return allFoods.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Lebensmittel auswählen")
                .font(.largeTitle)

            List {
                ForEach(filteredFoods, id: \.name) { food in
                    FoodRowView(
                        name: food.name,
                        kcalPerUnit: food.kcal,
                        selectedMeal: $selectedMeal,
                        meals: $meals,
                        mealsByDate: $mealsByDate
                    )
                }
            }
            .searchable(text: $searchText, prompt: "Lebensmittel suchen")
        }
    }
}
