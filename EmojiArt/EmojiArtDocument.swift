//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Gabriel on 12/15/21.
//

import UIKit

class EmojiArtDocument: UIDocument {

  var emojiArtModel: EmojiArtModel?
  var thumbnail: UIImage?

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

  override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocument.SaveOperation) throws -> [AnyHashable : Any] {
    var attributes = try super.fileAttributesToWrite(to: url, for: saveOperation)
    if let thumbnail = self.thumbnail {
      attributes[URLResourceKey.thumbnailDictionaryKey] = [URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey:thumbnail]
    }
    return attributes
  }

}

