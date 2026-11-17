import Foundation
import Security

@main
struct SystemAuthenticationPromptSelfTest {
    static func main() {
        let securityAgent = SystemAuthenticationPromptDescriptor(
            bundleIdentifier: "com.apple.SecurityAgent",
            executablePath: "/System/Library/CoreServices/SecurityAgent.app/Contents/MacOS/SecurityAgent",
            focusedElementRole: "AXTextField",
            focusedElementSubrole: "AXSecureTextField",
            isFocusedElementEnabled: true
        )
        precondition(SystemAuthenticationPromptPolicy.isTrusted(securityAgent), "FAIL: SecurityAgent secure field should be trusted")

        let localAuthentication = SystemAuthenticationPromptDescriptor(
            bundleIdentifier: "com.apple.LocalAuthentication.UIAgent",
            executablePath: "/System/Library/Frameworks/LocalAuthentication.framework/Support/coreautha.bundle/Contents/MacOS/coreautha",
            focusedElementRole: "AXTextField",
            focusedElementSubrole: "AXSecureTextField",
            isFocusedElementEnabled: true
        )
        precondition(SystemAuthenticationPromptPolicy.isTrusted(localAuthentication), "FAIL: LocalAuthentication Mac-password fallback should be trusted")
        let requirementText = SystemAuthenticationPromptPolicy.signingRequirement(for: localAuthentication)!
        var requirement: SecRequirement?
        precondition(SecRequirementCreateWithString(requirementText as CFString, [], &requirement) == errSecSuccess)
        var code: SecStaticCode?
        let agentURL = URL(fileURLWithPath: "/System/Library/Frameworks/LocalAuthentication.framework/Support/coreautha.bundle")
        precondition(SecStaticCodeCreateWithPath(agentURL as CFURL, [], &code) == errSecSuccess)
        precondition(SecStaticCodeCheckValidity(code!, [], requirement!) == errSecSuccess, "FAIL: the actual Apple agent must satisfy the policy's signature requirement")

        var invalidLocalAuthentication = localAuthentication
        invalidLocalAuthentication.focusedElementSubrole = nil
        precondition(!SystemAuthenticationPromptPolicy.isTrusted(invalidLocalAuthentication))
        invalidLocalAuthentication = localAuthentication
        invalidLocalAuthentication.isFocusedElementEnabled = false
        precondition(!SystemAuthenticationPromptPolicy.isTrusted(invalidLocalAuthentication))
        invalidLocalAuthentication = localAuthentication
        invalidLocalAuthentication.executablePath = "/Applications/FakeAuth.app/Contents/MacOS/FakeAuth"
        precondition(!SystemAuthenticationPromptPolicy.isTrusted(invalidLocalAuthentication))

        var accountAuthentication = localAuthentication
        accountAuthentication.bundleIdentifier = "com.apple.AuthKitUIService"
        precondition(!SystemAuthenticationPromptPolicy.isTrusted(accountAuthentication), "FAIL: Account password UI must not receive the Mac password")
        precondition(SystemAuthenticationPromptPolicy.signingRequirement(for: accountAuthentication) == nil)

        let systemSettings = SystemAuthenticationPromptDescriptor(
            bundleIdentifier: "com.apple.systempreferences",
            executablePath: "/System/Applications/System Settings.app/Contents/MacOS/System Settings",
            focusedElementRole: "AXTextField",
            focusedElementSubrole: "AXSecureTextField",
            isFocusedElementEnabled: true
        )
        // System Settings hosts more than login-password authentication (including
        // Apple ID fields), so v1 must not treat every secure field there as a
        // Mac-password prompt.
        precondition(!SystemAuthenticationPromptPolicy.isTrusted(systemSettings), "FAIL: System Settings secure field must not be a blanket password target")

        let safari = SystemAuthenticationPromptDescriptor(
            bundleIdentifier: "com.apple.Safari",
            executablePath: "/Applications/Safari.app/Contents/MacOS/Safari",
            focusedElementRole: "AXTextField",
            focusedElementSubrole: "AXSecureTextField",
            isFocusedElementEnabled: true
        )
        precondition(!SystemAuthenticationPromptPolicy.isTrusted(safari), "FAIL: Safari must not be a password target")

        let spoofedBundleID = SystemAuthenticationPromptDescriptor(
            bundleIdentifier: "com.apple.SecurityAgent",
            executablePath: "/Users/demo/Malware.app/Contents/MacOS/Malware",
            focusedElementRole: "AXTextField",
            focusedElementSubrole: "AXSecureTextField",
            isFocusedElementEnabled: true
        )
        precondition(!SystemAuthenticationPromptPolicy.isTrusted(spoofedBundleID), "FAIL: third-party path must be rejected even with Apple bundle ID")

        let plainField = SystemAuthenticationPromptDescriptor(
            bundleIdentifier: "com.apple.SecurityAgent",
            executablePath: "/System/Library/CoreServices/SecurityAgent.app/Contents/MacOS/SecurityAgent",
            focusedElementRole: "AXTextField",
            isFocusedElementEnabled: true
        )
        precondition(!SystemAuthenticationPromptPolicy.isTrusted(plainField), "FAIL: normal text field must be rejected")

        var missingSubrole = securityAgent
        missingSubrole.focusedElementSubrole = nil
        precondition(!SystemAuthenticationPromptPolicy.isTrusted(missingSubrole), "FAIL: a missing secure subrole must be rejected")

        var invalidRole = securityAgent
        invalidRole.focusedElementRole = "AXSecureTextField"
        precondition(!SystemAuthenticationPromptPolicy.isTrusted(invalidRole), "FAIL: the subrole must not be mistaken for the role")

        let disabledField = SystemAuthenticationPromptDescriptor(
            bundleIdentifier: "com.apple.SecurityAgent",
            executablePath: "/System/Library/CoreServices/SecurityAgent.app/Contents/MacOS/SecurityAgent",
            focusedElementRole: "AXTextField",
            focusedElementSubrole: "AXSecureTextField",
            isFocusedElementEnabled: false
        )
        precondition(!SystemAuthenticationPromptPolicy.isTrusted(disabledField), "FAIL: disabled secure field must be rejected")

        precondition(!SystemAuthenticationPromptPolicy.isTrusted(nil), "FAIL: missing descriptor must be rejected")

        print("PASS: system authentication prompt policy")
    }
}
