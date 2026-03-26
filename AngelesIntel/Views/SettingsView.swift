import SwiftUI

enum AgencySignInState {
    case idle
    case enterEmail
    case enterOTP
    case verified
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("autoplayAudio") private var autoplayAudio = false
    @AppStorage("agencyVerified") private var agencyVerified = false
    @AppStorage("agencyEmail") private var agencyEmail = ""
    @State private var signInState: AgencySignInState = .idle
    @State private var govEmail = ""
    @State private var otpCode = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingVerifiedAlert = false
    @State private var showingStatus = false
    @State private var showingAgencyInfo = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $autoplayAudio) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto-Play Audio Stream(s)")
                            Text("Automatically connect to Forest Net and Admin Net (if you have access to it; see below) on launch")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Audio")
                } footer: {
                    Text("When enabled, the live Forest Net audio stream will begin playing automatically when you open the app. If you have agency access, Admin Net will also auto-play.")
                }

                Section {
                    switch signInState {
                    case .idle:
                        Button {
                            withAnimation { signInState = .enterEmail }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "building.columns.fill")
                                    .foregroundStyle(Color.accentColor)
                                Text("Sign In With Email")
                            }
                        }

                    case .enterEmail:
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("you@example.com", text: $govEmail)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }

                            Button {
                                Task { await requestOTP() }
                            } label: {
                                HStack {
                                    if isSubmitting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    Text("Send Verification Code")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(govEmail.isEmpty || !govEmail.contains("@") || isSubmitting)
                            .allowsHitTesting(!isSubmitting)
                        }
                        .padding(.vertical, 4)

                    case .enterOTP:
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.badge.fill")
                                    .foregroundStyle(Color.accentColor)
                                Text("Check your email and enter the code below")
                                    .font(.subheadline)
                            }

                            Text(govEmail)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextField("Verification code", text: $otpCode)
                                .textContentType(.oneTimeCode)
                                .keyboardType(.asciiCapable)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                                .onChange(of: otpCode) {
                                    otpCode = String(
                                        otpCode
                                            .uppercased()
                                            .filter { $0.isLetter || $0.isNumber }
                                            .prefix(7)
                                    )
                                }

                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }

                            Button {
                                Task { await verifyOTP() }
                            } label: {
                                HStack {
                                    if isSubmitting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    Text("Verify")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(otpCode.count < 5 || isSubmitting)
                            .allowsHitTesting(!isSubmitting)
                        }
                        .padding(.vertical, 4)

                    case .verified:
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Verified")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(agencyEmail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Sign Out", role: .destructive) {
                                withAnimation {
                                    agencyVerified = false
                                    agencyEmail = ""
                                    govEmail = ""
                                    otpCode = ""
                                    signInState = .idle
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                } header: {
                    HStack(spacing: 4) {
                        Text("Agency Access")
                        Button {
                            showingAgencyInfo = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("Federal, state, and local fire personnel can sign in with their email to access the Admin Net (ANF law enforcement) audio stream and manual data refresh. A one-time verification code will be emailed to confirm your identity.")
                }

                // MARK: About
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("Angeles Intel.")
                                .font(.headline)
                                .foregroundStyle(Color.accentColor)
                        }
                        Spacer()
                    }

                    Text("A forever-free, ad-free incident tracker and radio monitor for Angeles National Forest\n\nPresented by Landmark 717, a not-for-profit documentary series covering Angeles National Forest\n\nThis app was created in the interest of public safety, providing open access to incident data and live radio communications for civilians and fire personnel alike.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text("Disclaimer")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("You're using this app at your own risk. Pay attention to your surroundings, don't rely on these feeds for life safety, remember streams are delayed, and always follow your organization's best practices. If you have a physical scanner, use that instead if you can. Streams use data, and you are responsible for monitoring your data use with your carrier and/or ISPs.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text("Finally, don't hesitate to get in touch for any reason:")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Link(destination: URL(string: "https://landmark717.com")!) {
                        HStack(spacing: 4) {
                            Spacer()
                            Image(systemName: "globe")
                            Text("Landmark717.com")
                            Spacer()
                        }
                        .font(.footnote)
                        .foregroundStyle(Color.accentColor)
                    }

                    Button {
                        showingStatus = true
                    } label: {
                        HStack(spacing: 4) {
                            Spacer()
                            Image(systemName: "server.rack")
                            Text("System Status")
                            Spacer()
                        }
                        .font(.footnote)
                        .foregroundStyle(Color.accentColor)
                    }

                    Link(destination: URL(string: "https://github.com/acceptableEngineering/angeles-intel/blob/main/README.md")!) {
                        HStack(spacing: 4) {
                            Spacer()
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                            Text("Project Roadmap & Source Code on GitHub")
                            Spacer()
                        }
                        .font(.footnote)
                        .foregroundStyle(Color.accentColor)
                    }

                    Link(destination: URL(string: "mailto:mark@landmark717.com")!) {
                        HStack(spacing: 4) {
                            Spacer()
                            Image(systemName: "envelope")
                            Text("mark@landmark717.com")
                            Spacer()
                        }
                        .font(.footnote)
                        .foregroundStyle(Color.accentColor)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if agencyVerified {
                    signInState = .verified
                }
            }
            .sheet(isPresented: $showingStatus) {
                InAppBrowserSheet(title: "System Status", url: URL(string: "https://status.landmark717.com/status/anf-firebot")!)
            }
            .alert("Agency Access", isPresented: $showingAgencyInfo) {
                Button("OK") { }
            } message: {
                Text("We've been asked to keep the Admin Net (Law Talk) audio stream protected from non-government employees")
            }
            .alert("You're Verified!", isPresented: $showingVerifiedAlert) {
                Button("Got It") { }
            } message: {
                Text("You've unlocked access to the Admin Net audio stream and pull-to-refresh on the incidents list.")
            }
        }
    }

    private func requestOTP() async {
        isSubmitting = true
        errorMessage = nil

        defer { isSubmitting = false }

        guard let url = URL(string: "https://landmark717.com/app/otp-gen") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["email": govEmail])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "Request failed. Is your email a .gov or associated address? (See below)"
                return
            }

            withAnimation { signInState = .enterOTP }
        } catch {
            errorMessage = "Unable to connect. Please try again."
        }
    }

    private func verifyOTP() async {
        isSubmitting = true
        errorMessage = nil

        defer { isSubmitting = false }

        guard let url = URL(string: "https://landmark717.com/app/otp-check") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["email": govEmail, "otp": otpCode])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                errorMessage = "Verification failed. Please check your code and try again."
                return
            }

            struct VerifyResponse: Codable {
                let message: String
            }

            let verifyResponse = try JSONDecoder().decode(VerifyResponse.self, from: data)

            if verifyResponse.message == "OTP verified" {
                agencyVerified = true
                agencyEmail = govEmail
                withAnimation { signInState = .verified }
                showingVerifiedAlert = true
            } else {
                errorMessage = verifyResponse.message
            }
        } catch {
            errorMessage = "Unable to connect. Please try again."
        }
    }
}
