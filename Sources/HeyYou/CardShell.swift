import SwiftUI

struct CardShell: ViewModifier {
  func body(content: Content) -> some View {
    content
      .frame(width: 300)
      .background(.ultraThinMaterial)
      .background(Color(red: 0.11, green: 0.118, blue: 0.141).opacity(0.88))
      .cornerRadius(20)
      .overlay(
        RoundedRectangle(cornerRadius: 20)
          .stroke(
            LinearGradient(
              colors: [
                .white.opacity(0.12),
                .white.opacity(0.02),
                .white.opacity(0.06)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 1
          )
      )
  }
}

extension View {
  func cardShell() -> some View {
    modifier(CardShell())
  }
}
