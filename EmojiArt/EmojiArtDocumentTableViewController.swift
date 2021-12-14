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

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      emojiArtDocuments.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
    }
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    // To enable the swiping to hide the primary view of the SplitView
    // We set it here because the preferredDisplayMode gets reset every time the layout changes
    if splitViewController?.preferredDisplayMode != .oneOverSecondary {
      splitViewController?.preferredDisplayMode = .oneOverSecondary
    }
  }

  @IBAction func newEmojiArt(_ sender: UIBarButtonItem) {
    emojiArtDocuments += ["Untitled".madeUnique(withRespectTo: emojiArtDocuments)]
    tableView.reloadData()
  }

}
