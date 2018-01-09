//
//  BrowseViewController.swift
//  UPnPDeviceBrowser
//
//  Created by imamurh on 2018/01/08.
//  Copyright © 2018年 imamurh. All rights reserved.
//

import UIKit
import upnpx

class BrowseViewController: UITableViewController {

    var device: MediaServer1Device!
    var containerObject: MediaServer1ContainerObject?
    var mediaObjects: [MediaServer1BasicObject] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard device != nil else { fatalError("device must not be null.") }
        title = containerObject?.title ?? device.friendlyName
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global().async { [weak self] in
            self?.browseDirectChildren()
        }
    }

    func browseDirectChildren() {
        let objectId = containerObject?.objectID ?? "0"
        let result = NSMutableString()
        let numberReturned = NSMutableString()
        let totalMatches = NSMutableString()
        let updateID = NSMutableString()
        device.contentDirectory.browse(
            withObjectID: objectId,
            browseFlag: "BrowseDirectChildren",
            filter: "*",
            startingIndex: "0",
            requestedCount: "0",
            sortCriteria: "",
            outResult: result,
            outNumberReturned: numberReturned,
            outTotalMatches: totalMatches,
            outUpdateID: updateID
        )
        print("result: ", result)
        print("numberReturned: ", numberReturned)
        print("totalMatches: ", totalMatches)
        print("updateID: ", updateID)

        // Parse result
        let didl = (result as String).data(using: .utf8)
        let mediaObjects = NSMutableArray()
        let parser = MediaServerBasicObjectParser(mediaObjectArray: mediaObjects, itemsOnly: false)
        parser?.parse(from: didl)
        self.mediaObjects = mediaObjects.flatMap { $0 as? MediaServer1BasicObject }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaObjects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaObject", for: indexPath)
        let mediaObject = mediaObjects[indexPath.row]
        cell.textLabel?.text = mediaObject.title
        if let itemObject = mediaObject as? MediaServer1ItemObject {
            cell.detailTextLabel?.text = itemObject.duration
            cell.accessoryType = .none
        } else {
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    // MARK: - Segue

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let indexPath = tableView.indexPathForSelectedRow else { return false }
        return mediaObjects[indexPath.row] as? MediaServer1ContainerObject != nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        if let browseViewController = segue.destination as? BrowseViewController,
            let containerObject = mediaObjects[indexPath.row] as? MediaServer1ContainerObject {
            browseViewController.device = device
            browseViewController.containerObject = containerObject
        }
    }
}
