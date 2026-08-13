import CoreAudio
import Foundation

final class CoreAudioController {
    typealias StateHandler = (AudioSnapshot, [AudioDevice]) -> Void

    var onStateChange: StateHandler?

    private let preferences: Preferences
    private let systemObject = AudioObjectID(kAudioObjectSystemObject)
    private let queue = DispatchQueue(label: "app.soundanchor.core-audio", qos: .userInitiated)
    private var listenerRegistrations: [(AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []
    private var isStarted = false
    private var correctionCount = 0
    private var lastCorrectionDate: Date?
    private var retryGeneration = 0

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    deinit {
        stop()
    }

    func start() {
        queue.async { [weak self] in
            guard let self, !self.isStarted else { return }
            self.isStarted = true
            self.installListeners()
            self.evaluate(reason: "启动", force: false, scheduleRetries: true)
        }
    }

    func stop() {
        queue.sync {
            guard isStarted else { return }
            for (storedAddress, block) in listenerRegistrations {
                var address = storedAddress
                AudioObjectRemovePropertyListenerBlock(systemObject, &address, queue, block)
            }
            listenerRegistrations.removeAll()
            isStarted = false
        }
    }

    func setProtectionEnabled(_ enabled: Bool) {
        preferences.isEnabled = enabled
        queue.async { [weak self] in
            self?.evaluate(reason: "保护开关", force: false, scheduleRetries: false)
        }
    }

    func setBluetoothOnly(_ bluetoothOnly: Bool) {
        preferences.protectsOnlyWithBluetoothOutput = bluetoothOnly
        queue.async { [weak self] in
            self?.evaluate(reason: "保护条件", force: false, scheduleRetries: true)
        }
    }

    func setAnchoredInput(uid: String) {
        preferences.anchoredInputUID = uid
        queue.async { [weak self] in
            self?.evaluate(reason: "锚定设备", force: true, scheduleRetries: true)
        }
    }

    func repairNow() {
        queue.async { [weak self] in
            self?.evaluate(reason: "手动修复", force: true, scheduleRetries: true)
        }
    }

    private func installListeners() {
        let selectors: [AudioObjectPropertySelector] = [
            kAudioHardwarePropertyDefaultInputDevice,
            kAudioHardwarePropertyDefaultOutputDevice,
            kAudioHardwarePropertyDevices
        ]

        for selector in selectors {
            var address = AudioObjectPropertyAddress(
                mSelector: selector,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
                self?.evaluate(reason: "音频设备变化", force: false, scheduleRetries: true)
            }
            if AudioObjectAddPropertyListenerBlock(systemObject, &address, queue, block) == noErr {
                listenerRegistrations.append((address, block))
            }
        }
    }

    private func evaluate(reason: String, force: Bool, scheduleRetries: Bool) {
        let devices = allDevices()
        let inputDevices = devices.filter(\.hasInput)
        let currentInput = device(withID: defaultDevice(selector: kAudioHardwarePropertyDefaultInputDevice), in: devices)
        let currentOutput = device(withID: defaultDevice(selector: kAudioHardwarePropertyDefaultOutputDevice), in: devices)

        guard let target = resolveTarget(from: inputDevices) else {
            publish(
                state: .targetUnavailable,
                currentInput: currentInput,
                currentOutput: currentOutput,
                target: nil,
                devices: inputDevices
            )
            return
        }

        let bluetoothActive = currentOutput?.isBluetooth == true
        let decision = ProtectionPolicy.decision(
            enabled: preferences.isEnabled,
            force: force,
            bluetoothOnly: preferences.protectsOnlyWithBluetoothOutput,
            bluetoothOutputActive: bluetoothActive,
            currentInputID: currentInput?.id,
            targetInputID: target.id
        )

        switch decision {
        case .disabled:
            publish(state: .disabled, currentInput: currentInput, currentOutput: currentOutput, target: target, devices: inputDevices)
        case .waitingForBluetooth:
            publish(state: .waitingForBluetooth, currentInput: currentInput, currentOutput: currentOutput, target: target, devices: inputDevices)
        case .enforce:
            if setDefaultInput(target.id) {
                correctionCount += 1
                lastCorrectionDate = Date()
                publish(state: .corrected, currentInput: target, currentOutput: currentOutput, target: target, devices: inputDevices)
                if scheduleRetries {
                    scheduleRaceRetries()
                }
            } else {
                publish(state: .error("无法切换默认输入"), currentInput: currentInput, currentOutput: currentOutput, target: target, devices: inputDevices)
            }
        case .active:
            publish(state: .active, currentInput: currentInput, currentOutput: currentOutput, target: target, devices: inputDevices)
        }
    }

    private func scheduleRaceRetries() {
        retryGeneration += 1
        let generation = retryGeneration
        for delay in [0.25, 0.9] {
            queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, generation == self.retryGeneration else { return }
                self.evaluate(reason: "连接竞争重试", force: false, scheduleRetries: false)
            }
        }
    }

    private func resolveTarget(from inputDevices: [AudioDevice]) -> AudioDevice? {
        if let uid = preferences.anchoredInputUID,
           let selected = inputDevices.first(where: { $0.uid == uid }) {
            return selected
        }

        guard let builtIn = inputDevices.first(where: \.isBuiltIn) else {
            return inputDevices.first
        }
        preferences.anchoredInputUID = builtIn.uid
        return builtIn
    }

    private func publish(
        state: ProtectionState,
        currentInput: AudioDevice?,
        currentOutput: AudioDevice?,
        target: AudioDevice?,
        devices: [AudioDevice]
    ) {
        let snapshot = AudioSnapshot(
            protectionState: state,
            currentInputName: currentInput?.name ?? "无输入设备",
            currentOutputName: currentOutput?.name ?? "无输出设备",
            anchoredInputName: target?.name ?? "未找到",
            bluetoothOutputActive: currentOutput?.isBluetooth == true,
            correctionCount: correctionCount,
            lastCorrectionDate: lastCorrectionDate
        )
        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(snapshot, devices.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending })
        }
    }

    private func allDevices() -> [AudioDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(systemObject, &address, 0, nil, &size) == noErr else {
            return []
        }

        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        let status = ids.withUnsafeMutableBytes { buffer in
            AudioObjectGetPropertyData(systemObject, &address, 0, nil, &size, buffer.baseAddress!)
        }
        guard status == noErr else { return [] }

        return ids.compactMap { id in
            guard let uid = stringProperty(id, selector: kAudioDevicePropertyDeviceUID) else { return nil }
            return AudioDevice(
                id: id,
                uid: uid,
                name: stringProperty(id, selector: kAudioObjectPropertyName) ?? "未知设备",
                transportType: uint32Property(id, selector: kAudioDevicePropertyTransportType) ?? 0,
                inputChannels: channelCount(id, scope: kAudioObjectPropertyScopeInput),
                outputChannels: channelCount(id, scope: kAudioObjectPropertyScopeOutput)
            )
        }
    }

    private func defaultDevice(selector: AudioObjectPropertySelector) -> AudioObjectID? {
        uint32Property(systemObject, selector: selector)
    }

    private func device(withID id: AudioObjectID?, in devices: [AudioDevice]) -> AudioDevice? {
        guard let id else { return nil }
        return devices.first(where: { $0.id == id })
    }

    private func setDefaultInput(_ id: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = id
        let size = UInt32(MemoryLayout<AudioObjectID>.size)
        return AudioObjectSetPropertyData(systemObject, &address, 0, nil, size, &deviceID) == noErr
    }

    private func uint32Property(
        _ objectID: AudioObjectID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
    ) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, &value) == noErr else {
            return nil
        }
        return value
    }

    private func stringProperty(
        _ objectID: AudioObjectID,
        selector: AudioObjectPropertySelector
    ) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let status = withUnsafeMutablePointer(to: &value) { pointer in
            AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, pointer)
        }
        return status == noErr ? value as String : nil
    }

    private func channelCount(_ deviceID: AudioObjectID, scope: AudioObjectPropertyScope) -> Int {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr, size > 0 else {
            return 0
        }

        let raw = UnsafeMutableRawPointer.allocate(
            byteCount: Int(size),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { raw.deallocate() }
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, raw) == noErr else {
            return 0
        }

        let buffers = UnsafeMutableAudioBufferListPointer(raw.assumingMemoryBound(to: AudioBufferList.self))
        return buffers.reduce(0) { $0 + Int($1.mNumberChannels) }
    }
}
