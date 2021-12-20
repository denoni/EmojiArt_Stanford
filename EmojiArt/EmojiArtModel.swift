//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Gabriel on 12/15/21.
//

import Foundation

struct EmojiArtModel: Codable {
  var url: URL?
  var imageData: Data?
  var emojis = [EmojiInfo]()

  struct EmojiInfo: Codable {
    let x: Int
    let y: Int
    let text: String
    let size: Int
  }

  var json: Data? {
    return try? JSONEncoder().encode(self)
  }

  init?(json: Data) {
    if let newValue = try? JSONDecoder().decode(EmojiArtModel.self, from: json) {
      self = newValue
    } else {
      return nil
    }
  }

  init(url: URL, emojis: [EmojiInfo]) {
    self.url = url
    self.emojis = emojis
  }

  init(imageData: Data, emojis: [EmojiInfo]) {
    self.imageData = imageData
    self.emojis = emojis
  }
}
