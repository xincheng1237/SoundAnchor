import CoreAudio
import Foundation

struct AudioDevice: Hashable {
    let id: AudioObjectID
    let uid: String
    let name: String
    let transportType: UInt32
    let inputChannels: Int
    let outputChannels: Int

    var hasInput: Bool { inputChannels > 0 }
    var hasOutput: Bool { outputChannels > 0 }

    var isBuiltIn: Bool {
        transportType == kAudioDeviceTransportTypeBuiltIn
    }

    var isBluetooth: Bool {
        transportType == kAudioDeviceTransportTypeBluetooth ||
            transportType == kAudioDeviceTransportTypeBluetoothLE
    }
}

enum ProtectionState: Equatable {
    case active
    case corrected
    case waitingForBluetooth
    case disabled
    case targetUnavailable
    case error(String)
}

struct AudioSnapshot: Equatable {
    let protectionState: ProtectionState
    let currentInputName: String
    let currentOutputName: String
    let anchoredInputName: String
    let bluetoothOutputActive: Bool
    let correctionCount: Int
    let lastCorrectionDate: Date?

    static let starting = AudioSnapshot(
        protectionState: .disabled,
        currentInputName: L10n.text("status.reading_short"),
        currentOutputName: L10n.text("status.reading_short"),
        anchoredInputName: L10n.text("input.auto_builtin"),
        bluetoothOutputActive: false,
        correctionCount: 0,
        lastCorrectionDate: nil
    )
}
