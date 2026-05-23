//
//  ItemDetailViewController.swift
//  TermProject
//
//

import UIKit
import AVKit
import Photos
import AVFoundation

class ItemDetailViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mediaImageView: UIImageView!
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var workshopButton: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var mainColorLabel: UILabel!
    @IBOutlet weak var mainColor: UIView!

    // MARK: - Data passed from previous screen
    var photo: Photo?
    var video: Video?
    var favoriteItem: FavoriteItem?

    // MARK: - video player state
    private var playerVC: AVPlayerViewController?
    private var videoURL: URL?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup audio first so video plays with sound immediately
        configureAudioSession()
        setupUI()

        // Decide what kind of item to show
        if let favorite = favoriteItem {
            configureFromFavorite(favorite)
        }
        else if let photo = photo {
            configureFor(photo: photo)
        }
        else if let video = video {
            configureFor(video: video)
        }
    }

    // MARK: - Favorite Item
    // Used when item coming from Favorites screen
    private func configureFromFavorite(_ item: FavoriteItem) {
        infoLabel.text = item.title
        detailLabel.text = item.isVideo ? "Video" : "Photo"

        // Reset UI state depending on type
        mediaImageView.isHidden = item.isVideo
        videoContainerView.isHidden = !item.isVideo
        mainColor.isHidden = true
        mainColorLabel.isHidden = true

        // For Video
        if item.isVideo {
            // For video, show player and enable workshop option
            workshopButton.isHidden = false
            guard let url = URL(string: item.imageURL) else { return }
            videoURL = url
            embedPlayer(url: url)

        } else {
            // For photo, hide workshop button and load image
            workshopButton.isHidden = true
            mediaImageView.loadImage(from: item.imageURL)
        }
    }

    // MARK: - Audio setup
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error:", error)
        }
    }

    // MARK: - UI Styling
    private func setupUI() {
        mainColor.layer.borderWidth = 1
        mainColor.layer.borderColor = UIColor.systemGray4.cgColor

        downloadButton.layer.cornerRadius = 15
        downloadButton.layer.borderWidth = 1
        downloadButton.layer.borderColor = UIColor.systemGray3.cgColor

        workshopButton.layer.cornerRadius = 15
        workshopButton.layer.borderWidth = 1
        workshopButton.layer.borderColor = UIColor.systemGray3.cgColor
    }

    // MARK: - Photo configuration
    private func configureFor(photo: Photo) {
        mediaImageView.isHidden = false
        videoContainerView.isHidden = true
        workshopButton.isHidden = true

        mediaImageView.loadImage(from: photo.src.medium)

        infoLabel.text = "Photographer: \(photo.photographer)"
        detailLabel.text = "Size: \(photo.width) × \(photo.height)"

        let hexString = photo.avgColor
        let color = hexString.hexColor ?? UIColor.systemGray

        mainColor.backgroundColor = color
        mainColorLabel.text = hexString
        mainColorLabel.textColor = color
    }

    // MARK: - Video configuration
    private func configureFor(video: Video) {
        mediaImageView.isHidden = true
        videoContainerView.isHidden = false
        workshopButton.isHidden = false

        infoLabel.text = "Creator: \(video.user.name)"
        detailLabel.text = "Size: \(video.width) × \(video.height)"

        mainColor.isHidden = true
        mainColorLabel.isHidden = true

        let urlString =
            video.videoFiles.first(where: { $0.quality == "hd" })?.link
            ?? video.videoFiles.first?.link

        if let urlString,
           let url = URL(string: urlString) {
            videoURL = url
            embedPlayer(url: url)
        }
    }

    // MARK: - Video Player embedding
    private func embedPlayer(url: URL) {
        let player = AVPlayer(url: url)
        let pvc = AVPlayerViewController()
        pvc.player = player

        addChild(pvc)
        videoContainerView.addSubview(pvc.view)

        pvc.view.frame = videoContainerView.bounds
        pvc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        pvc.didMove(toParent: self)

        player.play()
        playerVC = pvc
    }

    // MARK: - Actions
    // Download Button
    @IBAction func downloadTapped(_ sender: UIButton) {
        // For photo
        if let photo = photo {
            downloadPhoto(from: photo.src.original)
            return
        }

        // For favorites item
        if let item = favoriteItem, !item.isVideo {
            downloadPhoto(from: item.imageURL)
            return
        }

        // For video
        if let url = videoURL {
            downloadVideo(from: url)
        }
    }
    
    // Workshop Button, make sure it works for both search->detail->workshop and favorites->detail->workshop
    @IBAction func workshopTapped(_ sender: UIButton) {
        let video = self.video ?? {
            guard let item = favoriteItem, item.isVideo else { return nil }
            return Video(
                id: item.id,
                width: 0,
                height: 0,
                url: "",
                image: item.imageURL,
                duration: 0,
                user: VideoUser(id: nil, name: item.title, url: nil),
                videoFiles: [
                    VideoFile(link: item.imageURL, quality: "hd", fileType: nil,
                              width: nil, height: nil, fps: nil, size: nil)
                ],
                videoPictures: []
            )
        }()
        guard let video else { return }
        VideoWorkshopManager.shared.add(video)
        
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "VideoWorkshopViewController"
        ) as! VideoWorkshopViewController

        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Download photo
    private func downloadPhoto(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        downloadButton.isEnabled = false
        downloadButton.setTitle("Downloading...", for: .normal)

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                self?.downloadButton.isEnabled = true
                self?.downloadButton.setTitle("Download", for: .normal)
            }

            guard let data,
                  let image = UIImage(data: data) else { return }

            PHPhotoLibrary.requestAuthorization { status in

                guard status == .authorized else { return }

                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, _ in
                    DispatchQueue.main.async {
                        self?.showAlert(success ? "Saved!" : "Save failed")
                    }
                }
            }

        }.resume()
    }

    // MARK: - Download video
    private func downloadVideo(from url: URL) {
        downloadButton.isEnabled = false
        downloadButton.setTitle("Downloading...", for: .normal)

        URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in

            DispatchQueue.main.async {
                self?.downloadButton.isEnabled = true
                self?.downloadButton.setTitle("Download", for: .normal)
            }

            guard let tempURL, error == nil else { return }

            let fileManager = FileManager.default
            let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let localURL = documents.appendingPathComponent(UUID().uuidString + ".mp4")

            do {
                try fileManager.copyItem(at: tempURL, to: localURL)
            } catch {
                print("Copy failed:", error)
                return
            }

            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else { return }

                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
                }) { success, _ in
                    DispatchQueue.main.async {
                        self?.showAlert(success ? "Saved!" : "Save failed")
                    }
                }
            }
        }.resume()
    }

    // MARK: - Alert helper
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message,preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
