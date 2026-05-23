//
//  UIImageViewAndLoading.swift
//  TermProject
//
//

import UIKit
private let imageCache = NSCache<NSString, UIImage>()
 
extension UIImageView {
    // Loads an image and sets it on the image view and checks cache first to improve performance and reduce network calls
    func loadImage(from urlString: String) {
        image = nil
        guard !urlString.isEmpty else { return }
 
        if let cached = imageCache.object(forKey: urlString as NSString) {
            image = cached
            return
        }
        // Convert string into a valid URL
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let img = UIImage(data: data) else { return }

            DispatchQueue.main.async {
                self?.image = img
                self?.setNeedsLayout()
                self?.layoutIfNeeded()
            }
        }.resume()
    }
}
 
