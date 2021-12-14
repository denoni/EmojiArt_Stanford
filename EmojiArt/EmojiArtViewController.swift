//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Gabriel on 12/14/21.
//

import UIKit

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate {

  @IBOutlet weak var dropZone: UIView! {
    didSet {
      dropZone.addInteraction(UIDropInteraction(delegate: self))
    }
  }

  // Makes sure the dropped item is an NSURL and UIImage
  func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
    return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
  }

  // The drop should be accepted and will always come from out of the app(dragged from another app) so we use .copy
  func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
    return UIDropProposal(operation: .copy)
  }

  var imageFetcher: ImageFetcher!

  func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {

    imageFetcher = ImageFetcher() { (url, image) in
      DispatchQueue.main.async {
        self.emojiArtView.backgroundImage = image
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

  @IBOutlet weak var emojiArtView: EmojiArtView!

}

