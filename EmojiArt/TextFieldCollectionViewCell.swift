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

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}
