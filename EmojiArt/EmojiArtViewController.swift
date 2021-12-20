//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Gabriel on 12/14/21.
//

import UIKit
import UniformTypeIdentifiers

class EmojiArtViewController: UIViewController {

  // MARK: - IB

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

  @IBAction func close(_ sender: UIBarButtonItem? = nil) {
    if let observer = emojiArtViewObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    if document?.emojiArtModel != nil {
      document?.thumbnail = emojiArtView.snapshot
    }
    presentingViewController?.dismiss(animated: true) {
      self.document?.close()
    }
  }

  @IBAction func close(bySegue: UIStoryboardSegue) {
    close()
  }

  @IBOutlet weak var cameraButton: UIBarButtonItem! {
    didSet {
      cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
    }
  }

  @IBAction func takeBackgroundPhoto(_ sender: UIBarButtonItem) {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.mediaTypes = [UTType.image.identifier]
    picker.allowsEditing = true
    picker.delegate = self
    present(picker, animated: true)
  }

  // MARK: - Variables

  var emojis = "🩸😎🥸🧶🥾🎩🧤👠👗🌼🌿🌶".map { String($0) }
  lazy var emojiArtView = EmojiArtView()

  var document: EmojiArtDocument?
  private var emojiArtViewObserver: NSObjectProtocol?
  var imageFetcher: ImageFetcher!

  private var addingEmoji = false
  private var suppressBadURLWarnings = true

  private var font: UIFont {
    return UIFontMetrics(forTextStyle: .body).scaledFont(for: .preferredFont(forTextStyle: .body).withSize(50))
  }

  var emojiArtBackgroundImage: ImageSource? {
    didSet {
      scrollView?.zoomScale = 1
      emojiArtView.backgroundImage = emojiArtBackgroundImage?.image
      let size = emojiArtBackgroundImage?.image.size ?? CGSize.zero
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

  var emojiArtModel: EmojiArtModel? {
    get {
      if let imageSource = emojiArtBackgroundImage {
        let emojis = emojiArtView.subviews.compactMap { $0 as? UILabel }.compactMap { EmojiArtModel.EmojiInfo(label: $0) }
        switch imageSource {
        case .remote(let url, _): return EmojiArtModel(url: url, emojis: emojis)
        case .local(let imageData, _): return EmojiArtModel(imageData: imageData, emojis: emojis)
        }
      }
      return nil
    }
    set {
      emojiArtBackgroundImage = nil
      emojiArtView.subviews.compactMap { $0 as? UILabel }.forEach { $0.removeFromSuperview() }
      let imageData = newValue?.imageData
      let image = (imageData != nil) ? UIImage(data: imageData!) : nil
      if let url = newValue?.url {
        imageFetcher = ImageFetcher() { (url, image) in
          DispatchQueue.main.async {
            if image == self.imageFetcher.backup {
              self.emojiArtBackgroundImage = .local(imageData!, image)
            } else {
              self.emojiArtBackgroundImage = .remote(url, image)
            }
            newValue?.emojis.forEach {
              let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
              self.emojiArtView.addLabel(with: attributedText, centeredAt: CGPoint(x: $0.x, y: $0.y))
            }
          }
        }
        imageFetcher.backup = image
        imageFetcher.fetch(url)
      } else if image != nil {
        emojiArtBackgroundImage = .local(imageData!, image!)
        newValue?.emojis.forEach {
          let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
          self.emojiArtView.addLabel(with: attributedText, centeredAt: CGPoint(x: $0.x, y: $0.y))
        }
      }
    }
  }

  // MARK: - UIViewController Functions

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // We need to make this check otherwise when the user opens the camera to take a background image photo,
    // once he took the photo and came back to the scroll view screen, his photo will be covered by a new document created below
    if document?.documentState != .normal {
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
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowDocumentInfo" {
      if let destination = segue.destination.contents as? DocumentInfoViewController {
        document?.thumbnail = emojiArtView.snapshot
        destination.document = document
        if let popoverPresentationController = destination.popoverPresentationController {
          popoverPresentationController.delegate = self
        }
      }
    }
  }

  // MARK: - Functions

  func documentChanged() {
    document?.emojiArtModel = emojiArtModel
    if document?.emojiArtModel != nil {
      document?.updateChangeCount(.done)
    }
  }

  enum ImageSource {
    case remote(URL, UIImage)
    case local(Data, UIImage)

    var image: UIImage {
      switch self {
      case .remote(_, let image): return image
      case .local(_, let image): return image
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


// MARK: - Protocol Conformance

extension EmojiArtViewController: UIDropInteractionDelegate {
  
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
        if image == self.imageFetcher.backup {
          if let imageData = image.jpegData(compressionQuality: 1.0) {
            self.emojiArtBackgroundImage = .local(imageData, image)
            self.documentChanged()
          } else {
            self.presentBadURLWarning(for: url)
          }

        } else {
          self.emojiArtBackgroundImage = .remote(url, image)
          self.documentChanged()
        }
      }
    }

    session.loadObjects(ofClass: NSURL.self) { nsurls in
      if let url = nsurls.first as? URL {
        self.imageFetcher.fetch(url)
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
}

extension EmojiArtViewController: UIScrollViewDelegate {
  // Change the scroll view size to the content size if user scrolls
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    scrollViewHeight.constant = scrollView.contentSize.height
    scrollViewWidth.constant = scrollView.contentSize.width
  }

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return emojiArtView
  }
}

extension EmojiArtViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if let inputCell = cell as? TextFieldCollectionViewCell {
      inputCell.textField.becomeFirstResponder()
    }
  }
}

extension EmojiArtViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if addingEmoji && indexPath.section == 0 {
      return CGSize(width: 300, height: 80)
    }
    else {
      return CGSize(width: 80, height: 80)
    }
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
}

extension EmojiArtViewController: UICollectionViewDragDelegate {
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
}

extension EmojiArtViewController: UICollectionViewDropDelegate {
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
}

extension EmojiArtViewController: UIImagePickerControllerDelegate {
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.presentingViewController?.dismiss(animated:true)
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let image = ((info[UIImagePickerController.InfoKey.editedImage]
                     ?? info[UIImagePickerController.InfoKey.originalImage]) as? UIImage) {
      if let imageData = image.jpegData(compressionQuality: 1.0) {
        emojiArtBackgroundImage = .local(imageData, image)
        documentChanged()
      } else {
        // TODO: Alert the user that the photo that he took from camera had some problem
      }

    }
    picker.presentingViewController?.dismiss(animated:true)
  }
}

extension EmojiArtViewController: UIPopoverPresentationControllerDelegate {
  func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    // .none adaptation (that means: "don't adapt for compact screens")
    return .none
  }
}

extension EmojiArtViewController: UINavigationControllerDelegate { }
