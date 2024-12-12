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
    @Environment(\.modelContext) private var modelContext
    
    let existingChapterNumbers: [Int]
    
    // TODO: - will need to adjust to account for chapters that get new pages
    private func shouldAddChapter(_ chapter: Chapter) -> Bool {
        return !existingChapterNumbers.contains(chapter.number)
    }
    
    func body(content: Content) -> some View {
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
                            repo.addNewSpecialChapter(chapter, specialTitle: special.title, modelContext: modelContext)
                        }
                    }
                }
            }
    }
}

extension View {
    func fetchingChapters(existingChapterNumbers: [Int], loader: ChapterDataStore = ChapterLoaderAdapter()) -> some View {
        modifier(FetchChapterListViewModifier(repo: .init(loader: loader), existingChapterNumbers: existingChapterNumbers))
    }
}

final class ChapterListRepository: ObservableObject {
    @Published var chapters: [Chapter] = []
    @Published var specials: [Special] = []
    
    private let loader: ChapterDataStore
    
    init(loader: ChapterDataStore) {
        self.loader = loader
    }
}


// MARK: - Actions
extension ChapterListRepository {
    func loadData() async throws {
        let (storyChapters, specials) = try await loader.loadChapterLists()
        
        await setStoryChapters(storyChapters)
        await setSpecials(specials)
    }
    
    func addNewStoryChapter(_ chapter: Chapter, modelContext: ModelContext) {
        addNewSwiftDataChapter(chapter, universe: nil, modelContext: modelContext)
    }
    
    func addNewSpecialChapter(_ chapter: Chapter, specialTitle: String, modelContext: ModelContext) {
        addNewSwiftDataChapter(chapter, universe: specialTitle, modelContext: modelContext)
    }
}


// MARK: - MainActor
@MainActor
private extension ChapterListRepository {
    func setStoryChapters(_ chapters: [Chapter]) {
        self.chapters = chapters
    }
    
    func setSpecials(_ specials: [Special]) {
        self.specials = specials
    }
}


// MARK: - Private Methods
private extension ChapterListRepository {
    func addNewSwiftDataChapter(_ chapter: Chapter, universe: String?, modelContext: ModelContext) {
        print("inserting new chapter")
        modelContext.insert(SwiftDataChapter(chapter: chapter, universe: universe))
    }
}


// MARK: - Extension Dependencies
fileprivate extension SwiftDataChapter {
    convenience init(chapter: Chapter, universe: String?) {
        self.init(
            name: chapter.name,
            number: chapter.number,
            startPage: chapter.startPage,
            endPage: chapter.endPage,
            universe: universe,
            lastReadPage: nil
        )
    }
}
