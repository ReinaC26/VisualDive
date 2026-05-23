//
//  ColorPaletteViewController.swift
//  TermProject
//
//

import UIKit
import CoreImage

class ColorPaletteViewController: UIViewController {
    // MARK: - Outlets (UI elements from storyboard)
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var extractedColorsLabel: UILabel!
    @IBOutlet weak var mainColorView: UIView!
    @IBOutlet weak var mainColorLabel: UILabel!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Configure UI once view is loaded
        setupUI()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Image preview
        selectedImageView.contentMode = .scaleAspectFit
        selectedImageView.clipsToBounds = true
        selectedImageView.layer.cornerRadius = 12
        selectedImageView.backgroundColor = .systemGray3
        selectedImageView.isHidden = false

        // Label describing extracted color
        extractedColorsLabel.text = "Main Color"
        extractedColorsLabel.font = .systemFont(ofSize: 18, weight: .medium)
        extractedColorsLabel.textColor = .black
        extractedColorsLabel.isHidden = false

        // View that displays a photo's extracted main color
        mainColorView.layer.cornerRadius = 12
        mainColorView.clipsToBounds = true
        mainColorView.backgroundColor = .white
        mainColorView.isHidden = false

        // Hex label for the extracted color
        mainColorLabel.font = .systemFont(ofSize: 18, weight: .medium)
        mainColorLabel.textColor = .black
        mainColorLabel.isHidden = true

        // Upload button UI
        uploadButton.setTitle("Upload a photo", for: .normal)
        uploadButton.setImage(UIImage(systemName: "photo.badge.plus"), for: .normal)
        uploadButton.layer.cornerRadius = 10
        uploadButton.layer.borderWidth = 1
        uploadButton.layer.borderColor = UIColor.systemGray3.cgColor
    }

    // MARK: - User Action (Pick image from their phone's photo app)
    @IBAction func uploadTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Image extraction (find main color)
    private func extractMainColor(from image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }

        let context = CIContext()
        let filter = CIFilter(name: "CIAreaAverage")!

        // Configure filter to compute average color across entire image
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)

        guard let output = filter.outputImage else { return }

        // Buffer to store RGBA values
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        // Convert RGB values into UIColor
        let color = UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: 1
        )

        let hex = color.toHexString()

        // Update UI
        DispatchQueue.main.async { [weak self] in
            self?.showMainColor(color: color, hex: hex)
        }
    }

    // MARK: - UI update after extraction
    private func showMainColor(color: UIColor, hex: String) {
        selectedImageView.isHidden = false
        extractedColorsLabel.isHidden = false
        mainColorView.isHidden = false
        mainColorLabel.isHidden = false
        mainColorView.backgroundColor = color
        mainColorLabel.text = hex
    }
}

// MARK: - Image Picker
extension ColorPaletteViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else { return }

        // Show selected image
        selectedImageView.image = image

        // Run color extraction in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.extractMainColor(from: image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
