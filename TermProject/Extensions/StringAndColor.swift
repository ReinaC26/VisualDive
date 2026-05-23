//
//  StringAndColor.swift
//  TermProject
//
//
import Foundation
import UIKit

// Convert hex color string to UIColor
extension String {
    var hexColor: UIColor? {
        var hex = trimmingCharacters(in: .whitespaces)
        if hex.hasPrefix("#") { hex = String(hex.dropFirst()) }
        guard hex.count == 6, let val = UInt64(hex, radix: 16) else { return nil }
        return UIColor(
            red:   CGFloat((val >> 16) & 0xFF) / 255,
            green: CGFloat((val >> 8)  & 0xFF) / 255,
            blue:  CGFloat(val         & 0xFF) / 255,
            alpha: 1
        )
    }
}
// Convert UIColor to hex string
extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}
