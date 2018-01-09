//
//  RootViewController.swift
//  UPnPDeviceBrowser
//
//  Created by imamurh on 2018/01/08.
//  Copyright © 2018年 imamurh. All rights reserved.
//

import UIKit
import upnpx

class RootViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UPnP Devices"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchUPnPDevices()
    }

    var upnpDB: UPnPDB?
    func searchUPnPDevices() {
        guard upnpDB == nil else { return }
        guard let db = UPnPManager.getInstance().db else { return }
        db.add(self)
        upnpDB = db
        _ = UPnPManager.getInstance().ssdp.searchSSDP
    }

    var devices: [BasicUPnPDevice] = [] {
        didSet {
            devices.forEach({ device in
                print("uuid:", device.uuid)
                print("friendlyName:", device.friendlyName)
                print("urn:", device.urn)
            })
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "device", for: indexPath)
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.friendlyName
        cell.detailTextLabel?.text = device.baseURL.host
        if device as? MediaServer1Device != nil {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    // MARK: - Segue

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let indexPath = tableView.indexPathForSelectedRow else { return false }
        return devices[indexPath.row] as? MediaServer1Device != nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        if let browseViewController = segue.destination as? BrowseViewController,
            let device = devices[indexPath.row] as? MediaServer1Device {
            browseViewController.device = device
        }
    }
}

extension RootViewController: UPnPDBObserver {
    func uPnPDBWillUpdate(_ db: UPnPDB!) {
        print(#function)
    }
    func uPnPDBUpdated(_ db: UPnPDB!) {
        print(#function)
        if let devices = db.rootDevices as? [BasicUPnPDevice] {
            self.devices = devices
        }
    }
}
