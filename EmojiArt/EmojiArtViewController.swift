//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Gabriel on 12/14/21.
//

import UIKit

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDragDelegate {

  var emojiArtView = EmojiArtView()

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
        self.emojiArtBackgroundImage = image
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

  var emojis = "🩸😎🥸🧶🥾🎩🧤👠👗🌼🌿🌶".map { String($0) }

  private var font: UIFont {
    return UIFontMetrics(forTextStyle: .body).scaledFont(for: .preferredFont(forTextStyle: .body).withSize(50))
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return emojis.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
    if let emojiCell = cell as? EmojiCollectionViewCell {

      let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
      emojiCell.label.attributedText = text
    }
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    return dragItems(at: indexPath)
  }

  private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
    if let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label.attributedText {
      let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
      dragItem.localObject = attributedString
      return [dragItem]
    } else {
      return []
    }
  }

  var emojiArtBackgroundImage: UIImage? {
    get {
      return emojiArtView.backgroundImage
    }
    set {
      scrollView?.zoomScale = 1
      emojiArtView.backgroundImage = newValue
      let size = newValue?.size ?? CGSize.zero
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

