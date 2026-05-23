//
//  FavoriteItem.swift
//  TermProject
//
//
import Foundation

struct FavoriteItem: Codable {
    let id: Int
    let imageURL: String
    let title: String
    var folderName: String
    let isVideo: Bool
}
