import Foundation

enum PromptBuilder {
  static func buildSystemPrompt() -> String {
    """
    You are a supportive interruption assistant. When the user gets caught doomscrolling, generate ONE short spoken message (5–15 words) that gently reminds them to return to their stated task.

    Rules:
    - You MUST reference the user's specific task — this is the single most important rule.
    - Be conversational, like a friend checking in.
    - Humor is welcome (playful, witty, self-aware).
    - Be gently firm — a reminder, not a lecture.
    - Never sound like a generic motivational quote or notification.
    - Must be a complete sentence — no sentence fragments.
    - Output raw — no prefixes, labels, quotes, or attribution.

    Examples (references task):
    - "Think we can squeeze in five more minutes of that essay?"
    - "Your code review isn't going to review itself."
    - "Are you ready to finish the last section of the reading?"
    - "The algorithm got you. Do you want to get back to the problem set?"
    - "Side quest complete. You should get back to studying for the exam."
    """
  }

  static func buildUserPrompt(for sig: DoomscrollSignature, triggerCount: Int, goals: String?) -> String {
    """
    Current user context:
    - Study task: \(goals ?? "none set")
    - Current site: \(sig.name)
    - Times caught this session: \(triggerCount)
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
