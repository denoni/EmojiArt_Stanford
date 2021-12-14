//
//  EmojiArtView.swift
//  EmojiArt
//
//  Created by Gabriel on 12/14/21.
//

import UIKit

class EmojiArtView: UIView {

  var backgroundImage: UIImage? { didSet { setNeedsDisplay() } }
  
  override func draw(_ rect: CGRect) {
    backgroundImage?.draw(in: bounds)
  }


}
