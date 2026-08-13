import Testing
@testable import SoundAnchor

@Test func disabledProtectionDoesNothing() {
    #expect(
        ProtectionPolicy.decision(
            enabled: false,
            force: false,
            bluetoothOnly: true,
            bluetoothOutputActive: true,
            currentInputID: 2,
            targetInputID: 1
        ) == .disabled
    )
}

@Test func bluetoothScopeWaitsForBluetoothOutput() {
    #expect(
        ProtectionPolicy.decision(
            enabled: true,
            force: false,
            bluetoothOnly: true,
            bluetoothOutputActive: false,
            currentInputID: 2,
            targetInputID: 1
        ) == .waitingForBluetooth
    )
}

@Test func mismatchedInputIsCorrectedWhenBluetoothIsActive() {
    #expect(
        ProtectionPolicy.decision(
            enabled: true,
            force: false,
            bluetoothOnly: true,
            bluetoothOutputActive: true,
            currentInputID: 2,
            targetInputID: 1
        ) == .enforce
    )
}

@Test func manualRepairOverridesDisabledAndBluetoothScope() {
    #expect(
        ProtectionPolicy.decision(
            enabled: false,
            force: true,
            bluetoothOnly: true,
            bluetoothOutputActive: false,
            currentInputID: 2,
            targetInputID: 1
        ) == .enforce
    )
}

@Test func matchingInputStaysActive() {
    #expect(
        ProtectionPolicy.decision(
            enabled: true,
            force: false,
            bluetoothOnly: false,
            bluetoothOutputActive: false,
            currentInputID: 1,
            targetInputID: 1
        ) == .active
    )
}
