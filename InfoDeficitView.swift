import SwiftUI

// Zusätzliche Infoseite zum Kalorienüberschuss und -defizit.
struct InfoDeficitView: View {
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kalorien Info")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)

                        Text("So kannst du Überschuss und Defizit besser einordnen.")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 16) {
                        Label("Grundregel", systemImage: "scalemass")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("1 kg Körperfett entspricht ungefähr 7000 kcal.")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.14))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        Label("Beispiel", systemImage: "chart.bar.doc.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Wenn du täglich etwa 200 kcal im Überschuss oder Defizit bist, ergibt das in einer Woche:")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text("200 x 7 = 1400 kcal")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)

                                Text("pro Woche")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.14))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wichtig")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Gewichtsveränderungen passieren nicht von heute auf morgen. Entscheidend ist eher dein Durchschnitt über mehrere Tage als ein einzelner Tag.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.15))
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Defizit Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}
