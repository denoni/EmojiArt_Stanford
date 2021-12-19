//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Gabriel on 12/14/21.
//

import UIKit

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDragDelegate, UICollectionViewDropDelegate {

  var emojiArtModel: EmojiArtModel? {
    get {
      if let url = emojiArtBackgroundImage.url {
        let emojis = emojiArtView.subviews.compactMap { $0 as? UILabel }.compactMap { EmojiArtModel.EmojiInfo(label: $0) }
        return EmojiArtModel(url: url, emojis: emojis)
      }
      return nil
    }
    set {
      emojiArtBackgroundImage = (nil, nil)
      emojiArtView.subviews.compactMap { $0 as? UILabel }.forEach { $0.removeFromSuperview() }
      if let url = newValue?.url {
        imageFetcher = ImageFetcher(fetch: url, handler: { (url, image) in
          DispatchQueue.main.async {
            self.emojiArtBackgroundImage = (url, image)
            newValue?.emojis.forEach {
              let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
              self.emojiArtView.addLabel(with: attributedText, centeredAt: CGPoint(x: $0.x, y: $0.y))
            }
          }
        })
      }
    }
  }

  lazy var emojiArtView = EmojiArtView()

  var document: EmojiArtDocument?
  private var addingEmoji = false

  @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
  @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!

  @IBOutlet weak var dropZone: UIView! {
    didSet {
      dropZone.addInteraction(UIDropInteraction(delegate: self))
    }
  }

  @IBOutlet weak var scrollView: UIScrollView! {
    didSet {
      scrollView.minimumZoomScale = 0.1
      scrollView.maximumZoomScale = 5.0
      scrollView.delegate = self
      scrollView.addSubview(emojiArtView)
    }
  }

  @IBOutlet weak var emojiCollectionView: UICollectionView! {
    didSet {
      emojiCollectionView.dataSource = self
      emojiCollectionView.delegate = self
      emojiCollectionView.dragDelegate = self
      emojiCollectionView.dropDelegate = self
      // To enable dragging item from collection even on iPhone
      emojiCollectionView.dragInteractionEnabled = true
    }
  }

  @IBAction func addEmoji() {
    addingEmoji = true
    emojiCollectionView.reloadSections(IndexSet(integer: 0))
  }

  func documentChanged() {
    document?.emojiArtModel = emojiArtModel
    if document?.emojiArtModel != nil {
      document?.updateChangeCount(.done)
    }
  }

  @IBAction func close(_ sender: UIBarButtonItem) {
    if let observer = emojiArtViewObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    if document?.emojiArtModel != nil {
      document?.thumbnail = emojiArtView.snapshot
    }
    dismiss(animated: true) {
      self.document?.close()
    }
  }

  private var emojiArtViewObserver: NSObjectProtocol?

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    document?.open { success in
      if success {
        self.title = self.document?.localizedName
        self.emojiArtModel = self.document?.emojiArtModel
        self.emojiArtViewObserver = NotificationCenter.default.addObserver(forName: .EmojiArtViewDidChange,
                                                                           object: self.emojiArtView,
                                                                           queue: .main,
                                                                           using: { _ in
                                                                             self.documentChanged()
                                                                           })
      }
    }
  }

  // Change the scroll view size to the content size if user scrolls
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    scrollViewHeight.constant = scrollView.contentSize.height
    scrollViewWidth.constant = scrollView.contentSize.width
  }

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return emojiArtView
  }

  var imageFetcher: ImageFetcher!

  private var suppressBadURLWarnings = true

  // Makes sure the dropped item is an NSURL and UIImage
  func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
    return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
  }

  // The drop should be accepted and will always come from out of the app(dragged from another app) so we use .copy
  func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
    return UIDropProposal(operation: .copy)
  }

  // Drop and fetch the image
  func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {

    imageFetcher = ImageFetcher() { (url, image) in
      DispatchQueue.main.async {
        self.emojiArtBackgroundImage = (url, image)
      }
    }

    session.loadObjects(ofClass: NSURL.self) { nsurls in
      if let url = nsurls.first as? URL {
        DispatchQueue.global(qos: .userInitiated).async {
          if let imageData = try? Data(contentsOf: url.imageURL), let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
              self.emojiArtBackgroundImage = (url, image)
              self.documentChanged()
            }
          } else {
            self.presentBadURLWarning(for: url)
          }
        }
      }
    }

    session.loadObjects(ofClass: UIImage.self) { images in
      if let image = images.first as? UIImage {
        self.imageFetcher.backup = image
      }
    }
  }

  private func presentBadURLWarning(for url: URL?) {
    if !suppressBadURLWarnings {
      let alert = UIAlertController(title: "Image transfer failed",
                                    message: "Couldn't transfer the dropped image from its source.\n Keep showing this warning?",
                                    preferredStyle: .alert)

      alert.addAction(UIAlertAction(title: "Keep Warning",
                                    style: .default))

      alert.addAction(UIAlertAction(title: "Stop Warning",
                                    style: .destructive,
                                    handler: { action in self.suppressBadURLWarnings = true }
                                   ))
      present(alert, animated: true)
    }
  }

  var emojis = "🩸😎🥸🧶🥾🎩🧤👠👗🌼🌿🌶".map { String($0) }

  private var font: UIFont {
    return UIFontMetrics(forTextStyle: .body).scaledFont(for: .preferredFont(forTextStyle: .body).withSize(50))
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    switch section {
    case 0: return 1
    case 1: return emojis.count
    default: return 0
    }
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if indexPath.section == 1 {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
      if let emojiCell = cell as? EmojiCollectionViewCell {

        let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
        emojiCell.label.attributedText = text
      }
      return cell
    } else if addingEmoji {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiInputCell", for: indexPath)
      if let inputCell = cell as? TextFieldCollectionViewCell {
        inputCell.resignationHandler = { [weak self, unowned inputCell] in
          if let text = inputCell.textField.text {
            self?.emojis = ((text.map{ String($0)}) + self!.emojis).uniquified
          }
          self?.addingEmoji = false
          self?.emojiCollectionView.reloadData()
        }
      }
      return cell
    } else {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell", for: indexPath)
      return cell
    }
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if addingEmoji && indexPath.section == 0 {
      return CGSize(width: 300, height: 80)
    }
    else {
      return CGSize(width: 80, height: 80)
    }
  }

  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if let inputCell = cell as? TextFieldCollectionViewCell {
      inputCell.textField.becomeFirstResponder()
    }
  }


  func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    // Just to check check if the item is local(that means that the item being dropped
    // was dragged from the emoji's CollectionView) when user drops it
    session.localContext = collectionView
    return dragItems(at: indexPath)
  }

  func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
    return dragItems(at: indexPath)
  }

  private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
    if !addingEmoji, let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label.attributedText {
      let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
      dragItem.localObject = attributedString
      return [dragItem]
    } else {
      return []
    }
  }

  func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
    return session.canLoadObjects(ofClass: NSAttributedString.self)
  }

  func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
    if let indexPath = destinationIndexPath, indexPath.section == 1 {
      // Checks if the drop is local(that means that the item being dropped was dragged from the emoji's CollectionView)
      let isSelf = ((session.localDragSession?.localContext as? UICollectionView) == collectionView)
      return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    } else {
      return UICollectionViewDropProposal(operation: .cancel)
    }
  }

  func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
    let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
    for item in coordinator.items {
      // The drag-drop is local
      if let sourceIndexPath = item.sourceIndexPath {
        if let attributedString = item.dragItem.localObject as? NSAttributedString {
          collectionView.performBatchUpdates {
            emojis.remove(at: sourceIndexPath.item)
            emojis.insert(attributedString.string, at: destinationIndexPath.item)
            collectionView.deleteItems(at: [sourceIndexPath])
            collectionView.insertItems(at: [destinationIndexPath])
          }
          coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
      } else {
        let placeholderContext = coordinator.drop(item.dragItem,
                                                  to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
        item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self) { (provider, error) in
          DispatchQueue.main.async {
            if let attributedString = provider as? NSAttributedString {
              placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
              })
            } else {
              placeholderContext.deletePlaceholder()
            }
          }
        }
      }
    }
  }

  private var emojiArtBackgroundImageURL: URL?

  var emojiArtBackgroundImage: (url: URL?, image: UIImage?) {
    get {
      return (emojiArtBackgroundImageURL, emojiArtView.backgroundImage)
    }
    set {
      emojiArtBackgroundImageURL = newValue.url
      scrollView?.zoomScale = 1
      emojiArtView.backgroundImage = newValue.image
      let size = newValue.image?.size ?? CGSize.zero
      emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
      scrollView?.contentSize = size

      scrollViewHeight?.constant = size.height
      scrollViewWidth?.constant = size.width

      if let dropZone = self.dropZone, size.width > 0, size.height > 0 {
        scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width,
                                    dropZone.bounds.size.height / size.height)
      }
    }
  }

}

extension EmojiArtModel.EmojiInfo {
  init?(label: UILabel) {
    if let attributedText = label.attributedText, let font = attributedText.font {
      x = Int(label.center.x)
      y = Int(label.center.y)
      text = attributedText.string
      size = Int(font.pointSize)
    } else {
      return nil
    }
  }
}
