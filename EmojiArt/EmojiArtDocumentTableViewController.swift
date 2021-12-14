//
//  EmojiArtDocumentTableViewController.swift
//  EmojiArt
//
//  Created by Gabriel on 12/14/21.
//

import UIKit

class EmojiArtDocumentTableViewController: UITableViewController {

  var emojiArtDocuments = ["One", "Two", "Three"]

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return emojiArtDocuments.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)

    cell.textLabel?.text = emojiArtDocuments[indexPath.row]

    return cell
  }

}
