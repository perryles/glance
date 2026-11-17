import Foundation

@main
struct SpaceKeySelfTest {
    static func main() {
        var state = SpaceKeyState()
        precondition(!state.receive(device: 1, isDown: false))
        precondition(state.receive(device: 1, isDown: true))
        precondition(!state.receive(device: 1, isDown: true), "Held space must not start another scan")
        precondition(state.receive(device: 2, isDown: true), "Each keyboard has independent key state")
        precondition(!state.receive(device: 1, isDown: false))
        precondition(state.receive(device: 1, isDown: true))
        state.remove(device: 1)
        precondition(state.receive(device: 1, isDown: true), "Reconnected keyboards must not stay held")
        state.reset()
        precondition(state.receive(device: 2, isDown: true), "Wake/restart must clear stale held state")
        precondition(SpaceKeyState.shouldListen(enabled: true, selected: true, sleeping: false, permitted: true))
        precondition(!SpaceKeyState.shouldListen(enabled: false, selected: true, sleeping: false, permitted: true))
        precondition(!SpaceKeyState.shouldListen(enabled: true, selected: false, sleeping: false, permitted: true))
        precondition(SpaceKeyState.shouldListen(enabled: true, selected: true, sleeping: true, permitted: true), "Keep the queue open for the key that wakes the Mac")
        precondition(!SpaceKeyState.shouldListen(enabled: true, selected: true, sleeping: false, permitted: false))
        print("PASS: space key presses, repeat suppression, multiple devices, reconnect, sleep and permission gates")
    }
}
