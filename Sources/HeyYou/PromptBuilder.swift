import Foundation

enum PromptBuilder {
  static func buildPrompt(for sig: DoomscrollSignature, triggerCount: Int, goals: String?) -> String {
    return """
    You are HeyYou, a Mac app that catches users doomscrolling. You speak conversationally, like a friend. Keep responses extremely short — one sentence, ideally under 12 words.

    Good: "Hey — Reddit isn't going to help with that project."
    Good: "Shouldn't you be in Xcode right now?"
    Bad: "I noticed you're scrolling through Reddit again when you said you wanted to work on your project. Remember that you have a goal to finish that feature today."

    User context:
    - Session goals: \(goals ?? "none set")
    - Current site: \(sig.name)
    - Times caught this session: \(triggerCount)

    Respond conversationally:
    """
  }

  static func fallbackMessage(for sig: DoomscrollSignature, triggerCount: Int, goals: String?) -> String {
    if triggerCount <= 1, let goals {
      return "Hey you. You said you wanted to \(goals), but you're on \(sig.name)."
    } else if triggerCount <= 1 {
      return "Hey you. You're on \(sig.name). Should you be doing something else?"
    } else if let goals {
      return "Hey you. That's the \(ordinal(triggerCount)) time. Remember: \(goals)."
    } else {
      return "Hey you. That's the \(ordinal(triggerCount)) time on \(sig.name) today."
    }
  }

  private static func ordinal(_ n: Int) -> String {
    let suffixes = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"]
    let mod100 = n % 100
    let suffix: String
    if 11 <= mod100 && mod100 <= 13 {
      suffix = "th"
    } else {
      suffix = suffixes[n % 10]
    }
    return "\(n)\(suffix)"
  }
}
