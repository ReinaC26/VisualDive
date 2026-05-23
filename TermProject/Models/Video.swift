//
//  Video.swift
//  TermProject
//
//
import Foundation

struct VideoResponse: Codable {
    let page: Int
    let perPage: Int
    let totalResults: Int
    let videos: [Video]

    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case totalResults = "total_results"
        case videos
    }
}

struct Video: Codable {
    let id: Int
    let width: Int
    let height: Int
    let url: String
    let image: String?
    let duration: Int
    let user: VideoUser
    let videoFiles: [VideoFile]
    let videoPictures: [VideoPicture]

    enum CodingKeys: String, CodingKey {
        case id, width, height, url, image, duration, user
        case videoFiles = "video_files"
        case videoPictures = "video_pictures"
    }
}

struct VideoUser: Codable {
    let id: Int?
    let name: String
    let url: String?
}

struct VideoFile: Codable {
    let link: String
    let quality: String?  
    let fileType: String?
    let width: Int?
    let height: Int?
    let fps: Double?
    let size: Int?

    enum CodingKeys: String, CodingKey {
        case link, quality, width, height, fps, size
        case fileType = "file_type"
    }
}

struct VideoPicture: Codable {
    let picture: String
}
