//
//  PexelsAPIManager.swift
//  TermProject
//
//
import UIKit

// Manages API calls to Pexels for fetching photos and videos, as well as JSON decoding
class PexelsAPIManager {
    static let shared = PexelsAPIManager()
    private let apiKey = "API_KEY_HERE" // API key removed for security reason
    private let baseURL = "https://api.pexels.com"
    private init() {}
 
    private func fetch<T: Codable>(url: URL, completion: @escaping (T?) -> Void) {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let result = try? JSONDecoder().decode(T.self, from: data)
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }
 
    // Photo search
    func searchPhotos(query: String, page: Int = 1, completion: @escaping (PhotoResponse?) -> Void) {
        var components = URLComponents(string: "\(baseURL)/v1/search")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "20")
        ]
        queryItems.append(URLQueryItem(name: "query", value: query))
        components.queryItems = queryItems
        guard let url = components.url else { return }
        fetch(url: url, completion: completion)
    }
 
    // Video search
    func searchVideos(query: String, page: Int = 1, completion: @escaping (VideoResponse?) -> Void) {
        var components = URLComponents(string: "\(baseURL)/v1/videos/search")!
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "20")
        ]
        components.queryItems = queryItems
        guard let url = components.url else { return }
        fetch(url: url, completion: completion)
    }
}
