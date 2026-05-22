import SwiftUI
import DesignSystem
import SharedUI
import PersistenceKit

/// Markdown editor with edit/preview toggle. `AttributedString(markdown:)`
/// handles rendering — that's enough for headings, lists, bold/italic, links,
/// inline code. Full markdown features (code blocks with syntax highlighting,
/// images) wait for Phase 5c when we wire down-and-MarkdownUI.
struct NoteEditor: View {
    enum Result { case saved, deleted, dismissed }

    @Bindable var note: Note
    let onDismiss: (Result) -> Void

    @State private var mode: Mode = .edit
    @FocusState private var bodyFocused: Bool

    enum Mode: Hashable { case edit, preview }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.surface.ignoresSafeArea()

                VStack(spacing: 0) {
                    TextField("Title", text: $note.title)
                        .font(Type.titleScreen)
                        .padding(.horizontal, .md)
                        .padding(.top, .md)

                    Divider().padding(.vertical, .sm)

                    Group {
                        switch mode {
                        case .edit:
                            TextEditor(text: $note.body)
                                .focused($bodyFocused)
                                .font(Type.body)
                                .scrollContentBackground(.hidden)
                                .background(Palette.surface)
                        case .preview:
                            ScrollView {
                                Text(renderedMarkdown)
                                    .textSelection(.enabled)
                                    .font(Type.body)
                                    .foregroundStyle(Palette.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, .md)
                            }
                        }
                    }
                    .padding(.horizontal, mode == .edit ? Spacing.sm.value : 0)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onDismiss(.dismissed) }
                }
                ToolbarItem(placement: .principal) {
                    Picker("Mode", selection: $mode) {
                        Text("Edit").tag(Mode.edit)
                        Text("Preview").tag(Mode.preview)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            note.isPinned.toggle()
                        } label: {
                            Label(note.isPinned ? "Unpin" : "Pin",
                                  systemImage: note.isPinned ? "pin.slash" : "pin")
                        }
                        Button("Save") { onDismiss(.saved) }
                        Divider()
                        Button("Delete", role: .destructive) { onDismiss(.deleted) }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .onAppear {
                if note.title.isEmpty && note.body.isEmpty {
                    bodyFocused = true
                }
            }
        }
    }

    private var renderedMarkdown: AttributedString {
        // Multiline markdown — block-level constructs require .inlineOnlyPreservingWhitespace
        // off and .full enabled.
        (try? AttributedString(
            markdown: note.body,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        )) ?? AttributedString(note.body)
    }
}
