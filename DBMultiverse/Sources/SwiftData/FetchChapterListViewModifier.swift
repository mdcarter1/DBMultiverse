//
//  FetchChapterListViewModifier.swift
//  DBMultiverse
//
//  Created by Nikolai Nobadi on 12/11/24.
//

import SwiftUI
import SwiftData
import NnSwiftUIKit

struct FetchChapterListViewModifier: ViewModifier {
    @StateObject var repo: ChapterListRepository
    @Environment(\.isPreview) private var isPreview
    @Environment(\.modelContext) private var modelContext
    
    let existingChapterNumbers: [Int]
    
    // TODO: - will need to adjust to account for chapters that get new pages
    private func shouldAddChapter(_ chapter: Chapter) -> Bool {
        return !existingChapterNumbers.contains(chapter.number)
    }
    
    func body(content: Content) -> some View {
        if isPreview {
            content
        } else {
            content
                .asyncTask {
                    try await repo.loadData()
                }
                .onChange(of: repo.chapters) { _, newValue in
                    newValue.forEach { chapter in
                        if shouldAddChapter(chapter) {
                            repo.addNewStoryChapter(chapter, modelContext: modelContext)
                        }
                    }
                }
                .onChange(of: repo.specials) { _, newValue in
                    newValue.forEach { special in
                        special.chapters.forEach { chapter in
                            if shouldAddChapter(chapter) {
                                repo.addNewSpecialChapter(chapter, universe: special.universe, modelContext: modelContext)
                            }
                        }
                    }
                }
        }
    }
}

extension View {
    /// Applies a modifier to handle the fetching and persistence of chapters.
    ///
    /// This method uses `FetchChapterListViewModifier` to automatically fetch chapter data and add
    /// it to the database, updating the UI when the data changes. It is particularly useful for
    /// integrating asynchronous chapter loading into a SwiftUI view.
    ///
    /// - Parameters:
    ///   - existingChapterNumbers: An array of chapter numbers that already exist in the database.
    ///   - loader: A `ChapterDataStore` instance responsible for fetching the chapter data. The default value is `ChapterLoaderAdapter()`.
    /// - Returns: A modified view that includes chapter fetching logic.
    func fetchingChapters(existingChapterNumbers: [Int], loader: ChapterDataStore = ChapterLoaderAdapter()) -> some View {
        modifier(FetchChapterListViewModifier(repo: .init(loader: loader), existingChapterNumbers: existingChapterNumbers))
    }
}
