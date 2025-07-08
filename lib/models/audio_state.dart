enum AudioState {
  initial, // User sees the "Add component" plus button
  addMicrophone, // User sees the microphone button after tapping "Add component"
  recording, // User is currently recording
  recorded, // User has stopped recording and can play/delete
}