//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Gabriel on 12/14/21.
//

import UIKit

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate {

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

