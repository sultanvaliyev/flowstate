import SwiftUI

/// An inline editable text field styled as a pill/chip for session labels
struct SessionLabelEditor: View {
    /// Binding to the session label text
    @Binding var label: String

    /// Whether the editor is currently in edit mode
    @State private var isEditing: Bool = false

    /// Temporary text for editing
    @State private var editingText: String = ""

    /// Focus state for the text field
    @FocusState private var isFocused: Bool

    /// Default label when empty
    private let defaultLabel = "Study"

    /// Pill background color
    var pillColor: Color = Color.white.opacity(0.25)

    /// Text color
    var textColor: Color = .white

    /// Font size
    var fontSize: CGFloat = 14

    var body: some View {
        Group {
            if isEditing {
                editingView
            } else {
                displayView
            }
        }
    }

    /// Display mode - shows the label as a tappable pill
    private var displayView: some View {
        Button(action: startEditing) {
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .font(.system(size: fontSize - 2))

                Text(label.isEmpty ? defaultLabel : label)
                    .font(.system(size: fontSize, weight: .medium))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(pillColor)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("Click to edit session label")
    }

    /// Edit mode - shows an inline text field
    private var editingView: some View {
        HStack(spacing: 4) {
            Image(systemName: "tag.fill")
                .font(.system(size: fontSize - 2))
                .foregroundColor(textColor)

            TextField("Label", text: $editingText)
                .textFieldStyle(.plain)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(textColor)
                .focused($isFocused)
                .frame(minWidth: 60, maxWidth: 120)
                .onSubmit {
                    confirmEdit()
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(pillColor)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
        )
        .onAppear {
            isFocused = true
        }
        .onChange(of: isFocused) { oldValue, newValue in
            if !newValue {
                confirmEdit()
            }
        }
    }

    /// Start editing mode
    private func startEditing() {
        editingText = label.isEmpty ? defaultLabel : label
        isEditing = true
    }

    /// Confirm the edit and exit editing mode
    private func confirmEdit() {
        let trimmedText = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        label = trimmedText.isEmpty ? defaultLabel : trimmedText
        isEditing = false
    }
}

#Preview("Session Label - Default") {
    SessionLabelEditor(label: .constant("Study"))
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Session Label - Custom") {
    SessionLabelEditor(label: .constant("Deep Work"))
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Session Label - Empty") {
    SessionLabelEditor(label: .constant(""))
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}
