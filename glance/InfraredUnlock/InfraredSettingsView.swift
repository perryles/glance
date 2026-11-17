import SwiftUI

struct InfraredSettingsView: View {
    let coordinator: FaceUnlockCoordinator
    @Bindable private var settings = GlanceSettings.shared
    @State private var service = InfraredServiceManager()
    @Environment(\.scenePhase) private var phase

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle(text: "Infrared — experimental")
            SettingsGroup {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(String(localized: "Require a BRIO infrared match"), isOn: $settings.requireInfrared)
                        .disabled(!service.available && !settings.requireInfrared)
                    Text(String(localized: "Adds a separate infrared match after colour-camera recognition and Heavy liveness checks. Enroll infrared for each identity in Your Face first. A missing camera, helper or enrollment prevents face unlock; your Mac password still works."))
                        .font(.caption).foregroundStyle(.secondary)
                    if service.available {
                        HStack {
                            if service.registered {
                                Button(String(localized: "Disable camera helper")) { Task { await service.disable() } }
                            } else { Button(String(localized: "Enable camera helper")) { service.enable() } }
                            if service.needsApproval { Button(String(localized: "Open System Settings")) { service.openSettings() } }
                            if !service.enabled { Button(String(localized: "Check approval")) { service.refresh() } }
                            Text(service.enabled ? "Enabled" : String(localized: "Not ready")).font(.caption)
                        }
                        if !service.message.isEmpty { Text(service.message).font(.caption) }
                    } else { Text(String(localized: "The signed camera helper is not included in this build.")).font(.caption) }
                    HStack {
                        Text(String(localized: "IR similarity threshold")).font(.caption)
                        Slider(value: $settings.infraredThreshold, in: 0.60...0.95, step: 0.01)
                        Text(settings.infraredThreshold, format: .number.precision(.fractionLength(2)))
                            .font(.caption.monospacedDigit())
                    }
                    Text(String(localized: "Experimental: the threshold is not calibrated for infrared and is not a confidence percentage. The live-face check allows at least ten seconds to blink or turn your head; infrared captures an illuminated burst (up to five seconds) and briefly interrupts BRIO video/audio. It does not provide Windows Hello-equivalent spoof protection."))
                        .font(.caption).foregroundStyle(.secondary)
                    if settings.requireInfrared {
                        Text(String(localized: "Last face-unlock check: \(coordinator.lastOutcome ?? coordinator.statusMessage)"))
                            .font(.caption).textSelection(.enabled)
                        if let details = coordinator.lastCheckDetails {
                            Text(details).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                        }
                    }
                }.padding(14)
            }
        }
        .onChange(of: phase) { _, value in if value == .active { service.refresh() } }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            service.refresh()
        }
    }
}
