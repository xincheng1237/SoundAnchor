import CoreAudio

enum ProtectionDecision: Equatable {
    case disabled
    case waitingForBluetooth
    case enforce
    case active
}

enum ProtectionPolicy {
    static func decision(
        enabled: Bool,
        force: Bool,
        bluetoothOnly: Bool,
        bluetoothOutputActive: Bool,
        currentInputID: AudioObjectID?,
        targetInputID: AudioObjectID
    ) -> ProtectionDecision {
        guard enabled || force else {
            return .disabled
        }
        guard force || !bluetoothOnly || bluetoothOutputActive else {
            return .waitingForBluetooth
        }
        return currentInputID == targetInputID ? .active : .enforce
    }
}
