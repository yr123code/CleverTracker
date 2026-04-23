import SwiftUI

// Kleines Info-Sheet zur Bedeutung des Aktivitätslevels.
struct InfoView: View {
    @Environment(\.dismiss) var dismiss

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
}
