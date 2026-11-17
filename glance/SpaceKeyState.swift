import Foundation

nonisolated struct SpaceKeyState {
    private var heldDevices: Set<UInt> = []

    mutating func receive(device: UInt, isDown: Bool) -> Bool {
        if isDown { return heldDevices.insert(device).inserted }
        heldDevices.remove(device)
        return false
    }

    mutating func remove(device: UInt) { heldDevices.remove(device) }
    mutating func reset() { heldDevices.removeAll() }

    // Open before locking so the key that wakes the display can reach the existing queue.
    static func shouldListen(enabled: Bool, selected: Bool, sleeping _: Bool, permitted: Bool) -> Bool {
        enabled && selected && permitted
    }
}
