import Testing
@testable import HeyYou

@Test("Build prompt includes site name and goals")
func promptIncludesSiteAndGoals() {
  let sig = DoomscrollSignature(name: "Reddit", patterns: ["Reddit"], threshold: 30, repeatThreshold: 15)
  let prompt = PromptBuilder.buildPrompt(for: sig, triggerCount: 2, goals: "work on project")
  #expect(prompt.contains("Reddit"))
  #expect(prompt.contains("work on project"))
  #expect(prompt.contains("Times caught this session: 2"))
}

@Test("Build prompt with nil goals")
func promptWithNilGoals() {
  let sig = DoomscrollSignature(name: "X", patterns: ["X"], threshold: 30, repeatThreshold: 15)
  let prompt = PromptBuilder.buildPrompt(for: sig, triggerCount: 0, goals: nil)
  #expect(prompt.contains("none set"))
  #expect(prompt.contains("Times caught this session: 0"))
}

@Test("Fallback message first trigger with goals")
func fallbackFirstWithGoals() {
  let sig = DoomscrollSignature(name: "Reddit", patterns: ["Reddit"], threshold: 30, repeatThreshold: 15)
  let msg = PromptBuilder.fallbackMessage(for: sig, triggerCount: 1, goals: "write code")
  #expect(msg == "Hey you. You said you wanted to write code, but you're on Reddit.")
}

@Test("Fallback message first trigger without goals")
func fallbackFirstNoGoals() {
  let sig = DoomscrollSignature(name: "Twitter", patterns: ["Twitter"], threshold: 30, repeatThreshold: 15)
  let msg = PromptBuilder.fallbackMessage(for: sig, triggerCount: 1, goals: nil)
  #expect(msg == "Hey you. You're on Twitter. Should you be doing something else?")
}

@Test("Fallback message repeated trigger with goals")
func fallbackRepeatWithGoals() {
  let sig = DoomscrollSignature(name: "Instagram", patterns: ["Instagram"], threshold: 20, repeatThreshold: 10)
  let msg = PromptBuilder.fallbackMessage(for: sig, triggerCount: 3, goals: "meditate")
  #expect(msg == "Hey you. That's the 3rd time. Remember: meditate.")
}

@Test("Fallback message repeated trigger without goals")
func fallbackRepeatNoGoals() {
  let sig = DoomscrollSignature(name: "TikTok", patterns: ["TikTok"], threshold: 20, repeatThreshold: 10)
  let msg = PromptBuilder.fallbackMessage(for: sig, triggerCount: 5, goals: nil)
  #expect(msg == "Hey you. That's the 5th time on TikTok today.")
}

@Test("Ordinal suffixes are correct")
func ordinalSuffixes() {
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 30, repeatThreshold: 15)
  #expect(PromptBuilder.fallbackMessage(for: sig, triggerCount: 2, goals: "work").contains("2nd"))
  #expect(PromptBuilder.fallbackMessage(for: sig, triggerCount: 3, goals: "work").contains("3rd"))
  #expect(PromptBuilder.fallbackMessage(for: sig, triggerCount: 4, goals: nil).contains("4th"))
  #expect(PromptBuilder.fallbackMessage(for: sig, triggerCount: 11, goals: nil).contains("11th"))
  #expect(PromptBuilder.fallbackMessage(for: sig, triggerCount: 12, goals: nil).contains("12th"))
  #expect(PromptBuilder.fallbackMessage(for: sig, triggerCount: 13, goals: nil).contains("13th"))
  #expect(PromptBuilder.fallbackMessage(for: sig, triggerCount: 21, goals: nil).contains("21st"))
  #expect(PromptBuilder.fallbackMessage(for: sig, triggerCount: 22, goals: nil).contains("22nd"))
  #expect(PromptBuilder.fallbackMessage(for: sig, triggerCount: 23, goals: nil).contains("23rd"))
  #expect(PromptBuilder.fallbackMessage(for: sig, triggerCount: 101, goals: "work").contains("101st"))
}
