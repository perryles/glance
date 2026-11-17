import SwiftUI
import Observation

@Observable @MainActor
private final class InfraredEnrollmentController {
    let service = InfraredServiceManager()
    private let analyzer = InfraredFaceAnalyzer()
    private(set) var image: CGImage?
    private(set) var samples: [InfraredFaceSample] = []
    private(set) var isBusy = false
    private(set) var sessionIdentifier: UUID?
    var status = String(localized: "Look at the BRIO and capture three infrared reference scans.")
    private var operation: Task<Void, Never>?
    private var generation = UUID()

    func capture(beforeCapture: @escaping @MainActor () async -> Void) {
        guard !isBusy, samples.count < 3 else { return }
        service.refresh()
        guard service.enabled else { status = String(localized: "Enable and approve the camera helper first."); return }
        guard SecureCredentialManager.isSessionUnlocked, !LockMonitor.isScreenActuallyLocked() else {
            status = String(localized: "Unlock your Mac and authenticate in Glance before enrolling."); return
        }
        let session = SecureCredentialManager.sessionIdentifier
        guard samples.isEmpty || sessionIdentifier == session else { clear(); return }
        sessionIdentifier = session
        isBusy = true
        image = nil
        status = String(localized: "Capturing infrared…")
        let id = UUID()
        generation = id
        operation = Task {
            do {
                await beforeCapture()
                try Task.checkCancellation()
                let result = try await InfraredServiceManager.capture()
                let frame = try result.image()
                guard generation == id else { return }
                image = frame
                let sample = try await analyzer.sample(from: frame, captureID: id)
                try Task.checkCancellation()
                guard generation == id else { return }
                guard session != nil, SecureCredentialManager.sessionIdentifier == session,
                      !LockMonitor.isScreenActuallyLocked() else {
                    throw SecureFaceStoreError.sessionLocked
                }
                samples.append(sample)
                status = samples.count == 3 ? String(localized: "Three scans captured. Save to attach them to this identity.")
                    : String(localized: "Captured \(samples.count) of 3. Keep the same person in view and capture again.")
            } catch {
                guard generation == id else { return }
                status = error.localizedDescription
            }
            guard generation == id else { return }
            isBusy = false
            operation = nil
        }
    }

    func clear() {
        generation = UUID()
        operation?.cancel(); operation = nil
        isBusy = false; image = nil; samples = []
        sessionIdentifier = nil
    }
}

struct InfraredEnrollmentView: View {
    let identity: FaceIdentity
    let environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var controller = InfraredEnrollmentController()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Infrared enrollment: \(identity.name)")).font(.title2)
            Text(String(localized: "Use the same person as this identity's colour-camera enrollment. The BRIO briefly interrupts its normal video and audio during each scan."))
                .font(.callout)
            if !controller.service.enabled {
                HStack {
                    Button(String(localized: "Enable camera helper")) { controller.service.enable() }
                        .disabled(!controller.service.available || controller.service.registered)
                    if controller.service.needsApproval {
                        Button(String(localized: "Open System Settings")) { controller.service.openSettings() }
                    }
                    Button(String(localized: "Check approval")) { controller.service.refresh() }
                }
                Text(controller.service.available ? controller.service.message : String(localized: "This build does not include the signed infrared helper."))
                    .font(.caption)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(.black)
                if let image = controller.image {
                    Image(decorative: image, scale: 1).resizable().scaledToFit()
                        .accessibilityLabel(String(localized: "Infrared enrollment preview"))
                } else { Text(String(localized: "Infrared preview")).foregroundStyle(.white) }
            }.frame(width: 340, height: 340)
            Text(controller.status).font(.callout).textSelection(.enabled)
            HStack {
                Button(String(localized: "Capture scan (\(controller.samples.count)/3)")) {
                    controller.capture {
                        // Face Lab is created only while its own tab is showing (released on disappear), so the
                        // unlock coordinator's camera is the only colour session that can still hold the BRIO here.
                        await environment.faceUnlockCoordinator.camera.stopAndWait()
                    }
                }.disabled(controller.isBusy || controller.samples.count == 3 || !controller.service.enabled)
                if controller.isBusy { ProgressView().controlSize(.small) }
                Spacer()
                Button(String(localized: "Cancel")) { controller.clear(); dismiss() }
                Button(String(localized: "Save infrared enrollment")) {
                    do {
                        guard controller.sessionIdentifier != nil,
                              controller.sessionIdentifier == SecureCredentialManager.sessionIdentifier else {
                            throw SecureFaceStoreError.sessionLocked
                        }
                        let enrollment = try InfraredEnrollment(samples: controller.samples)
                        try FaceEnrollmentStore.shared.setInfrared(enrollment, for: identity)
                        controller.clear(); dismiss()
                    } catch { controller.status = error.localizedDescription }
                }.disabled(controller.isBusy || controller.samples.count != 3)
            }
            Text(String(localized: "Face features are encrypted with your existing enrollment. Images are not saved. Enable the additional infrared check separately in Recognition settings."))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24).frame(width: 640)
        .onChange(of: scenePhase) { _, phase in if phase == .active { controller.service.refresh() } }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            controller.service.refresh()
        }
        .onChange(of: FaceEnrollmentStore.shared.isLocked) { _, locked in
            if locked { controller.clear(); dismiss() }
        }
        .onDisappear { controller.clear() }
    }
}
