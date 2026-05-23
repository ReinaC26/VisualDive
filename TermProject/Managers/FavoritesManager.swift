//
//  FavoritesManager.swift
//  TermProject
//
//

import Foundation

class FavoritesManager {
    static let shared = FavoritesManager()
    private init() {}
 
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Favorites.plist")
    }
    private var folderURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Folders.plist")
    }
 
    // Load folder
    func loadFolders() -> [FavoriteFolder] {
        guard let data = try? Data(contentsOf: folderURL) else { return [] }
        return (try? PropertyListDecoder().decode([FavoriteFolder].self, from: data)) ?? []
    }
    // Load items
    func load() -> [FavoriteItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? PropertyListDecoder().decode([FavoriteItem].self, from: data)) ?? []
    }
    // Save created folder
    func saveFolders(_ folders: [FavoriteFolder]) {
        guard let data = try? PropertyListEncoder().encode(folders) else { return }
        try? data.write(to: folderURL)
    }
 
    // Item to folder
    func save(_ items: [FavoriteItem]) {
        guard let data = try? PropertyListEncoder().encode(items) else { return }
        try? data.write(to: fileURL)
    }
 
    // Add item to folder
    func add(_ item: FavoriteItem) {
        var items = load()
        guard !items.contains(where: { $0.id == item.id }) else { return }
        items.append(item)
        save(items)
    }
    // Remove folder
    func removeFolder(name: String) {
        var folders = loadFolders()
        folders.removeAll { $0.name == name }
        saveFolders(folders)
    }
    // Remove item in folder
    func remove(id: Int) {
        var items = load()
        items.removeAll { $0.id == id }
        save(items)
    }
}
