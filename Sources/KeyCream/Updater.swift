import AppKit
import CryptoKit
import Security

/** Finds a newer GitHub release and installs it over the running copy of the app. */
@MainActor
final class Updater {
    enum State { case idle, checking, downloading }

    private struct Release: Decodable {
        struct Asset: Decodable {
            let name: String
            let browserDownloadUrl: URL
            let digest: String?
        }

        let tagName: String
        let htmlUrl: URL
        let assets: [Asset]

        var version: String { tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName }
    }

    private enum UpdateError: Error {
        case badResponse, notReplaceable, noDownload, digestMismatch, unzipFailed, wrongBundle, invalidSignature
    }

    private static let latestReleaseURL = URL(string: "https://api.github.com/repos/halitsever/keycream/releases/latest")!

    private(set) var state = State.idle {
        didSet { onStateChange?() }
    }

    var onStateChange: (() -> Void)?

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        return URLSession(configuration: configuration)
    }()

    /** The check at login often starts before the network is up. */
    private let patientSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForResource = 120
        return URLSession(configuration: configuration)
    }()

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    /** Only a check the user started reports that nothing is new, or that it failed. */
    func check(userInitiated: Bool) {
        guard state == .idle else { return }
        state = .checking
        Task {
            let release: Release
            do {
                release = try await fetchLatestRelease(using: userInitiated ? session : patientSession)
            } catch {
                state = .idle
                print("Update check failed: \(error)")
                if userInitiated {
                    showAlert(
                        title: Localization.string("update_check_failed"),
                        message: Localization.string("update_check_failed_message"),
                        buttons: [Localization.string("ok")]
                    )
                }
                return
            }
            state = .idle
            if release.version.compare(currentVersion, options: .numeric) == .orderedDescending {
                offer(release)
            } else if userInitiated {
                showAlert(
                    title: Localization.string("update_none"),
                    message: String(format: Localization.string("update_none_message"), currentVersion),
                    buttons: [Localization.string("ok")]
                )
            }
        }
    }

    private func fetchLatestRelease(using session: URLSession) async throws -> Release {
        var request = URLRequest(url: Self.latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw UpdateError.badResponse }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Release.self, from: data)
    }

    private func offer(_ release: Release) {
        let choice = showAlert(
            title: String(format: Localization.string("update_available"), release.version),
            message: String(format: Localization.string("update_available_message"), currentVersion),
            buttons: [Localization.string("update_install"), Localization.string("update_later")]
        )
        guard choice == .alertFirstButtonReturn else { return }
        state = .downloading
        Task {
            do {
                try await replaceApp(with: release)
            } catch {
                state = .idle
                print("Update failed: \(error)")
                let choice = showAlert(
                    title: Localization.string("update_failed"),
                    message: Localization.string("update_failed_message"),
                    buttons: [Localization.string("update_open_release"), Localization.string("cancel")]
                )
                if choice == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(release.htmlUrl)
                }
                return
            }
            relaunch()
        }
    }

    private func replaceApp(with release: Release) async throws {
        let app = Bundle.main.bundleURL
        let fileManager = FileManager.default
        // A translocated copy runs from a read-only mount that is gone after quitting.
        guard !app.path.contains("/AppTranslocation/"),
              fileManager.isWritableFile(atPath: app.deletingLastPathComponent().path) else {
            throw UpdateError.notReplaceable
        }
        guard let asset = release.assets.first(where: { $0.name.hasSuffix(".zip") }), let digest = asset.digest else {
            throw UpdateError.noDownload
        }

        let (zip, response) = try await session.download(from: asset.browserDownloadUrl)
        defer { try? fileManager.removeItem(at: zip) }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw UpdateError.badResponse }
        let hash = SHA256.hash(data: try Data(contentsOf: zip, options: .mappedIfSafe))
            .map { String(format: "%02x", $0) }.joined()
        guard digest.lowercased() == "sha256:\(hash)" else { throw UpdateError.digestMismatch }

        // On the app's volume, so the swap below is a rename.
        let staging = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: app, create: true)
        defer { try? fileManager.removeItem(at: staging) }
        try await Self.unzip(zip, into: staging)
        let newApp = staging.appendingPathComponent("KeyCream.app")
        try Self.verify(newApp, version: release.version)
        _ = try fileManager.replaceItemAt(app, withItemAt: newApp)
    }

    private static func unzip(_ zip: URL, into folder: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", zip.path, folder.path]
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            process.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: UpdateError.unzipFailed)
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func verify(_ app: URL, version: String) throws {
        guard let info = NSDictionary(contentsOf: app.appendingPathComponent("Contents/Info.plist")),
              info["CFBundleIdentifier"] as? String == Bundle.main.bundleIdentifier,
              info["CFBundleShortVersionString"] as? String == version else {
            throw UpdateError.wrongBundle
        }
        var code: SecStaticCode?
        let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSCheckNestedCode | kSecCSStrictValidate)
        guard SecStaticCodeCreateWithPath(app as CFURL, [], &code) == errSecSuccess, let code,
              SecStaticCodeCheckValidity(code, flags, signerRequirement()) == errSecSuccess else {
            throw UpdateError.invalidSignature
        }
    }

    /** An ad-hoc signature only matches its own build, so only certificate-signed builds pin the signer. */
    private static func signerRequirement() -> SecRequirement? {
        var code: SecCode?
        var staticCode: SecStaticCode?
        var info: CFDictionary?
        var requirement: SecRequirement?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code,
              SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode,
              SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
              let certificates = (info as? [String: Any])?[kSecCodeInfoCertificates as String] as? [Any],
              !certificates.isEmpty,
              SecCodeCopyDesignatedRequirement(staticCode, [], &requirement) == errSecSuccess else {
            return nil
        }
        return requirement
    }

    /** The shell waits for this process to exit so two copies never run at once. */
    private func relaunch() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            "-c", "while kill -0 \"$0\" 2>/dev/null; do sleep 0.2; done; exec /usr/bin/open -n \"$1\"",
            String(ProcessInfo.processInfo.processIdentifier), Bundle.main.bundleURL.path,
        ]
        do {
            try process.run()
        } catch {
            // The new version is already in place and starts with the next launch.
            print("Relaunch failed: \(error)")
            state = .idle
            return
        }
        NSApp.terminate(nil)
    }

    @discardableResult
    private func showAlert(title: String, message: String, buttons: [String]) -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        buttons.forEach { alert.addButton(withTitle: $0) }
        // A menu bar app is never frontmost by itself, so the alert would open behind other windows.
        NSApp.activate()
        alert.window.level = .floating
        return alert.runModal()
    }
}
