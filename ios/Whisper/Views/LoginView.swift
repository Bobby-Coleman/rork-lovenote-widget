import SwiftUI

struct LoginView: View {
    let authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)

                    VStack(spacing: 8) {
                        Text("whisper")
                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                            .tracking(2)

                        Text("leave a little love note")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 16) {
                        TextField("email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        SecureField("password", text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { loginAction() }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: 12))
                    }

                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        loginAction()
                    } label: {
                        Group {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("sign in")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
                    .clipShape(.rect(cornerRadius: 12))
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)

                    Button {
                        showRegister = true
                    } label: {
                        Text("don't have an account? **sign up**")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarHidden(true)
            .sheet(isPresented: $showRegister) {
                RegisterView(authViewModel: authViewModel)
            }
        }
    }

    private func loginAction() {
        guard !email.isEmpty, !password.isEmpty else { return }
        Task {
            await authViewModel.login(email: email, password: password)
        }
    }
}
