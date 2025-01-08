//
//  ChapterListView.swift
//
//
//  Created by Nikolai Nobadi on 1/7/25.
//

import SwiftUI
import NnSwiftUIKit

struct ChapterListView: View {
    let imageSize: CGSize
    let sections: [ChapterSection]
    let makeImageURL: (Chapter) -> URL?
    let unreadChapter: (Chapter) -> Void
    
    var body: some View {
        List(sections, id: \.title) { section in
            DynamicSection(section.title) {
                ForEach(section.chapters, id: \.name) { chapter in
                    ChapterRow(chapter, url: makeImageURL(chapter), imageSize: imageSize)
                        .asNavLink(chapter)
                        .withUnreadSwipeAction(isActive: chapter.didFinishReading) {
                            unreadChapter(chapter)
                        }
                }
            }
        }
    }
}


// MARK: - Row
fileprivate struct ChapterRow: View {
    let url: URL?
    let chapter: Chapter
    let imageSize: CGSize
    
    init(_ chapter: Chapter, url: URL?, imageSize: CGSize) {
        self.url = url
        self.chapter = chapter
        self.imageSize = imageSize
    }
    
    var body: some View {
        HStack {
            CustomAsyncImage(url: url, size: imageSize)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(chapter.rowTitle)
                    .withFont(.headline, autoSizeLineLimit: 1)
                
                Text(chapter.pageRangeText)
                    .withFont(textColor: .secondary)
                
                if chapter.didFinishReading {
                    Text("Finished")
                        .padding(.horizontal)
                        .withFont(.caption, textColor: .red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ChapterSection {
    let type: ChapterSectionType
    let chapters: [Chapter]
    
    var isCurrentChapterSection: Bool {
        return type == .currentChapter
    }
    
    var title: String {
        switch type {
        case .currentChapter:
            return "Current Chapter"
        case .chapterList(let title):
            return title
        }
    }
}

enum ChapterSectionType: Equatable {
    case currentChapter
    case chapterList(title: String)
}

extension View {
    var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}

extension Chapter {
    var rowTitle: String {
        return "\(number) - \(name)"
    }
    
    var pageRangeText: String {
        return "Pages: \(startPage) - \(endPage)"
    }
}

extension View {
    func withUnreadSwipeAction(isActive: Bool, action: @escaping () -> Void) -> some View {
        withSwipeAction(info: .init(prompt: "Unread"), systemImage: "eraser.fill", tint: .gray, edge: .leading, isActive: isActive, action: action)
    }
}
