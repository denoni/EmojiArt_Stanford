//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Gabriel on 12/15/21.
//

import UIKit

class EmojiArtDocument: UIDocument {

  var emojiArtModel: EmojiArtModel?

  override func contents(forType typeName: String) throws -> Any {
    // Encode your document with an instance of NSData or NSFileWrapper
    return emojiArtModel?.json ?? Data()
  }

  override func load(fromContents contents: Any, ofType typeName: String?) throws {
    // Load your document from contents
    if let json = contents as? Data {
      emojiArtModel = EmojiArtModel(json: json)
    }
  }
}

