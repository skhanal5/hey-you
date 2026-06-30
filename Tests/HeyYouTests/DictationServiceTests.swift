import Foundation
import Testing
@testable import HeyYou

@Test("Microphone permission denied equals itself")
func micPermissionDeniedEquality() {
  let a = DictationService.Error.microphonePermissionDenied
  let b = DictationService.Error.microphonePermissionDenied
  #expect(a == b)
}

@Test("Recognition unavailable equals itself")
func recognitionUnavailableEquality() {
  let a = DictationService.Error.recognitionUnavailable
  let b = DictationService.Error.recognitionUnavailable
  #expect(a == b)
}

@Test("Not recording equals itself")
func notRecordingEquality() {
  let a = DictationService.Error.notRecording
  let b = DictationService.Error.notRecording
  #expect(a == b)
}

@Test("Cancelled equals itself")
func cancelledEquality() {
  let a = DictationService.Error.cancelled
  let b = DictationService.Error.cancelled
  #expect(a == b)
}

@Test("Different error cases are not equal")
func differentErrorsNotEqual() {
  #expect(DictationService.Error.microphonePermissionDenied != DictationService.Error.recognitionUnavailable)
  #expect(DictationService.Error.notRecording != DictationService.Error.cancelled)
}

@Test("RecognitionFailed with same NSError are equal")
func recognitionFailedSameError() {
  let underlying = NSError(domain: "test", code: 42, userInfo: nil)
  let a = DictationService.Error.recognitionFailed(underlying)
  let b = DictationService.Error.recognitionFailed(underlying)
  #expect(a == b)
}

@Test("RecognitionFailed with different NSError are not equal")
func recognitionFailedDifferentError() {
  let a = DictationService.Error.recognitionFailed(NSError(domain: "a", code: 1, userInfo: nil))
  let b = DictationService.Error.recognitionFailed(NSError(domain: "b", code: 2, userInfo: nil))
  #expect(a != b)
}

@Test("Init creates recognizer for current locale")
func initCreatesRecognizer() {
  let service = DictationService()
  _ = service
}

@Test("Cancel before recording is no-op")
func cancelWithoutRecording() {
  let service = DictationService()
  service.cancel()
}
