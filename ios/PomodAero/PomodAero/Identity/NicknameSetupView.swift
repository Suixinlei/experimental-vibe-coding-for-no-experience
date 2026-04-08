//
//  NicknameSetupView.swift
//  PomodAero
//
//  First-launch nickname input. Simple TextField + CTA.
//

import SwiftUI

struct NicknameSetupView: View {
    @Environment(IdentityStore.self) private var identity
    @State private var draft: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var nicknameFocused: Bool

    private var canSubmit: Bool {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1 && trimmed.count <= 32 && !isSubmitting
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.18),
                    Color(red: 0.10, green: 0.15, blue: 0.32)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("PomodAero")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("每一次专注,都是一场从杭州出发的旅行")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("给自己起个名字")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                    TextField("", text: $draft, prompt: Text("昵称").foregroundStyle(.white.opacity(0.4)))
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.white.opacity(0.12))
                        )
                        .focused($nicknameFocused)
                        .submitLabel(.done)
                        .onSubmit { Task { await submit() } }
                }
                .padding(.horizontal, 32)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(.horizontal, 32)
                }

                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("出发")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white)
                    )
                    .foregroundStyle(.black)
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.4)
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .onAppear { nicknameFocused = true }
    }

    @MainActor
    private func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            try await identity.setNickname(draft)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "网络出错,再试一次"
        }
    }
}

#Preview {
    NicknameSetupView()
        .environment(IdentityStore())
}
