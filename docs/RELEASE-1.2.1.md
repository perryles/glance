# Glance 1.2.1 (build 7)

Changes compared with jonnyoo/glance main at b97f521. Download **Glance-1.2.1.dmg** for Apple Silicon Macs running macOS 15 or later. [Upstream baseline](https://github.com/jonnyoo/glance/tree/b97f521397ec1197ba17768ba797cae1e628848d)

## New

- Added Simplified Chinese and Turkish translations for settings, onboarding, permissions, error messages and the new infrared pages. Glance follows your system language and supports the per-app language selection in macOS settings.
- Added system password assistance. Enable it, focus a supported Apple system password field and press **Control + Option + Command + F**. After face verification, Glance fills your Mac login password for you to confirm. The field owner, focus and Apple system-agent signature are checked. Supported prompts are the secure password fields owned by SecurityAgent and LocalAuthentication UIAgent. Native Face ID, Touch ID and passkey authentication remain outside this feature's scope.
- Added experimental Logitech BRIO infrared support, ported from JediBrooker's PR #50 at e089499. Includes a signed helper, three independent enrollment scans and encrypted templates. Disabled by default. When enabled, both lock-screen unlock and system password assistance require colour identity recognition, Heavy liveness and a fresh infrared match for the same identity. Missing hardware, approval or enrollment denies face unlock. [PR #50](https://github.com/jonnyoo/glance/pull/50)

## Improvements

- Improved camera handoff and recovery after infrared capture, and refined glare analysis while preserving the recognition-distance setting.
- Pointed update checks, feedback and download links to the perryles repository. Increased the internal build number from 6 to 7.

## Fixes

- Improved space-key triggering across sleep, wake and lock transitions, repeated key events and keyboard reconnections by establishing input monitoring earlier and keeping it active through sleep.
- Fixed keychain migration potentially deleting old data after a read failure. Migration now verifies the destination before removing the source.
- Invalidated in-flight recognition, infrared enrollment and password submission when the credential session changes.

The signed Release build, eight offline infrared/liveness regression suites, space-key state checks, system-prompt trust policy, keychain migration, encrypted storage and session checks, native infrared offline checks, Chinese/Turkish resources, and app/helper signature checks passed.

Infrared support remains experimental. BRIO enrollment, end-to-end unlock and spoof-resistance thresholds still need hardware validation because no infrared camera was available. Lock-screen, sleep/wake and system password-field interactions also need live acceptance testing. The download is signed with an Apple Development certificate and has not been Developer ID notarized, which may limit installation or execution on other Macs.
