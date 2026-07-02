import SwiftUI

struct GoalChipView: View {
  let goal: String
  let tint: Color
  var showPrefix: Bool = true

  var body: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(tint)
        .frame(width: 5, height: 5)

      if showPrefix {
        (Text("Goal: ")
          .font(.system(size: 12))
          .foregroundColor(.white.opacity(0.4))
          + Text(goal)
          .font(.system(size: 12))
          .foregroundColor(.white.opacity(0.6))
        )
      } else {
        Text(goal)
          .font(.system(size: 12))
          .foregroundColor(.white.opacity(0.8))
      }
    }
    .lineLimit(1...3)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.white.opacity(0.06))
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(.white.opacity(0.08), lineWidth: 1)
    )
  }
}
