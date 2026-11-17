import SwiftUI

struct InfraredLabView: View {
    var beforeCapture: () -> Void = {}
    @Environment(\.scenePhase) private var scenePhase
    @State private var controller = InfraredProbeController()

    var body: some View {
        GroupBox(String(localized: "Infrared camera — experimental")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Test the Logitech BRIO's infrared sensor. This test does not enable IR face unlock."))
                    .font(.callout)
                if controller.service.available {
                    Text(String(localized: "Enable the camera helper once to test without repeated administrator prompts. You can disable it here when finished."))
                        .font(.caption)
                    HStack {
                        if controller.service.registered {
                            Button(String(localized: "Disable camera helper")) {
                                Task { await controller.service.disable() }
                            }
                        } else {
                            Button(String(localized: "Enable camera helper")) { controller.service.enable() }
                        }
                        if controller.service.needsApproval {
                            Button(String(localized: "Open System Settings")) { controller.service.openSettings() }
                        }
                        Text(controller.service.enabled ? "Enabled" : (controller.service.needsApproval ? String(localized: "Awaiting approval") : "Disabled"))
                            .font(.caption)
                    }
                    .disabled(controller.isBusy)
                    if !controller.service.message.isEmpty {
                        Text(controller.service.message).font(.caption).foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Button(String(localized: "Check camera")) { controller.check() }
                        .disabled(controller.isBusy || !controller.helperAvailable)
                    Button(String(localized: "Test infrared")) {
                        beforeCapture()
                        controller.capture()
                    }
                    .disabled(controller.isBusy || !controller.canCapture || (controller.service.available && !controller.service.enabled))
                    if controller.isBusy {
                        ProgressView().controlSize(.small)
                        Button(String(localized: "Cancel")) { controller.cancel() }
                    }
                    Spacer()
                }
                Text(controller.helperAvailable ? controller.status : String(localized: "The optional IR helper is not included in this build."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                GroupBox(String(localized: "Compare faces — experimental")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Capture three reference scans of one person, then compare a new scan. Each capture stops when an illuminated burst is ready, within five seconds."))
                            .font(.caption)
                        HStack {
                            Button(String(localized: "Add reference scan (\(controller.referenceCount)/3)")) {
                                beforeCapture()
                                controller.captureReference()
                            }
                            .disabled(controller.referenceReady)
                            Button(String(localized: "Compare new scan")) {
                                beforeCapture()
                                controller.compare()
                            }
                            .disabled(!controller.referenceReady)
                            Button(String(localized: "Clear reference")) { controller.clearReference() }
                                .disabled(controller.referenceCount == 0)
                        }
                        .disabled(controller.isBusy || !controller.canCapture || (controller.service.available && !controller.service.enabled))
                        Text(controller.comparisonStatus).font(.caption).foregroundStyle(.secondary)
                        if let latest = controller.lastComparison {
                            Text(String(localized: "Similarity score: \(latest.centroid, specifier: "%.3f")"))
                                .font(.headline.monospacedDigit())
                            Text(String(localized: "Across reference scans: \(latest.minimumReference, specifier: "%.3f") to \(latest.maximumReference, specifier: "%.3f")"))
                                .font(.caption.monospacedDigit())
                        }
                        let earlier = controller.lastComparison == nil ? controller.comparisons : Array(controller.comparisons.dropFirst())
                        if !earlier.isEmpty {
                            Text(String(localized: "Earlier scores: ") + earlier.map { String(format: "%.3f", $0.centroid) }.joined(separator: " · "))
                                .font(.caption.monospacedDigit())
                        }
                        Text(String(localized: "Higher scores mean more similar face features. This is not a confidence percentage or an unlock check. Infrared accuracy and spoof resistance are unverified. References stay in memory until cleared or this panel closes."))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(.black)
                    if let image = controller.image {
                        Image(decorative: image, scale: 1)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 340, height: 340)
                            .accessibilityLabel(String(localized: "Infrared camera test image"))
                    } else {
                        Text(controller.isBusy ? String(localized: "Waiting for the IR image…") : String(localized: "Infrared image appears here after the test"))
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                .frame(width: 340, height: 340)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                if let statistics = controller.statistics {
                    Text(statistics).font(.caption.monospacedDigit())
                }
                Text(String(localized: "The test briefly interrupts BRIO video and audio. Images stay in memory and are cleared when this panel closes."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { controller.service.refresh() }
        }
        .onDisappear { controller.clear() }
    }
}
