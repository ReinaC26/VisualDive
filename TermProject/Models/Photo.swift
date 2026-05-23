//
//  Photo.swift
//  TermProject
//
//

import Foundation
 
struct PhotoResponse: Codable {
    let photos: [Photo]
    let totalResults: Int
    let nextPage: String?
    enum CodingKeys: String, CodingKey {
        case photos
        case totalResults = "total_results"
        case nextPage = "next_page"
    }
}
 
struct Photo: Codable {
    let id: Int
    let width: Int
    let height: Int
    let url: String
    let photographer: String
    let photographerUrl: String
    let photographerId: Int
    let avgColor: String
    let src: PhotoSrc

    enum CodingKeys: String, CodingKey {
        case id, width, height, url, photographer, src
        case photographerUrl = "photographer_url"
        case photographerId = "photographer_id"
        case avgColor = "avg_color"
    }
}
 
struct PhotoSrc: Codable {
    let original: String
    let medium: String
    let small: String
}
