//
//  TextFieldCollectionViewCell.swift
//  EmojiArt
//
//  Created by Gabriel on 12/15/21.
//

import UIKit

class TextFieldCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {

  @IBOutlet weak var textField: UITextField! {
    didSet {
      textField.delegate = self
    }
  }

  var resignationHandler: (() -> Void)?

  func textFieldDidEndEditing(_ textField: UITextField) {
    resignationHandler?()
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}
