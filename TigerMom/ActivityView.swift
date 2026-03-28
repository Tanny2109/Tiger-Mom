import SwiftUI

struct ActivityView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Activity")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 20)

            VStack(spacing: 16) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: 0xF59E0B).opacity(0.3))
                Text("Activity")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                Text("Activity log and timeline will appear here.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.25))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
