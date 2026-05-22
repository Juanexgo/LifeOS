import SwiftUI
import SwiftData
import DesignSystem
import SharedUI
import PersistenceKit

@MainActor
struct NotesScreen: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: [SortDescriptor(\Note.updatedAt, order: .reverse)])
    private var notes: [Note]

    @State private var selected: Note? = nil
    @State private var search: String = ""

    private var filtered: [Note] {
        let needle = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return notes }
        return notes.filter {
            $0.title.lowercased().contains(needle) ||
            $0.body.lowercased().contains(needle)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                if notes.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $search, prompt: "Search notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        let note = Note()
                        ctx.insert(note)
                        try? ctx.save()
                        selected = note
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                    }
                }
            }
            .sheet(item: $selected) { note in
                NoteEditor(note: note) { result in
                    handle(result: result, for: note)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.xs.value) {
                ForEach(filtered) { note in
                    NoteRow(note: note) {
                        selected = note
                    }
                    .contextMenu {
                        Button {
                            note.isPinned.toggle()
                            note.touch()
                            try? ctx.save()
                        } label: {
                            Label(note.isPinned ? "Unpin" : "Pin",
                                  systemImage: note.isPinned ? "pin.slash" : "pin")
                        }
                        Button(role: .destructive) {
                            ctx.delete(note)
                            try? ctx.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, .md)
            .padding(.top, .sm)
            .padding(.bottom, .xl)
            .animation(Motion.gentle, value: filtered.map(\.id))
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md.value) {
            Image(systemName: "note.text")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Palette.textTertiary)
            Text("No notes yet")
                .font(Type.titleCard)
                .foregroundStyle(Palette.textPrimary)
            Text("Capture a thought or paste markdown.")
                .font(Type.bodySoft)
                .foregroundStyle(Palette.textSecondary)
            GlassButton("New note", systemImage: "square.and.pencil") {
                let note = Note()
                ctx.insert(note)
                try? ctx.save()
                selected = note
            }
            .padding(.top, Spacing.sm.value)
        }
        .padding(.lg)
    }

    private func handle(result: NoteEditor.Result, for note: Note) {
        switch result {
        case .saved:
            note.touch()
            try? ctx.save()
            Haptics.commit()
        case .deleted:
            ctx.delete(note)
            try? ctx.save()
            Haptics.warn()
        case .dismissed:
            // Auto-save on dismiss; discard if empty.
            if note.title.isEmpty && note.body.isEmpty {
                ctx.delete(note)
            } else {
                note.touch()
            }
            try? ctx.save()
        }
        selected = nil
    }
}
