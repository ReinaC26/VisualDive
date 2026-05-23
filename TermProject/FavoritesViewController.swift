//
//  FavoritesViewController.swift
//  TermProject
//
//

import UIKit

class FavoritesViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!

    // MARK: - Data Sources
    private var allItems: [FavoriteItem] = []
    private var folders: [FavoriteFolder] = []

    // Determines whether to show folders or saved items
    private var isShowingFolders: Bool {
        segmentControl.selectedSegmentIndex == 0
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupAddButton()
    }

    override func viewWillAppear(_ animated: Bool) {super.viewWillAppear(animated)
        // Refresh data every time the screen appears
        loadData()
    }

    // MARK: - Setup
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FavoriteItemCell.self, forCellReuseIdentifier: "ItemCell")
    }

    // Add folder button
    private func setupAddButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addFolderTapped)
        )
    }

    // MARK: - Data Loading
    private func loadData() {
        allItems = FavoritesManager.shared.load()
        folders = FavoritesManager.shared.loadFolders()
        tableView.reloadData()
    }

    // MARK: - Segment Control
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }

    // MARK: - Create Folder
    @objc private func addFolderTapped() {
        let alert = UIAlertController(
            title: "New Folder",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { $0.placeholder = "Folder name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text,
                  !name.isEmpty else { return }

            var savedFolders = FavoritesManager.shared.loadFolders()

            // Avoid duplicate folder names
            guard !savedFolders.contains(where: { $0.name == name }) else { return }
            savedFolders.append(FavoriteFolder(name: name))
            FavoritesManager.shared.saveFolders(savedFolders)

            self.loadData()
        })
        present(alert, animated: true)
    }
}

// MARK: - TableView
extension FavoritesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isShowingFolders ? folders.count : allItems.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Folder list view
        if isShowingFolders {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "FolderCell",
                for: indexPath
            )

            let folder = folders[indexPath.row]

            cell.textLabel?.text = folder.name
            cell.imageView?.image = UIImage(systemName: "folder")
            cell.imageView?.tintColor = .systemYellow
            cell.accessoryType = .disclosureIndicator
            cell.detailTextLabel?.text = nil

            return cell
        }

        // Favorites items view
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ItemCell",
            for: indexPath
        ) as! FavoriteItemCell

        cell.configure(with: allItems[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return isShowingFolders ? 56 : 80
    }

    // Tab handler, decides what happens when the user selects a row in the Favorites screen
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        if isShowingFolders {
            let folder = folders[indexPath.row]

            // Filter items that belong to the folder
            let itemsInFolder = allItems.filter {
                $0.folderName == folder.name
            }

            let vc = FolderItemsViewController(
                folderName: folder.name,
                items: itemsInFolder
            )

            navigationController?.pushViewController(vc, animated: true)

        } else {
            let item = allItems[indexPath.row]
            let detail = storyboard?.instantiateViewController(
                withIdentifier: "ItemDetailViewController"
            ) as! ItemDetailViewController

            detail.favoriteItem = item

            navigationController?.pushViewController(detail, animated: true)
        }
    }

    // MARK: - Delete folder
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {

        guard editingStyle == .delete else { return }

        if isShowingFolders {
            let folder = folders[indexPath.row]

            // Remove folder from storage
            FavoritesManager.shared.removeFolder(name: folder.name)

            // Update UI look with the folder removed
            folders.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)

        } else {
            let item = allItems[indexPath.row]
            FavoritesManager.shared.remove(id: item.id)
            allItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

// MARK: - Favorite Item Cell
class FavoriteItemCell: UITableViewCell {
    let thumbImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 6
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // My custom cell UI setup
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(thumbImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        accessoryType = .disclosureIndicator

        NSLayoutConstraint.activate([
            thumbImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            thumbImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbImageView.widthAnchor.constraint(equalToConstant: 60),
            thumbImageView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: thumbImageView.topAnchor, constant: 8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with item: FavoriteItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.isVideo ? "Video" : "Photo"
        thumbImageView.loadImage(from: item.imageURL)
    }
}

// MARK: - Folder Items Screen
class FolderItemsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let folderName: String
    private let items: [FavoriteItem]
    private let tableView = UITableView()

    init(folderName: String, items: [FavoriteItem]) {
        self.folderName = folderName
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = folderName
        view.backgroundColor = .systemBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FavoriteItemCell.self, forCellReuseIdentifier: "ItemCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {items.count}

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ItemCell",
            for: indexPath
        ) as! FavoriteItemCell

        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {80}
}
