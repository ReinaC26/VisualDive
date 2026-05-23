//
//  WorkshopManager.swift
//  TermProject
//
//
import Foundation

final class VideoWorkshopManager {
    static let shared = VideoWorkshopManager()

    private init() {}

    private(set) var selectedVideos: [Video] = []

    // Keeps only the 2 most recently added videos, and a third video is added, the oldest one is automatically removed 
    func add(_ video: Video) {
        if selectedVideos.count >= 2 {
            selectedVideos.removeFirst()
        }
        selectedVideos.append(video)
    }

    func clear() {
        selectedVideos.removeAll()
    }
}
