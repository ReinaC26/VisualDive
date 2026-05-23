//
//  SearchViewController.swift
//  TermProject
//
//

import UIKit

// MARK: - Delegate Protocol
// Handles tap from the collection view cell (favorite/save button)
protocol MediaCellDelegate: AnyObject {
    func didTapFavorite(for cell: MediaCollectionViewCell)
}

// MARK: - Collection View Cell
// Displays either a photo or video item
class MediaCollectionViewCell: UICollectionViewCell {
    weak var delegate: MediaCellDelegate?
    
    // Store either a photo or video depending on mode
    var photo: Photo?
    var video: Video?

    // Main thumbnail image
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Favorite/save button look
    let favoriteButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "star"), for: .normal)
        btn.setImage(UIImage(systemName: "star.fill"), for: .selected)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // Video play icon
    let videoIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        iv.tintColor = .white
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        contentView.addSubview(imageView)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(videoIcon)

        favoriteButton.addTarget(self,
                                 action: #selector(favTapped),
                                 for: .touchUpInside)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            favoriteButton.widthAnchor.constraint(equalToConstant: 28),
            favoriteButton.heightAnchor.constraint(equalToConstant: 28),

            videoIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            videoIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            videoIcon.widthAnchor.constraint(equalToConstant: 36),
            videoIcon.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // User tapped save button
    @objc private func favTapped() {
        favoriteButton.isSelected.toggle()
        delegate?.didTapFavorite(for: self)
    }

    // Configure cell for photo
    func configure(with photo: Photo) {
        self.photo = photo
        self.video = nil

        videoIcon.isHidden = true
        imageView.loadImage(from: photo.src.medium)

        let isFav = FavoritesManager.shared.load().contains { $0.id == photo.id }
        favoriteButton.isSelected = isFav
    }

    // Configure cell for video
    func configure(with video: Video) {
        self.video = video
        self.photo = nil

        videoIcon.isHidden = false
        imageView.loadImage(from: video.image ?? "")

        let isFav = FavoritesManager.shared.load().contains { $0.id == video.id }
        favoriteButton.isSelected = isFav
    }
}

// MARK: - Search Screen Controller
class SearchViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mediaTypeSegment: UISegmentedControl!

    // Data storage
    private var photos: [Photo] = []
    private var videos: [Video] = []

    private var currentQuery = "nature" // Default query
    private var currentPage = 1
    private var isFetchingMore = false

    // Helper: check which segment is active
    private var isShowingVideos: Bool {
        mediaTypeSegment.selectedSegmentIndex == 1
    }

    // Helper: current item count
    private var itemCount: Int {
        isShowingVideos ? videos.count : photos.count
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        searchBar.delegate = self
        fetchMedia()
    }

    // MARK: - Setup Collection View
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MediaCollectionViewCell.self,
                                 forCellWithReuseIdentifier: "MediaCell")

        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 8
        let width = (collectionView.bounds.width - padding * 3) / 2

        layout.itemSize = CGSize(width: width, height: width * 1.2)
        layout.minimumInteritemSpacing = padding
        layout.minimumLineSpacing = padding
        layout.sectionInset = UIEdgeInsets(top: padding,left: padding,
                                           bottom: padding,right: padding)

        collectionView.collectionViewLayout = layout
    }

    // MARK: - Segment switch (Photos/Videos)
    @IBAction func mediaTypeChanged(_ sender: UISegmentedControl) {
        currentPage = 1
        photos.removeAll()
        videos.removeAll()
        collectionView.reloadData()
        fetchMedia()
    }

    // MARK: - API Fetch
    // Fetches photos or videos from Pexels API based on current search query and page
    private func fetchMedia(loadMore: Bool = false) {
        guard !isFetchingMore else { return }
        isFetchingMore = true

        currentPage = loadMore ? currentPage + 1 : 1

        if isShowingVideos {

            PexelsAPIManager.shared.searchVideos(
                query: currentQuery,
                page: currentPage
            ) { [weak self] response in
                guard let self = self else { return }
                self.isFetchingMore = false

                guard let response = response else { return }

                self.videos.append(contentsOf: response.videos)
                self.collectionView.reloadData()
            }
        } else {
            PexelsAPIManager.shared.searchPhotos(
                query: currentQuery,
                page: currentPage
            ) { [weak self] response in
                guard let self = self else { return }
                self.isFetchingMore = false

                guard let response = response else { return }

                self.photos.append(contentsOf: response.photos)
                self.collectionView.reloadData()
            }
        }
    }
}

// MARK: - Collection View
extension SearchViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return itemCount
    }
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "MediaCell",
            for: indexPath
        ) as! MediaCollectionViewCell

        cell.delegate = self

        if isShowingVideos {
            cell.configure(with: videos[indexPath.item])
        } else {
            cell.configure(with: photos[indexPath.item])
        }
        return cell
    }

    // Trigger load more when user scrolls near end
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {

        if indexPath.item == itemCount - 5 {
            fetchMedia(loadMore: true)
        }
    }

    // Open detail screen
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        let vc = storyboard?.instantiateViewController(
            withIdentifier: "ItemDetailViewController"
        ) as! ItemDetailViewController

        if isShowingVideos {
            vc.video = videos[indexPath.item]
        } else {
            vc.photo = photos[indexPath.item]
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Favorite handling
extension SearchViewController: MediaCellDelegate {
    func didTapFavorite(for cell: MediaCollectionViewCell) {
        guard let item = buildFavoriteItem(from: cell) else { return }
        presentFolderPicker(for: item)
    }

    // Convert cell content into FavoriteItem model
    private func buildFavoriteItem(from cell: MediaCollectionViewCell) -> FavoriteItem? {

        if let photo = cell.photo {
            return FavoriteItem(
                id: photo.id,
                imageURL: photo.src.medium,
                title: photo.photographer,
                folderName: "",
                isVideo: false
            )
        }

        if let video = cell.video {
            return FavoriteItem(
                id: video.id,
                imageURL: video.videoFiles.first?.link ?? "",
                title: video.user.name,
                folderName: "",
                isVideo: true
            )
        }
        return nil
    }

    // Show folder selection menu (user can select which folder thwy want to save to)
    private func presentFolderPicker(for item: FavoriteItem) {
        let folders = FavoritesManager.shared.loadFolders()
        let alert = UIAlertController(
            title: "Save to Folder",
            message: nil,
            preferredStyle: .actionSheet
        )

        for folder in folders {
            alert.addAction(UIAlertAction(title: folder.name, style: .default) { _ in
                self.save(item, to: folder)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func save(_ item: FavoriteItem, to folder: FavoriteFolder) {
        var updated = item
        updated.folderName = folder.name
        FavoritesManager.shared.add(updated)
    }
}

// MARK: - Search Bar
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        // Reset to default query when user clears search
        if searchText.isEmpty {
            currentQuery = "nature" // default query
            photos.removeAll()
            videos.removeAll()
            currentPage = 1

            collectionView.reloadData()
            fetchMedia()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.isEmpty else { return }

        currentQuery = text
        searchBar.resignFirstResponder()

        photos.removeAll()
        videos.removeAll()

        collectionView.reloadData()
        fetchMedia()
    }
}
