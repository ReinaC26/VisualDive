//
//  VideoWorkshopViewController.swift
//  TermProject
//
//
import UIKit
import AVKit
import AVFoundation

class VideoWorkshopViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var videoLabel1: UILabel!
    @IBOutlet weak var videoLabel2: UILabel!

    @IBOutlet weak var videoContainer1: UIView!
    @IBOutlet weak var videoContainer2: UIView!

    @IBOutlet weak var scrubber1: UISlider!
    @IBOutlet weak var scrubber2: UISlider!

    @IBOutlet weak var startTimeLabel1: UILabel!
    @IBOutlet weak var endTimeLabel1: UILabel!

    @IBOutlet weak var startTimeLabel2: UILabel!
    @IBOutlet weak var endTimeLabel2: UILabel!

    @IBOutlet weak var playBothButton: UIButton!
    @IBOutlet weak var pauseBothButton: UIButton!
    @IBOutlet weak var selectVideo1Button: UIButton!
    @IBOutlet weak var selectVideo2Button: UIButton!

    // MARK: - Players
    private var player1: AVPlayer?
    private var player2: AVPlayer?

    private var playerVC1: AVPlayerViewController?
    private var playerVC2: AVPlayerViewController?

    // Observers used to sync UI with playback time
    private var observer1: Any?
    private var observer2: Any?

    // Prevent reloading videos multiple times
    private var didLoad = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Labels for slots
        videoLabel1.text = "Video 1"
        videoLabel2.text = "Video 2"

        setupButtons()
        setupScrubbers()
        setupTimeLabels()
        setupEmptyStateUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Ensure videos only load once
        guard !didLoad else { return }
        didLoad = true

        loadVideosFromManager()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause playback when leaving screen
        player1?.pause()
        player2?.pause()

        // Clean up observers to avoid memory leaks
        if let o1 = observer1 {
            player1?.removeTimeObserver(o1)
            observer1 = nil
        }

        if let o2 = observer2 {
            player2?.removeTimeObserver(o2)
            observer2 = nil
        }
    }

    // MARK: - Load videos
    private func loadVideosFromManager() {
        let videos = VideoWorkshopManager.shared.selectedVideos

        // First slot
        if videos.count > 0 {
            load(video: videos[0], slot: 1)
        }

        // Second slot
        if videos.count > 1 {
            load(video: videos[1], slot: 2)
        }
    }

    // MARK: - UI Setup
    private func setupButtons() {
        [playBothButton, pauseBothButton, selectVideo1Button, selectVideo2Button].forEach {
            $0?.layer.cornerRadius = 8
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = UIColor.systemGray3.cgColor
        }

        playBothButton.setTitle("Play Both", for: .normal)
        pauseBothButton.setTitle("Pause Both", for: .normal)

        selectVideo1Button.setTitle("▶", for: .normal)
        selectVideo2Button.setTitle("▶", for: .normal)
    }

    // Scrubbers
    private func setupScrubbers() {
        scrubber1.minimumValue = 0
        scrubber2.minimumValue = 0

        scrubber1.addTarget(self, action: #selector(scrubber1Changed), for: .valueChanged)
        scrubber2.addTarget(self, action: #selector(scrubber2Changed), for: .valueChanged)
    }

    // Start and end time labels
    private func setupTimeLabels() {
        [startTimeLabel1, startTimeLabel2, endTimeLabel1, endTimeLabel2].forEach {
            $0?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            $0?.textColor = .secondaryLabel
        }
    }
    // Default look when no videos are added
    private func setupEmptyStateUI() {
        videoContainer1.backgroundColor = .systemGray3
        videoContainer2.backgroundColor = .systemGray3

        scrubber1.value = 0
        scrubber2.value = 0
    }

    // MARK: - Load video into slot
    private func load(video: Video, slot: Int) {
        guard let link = video.videoFiles.first(where: { $0.quality == "hd" })?.link
                ?? video.videoFiles.first?.link,
              let url = URL(string: link) else { return }

        let player = AVPlayer(url: url)
        let pvc = AVPlayerViewController()
        pvc.player = player
        pvc.showsPlaybackControls = false

        let container = (slot == 1) ? videoContainer1 : videoContainer2

        // Replace existing player if needed
        if slot == 1 {
            playerVC1?.view.removeFromSuperview()
            playerVC1?.removeFromParent()

            player1 = player
            playerVC1 = pvc
        } else {
            playerVC2?.view.removeFromSuperview()
            playerVC2?.removeFromParent()

            player2 = player
            playerVC2 = pvc
        }

        addChild(pvc)
        pvc.view.translatesAutoresizingMaskIntoConstraints = false
        container?.addSubview(pvc.view)

        NSLayoutConstraint.activate([
            pvc.view.topAnchor.constraint(equalTo: container!.topAnchor),
            pvc.view.leadingAnchor.constraint(equalTo: container!.leadingAnchor),
            pvc.view.trailingAnchor.constraint(equalTo: container!.trailingAnchor),
            pvc.view.bottomAnchor.constraint(equalTo: container!.bottomAnchor)
        ])

        pvc.didMove(toParent: self)

        // Load duration
        Task {
            do {
                let asset = player.currentItem?.asset
                let duration = try await asset?.load(.duration) ?? .zero
                let seconds = CMTimeGetSeconds(duration)

                await MainActor.run {
                    if slot == 1 {
                        self.scrubber1.maximumValue = Float(seconds)
                        self.endTimeLabel1.text = self.formatTime(seconds)
                        self.startTimeLabel1.text = "0:00"
                    } else {
                        self.scrubber2.maximumValue = Float(seconds)
                        self.endTimeLabel2.text = self.formatTime(seconds)
                        self.startTimeLabel2.text = "0:00"
                    }
                }
            } catch {
                print("Duration error:", error)
            }
        }
    }

    // MARK: - Scrubber control
    @objc func scrubber1Changed(_ sender: UISlider) {
        let seconds = Double(sender.value)
        player1?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        startTimeLabel1.text = formatTime(seconds)
    }

    @objc func scrubber2Changed(_ sender: UISlider) {
        let seconds = Double(sender.value)
        player2?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        startTimeLabel2.text = formatTime(seconds)
    }

    // MARK: - Playback control
    // Play both video
    @IBAction func playBothTapped(_ sender: UIButton) {
        player1?.play()
        player2?.play()
        startObservers()
    }
    // Pause both video
    @IBAction func pauseBothTapped(_ sender: UIButton) {
        player1?.pause()
        player2?.pause()
    }

    // MARK: - Individual play buttons
    @IBAction func selectVideo1Tapped(_ sender: UIButton) {
        player1?.play()
    }

    @IBAction func selectVideo2Tapped(_ sender: UIButton) {
        player2?.play()
    }

    // MARK: - Playback observers
    // Checks the current playback time of the video
    private func startObservers() {
        if let o1 = observer1 { player1?.removeTimeObserver(o1) }
        if let o2 = observer2 { player2?.removeTimeObserver(o2) }

        observer1 = player1?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            let seconds = CMTimeGetSeconds(time)
            self.scrubber1.value = Float(seconds)
            self.startTimeLabel1.text = self.formatTime(seconds)
        }

        observer2 = player2?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            let seconds = CMTimeGetSeconds(time)
            self.scrubber2.value = Float(seconds)
            self.startTimeLabel2.text = self.formatTime(seconds)
        }
    }

    // MARK: - Helper
    private func formatTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
