//
//  ChatInputView.swift
//  MCPiOSClient
//
//  iOS-optimized chat input with keyboard handling
//

import SwiftUI

struct ChatInputView: View {
    @Binding var inputText: String
    let onSend: () -> Void
    let isLoading: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text input
            TextField("Type a message...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .lineLimit(1...4)
                .focused($isFocused)
                .onSubmit {
                    if !inputText.isEmpty && !isLoading {
                        onSend()
                    }
                }
                .submitLabel(.send)

            // Send button
            Button(action: {
                onSend()
                isFocused = false
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(sendButtonColor)
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            .animation(.easeInOut(duration: 0.2), value: sendButtonColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var sendButtonColor: Color {
        if isLoading {
            return Color(.systemGray3)
        } else if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Color(.systemGray3)
        } else {
            return .blue
        }
    }
}