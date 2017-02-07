//
//  main.swift
//  Karabiner-Elements App Profiles
//
//  Created by Nicholas Riley on 2/6/17.
//  Copyright © 2017 Nicholas Riley. All rights reserved.
//

import Cocoa
import Dispatch

class FileMonitor {
    var action: (() -> Void)?
    var source: DispatchSourceFileSystemObject
    var monitoredFileDescriptor: Int32 = -1
    var enabled: Bool = false
    
    init(path: String) {
        monitoredFileDescriptor = open(path, O_EVTONLY)
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFileDescriptor, eventMask: [.write], queue: DispatchQueue.global())
        source.setEventHandler {
            if self.enabled, let action = self.action {
                action()
            }
            self.source.activate()
        }
        enabled = true
        source.activate()
    }
    
    func suspend(for block: () -> Void) {
        enabled = false
        block()
        enabled = true
    }
}

class KarabinerConfiguration {
    var fileMonitor = FileMonitor(path: jsonPath)
    var json: [String: Any] = [:]
    var profiles: [[String: Any]] = []
    var profileIndices : [String: Int] = [:]
    var selectedProfileIndex: Int?
    var selectedProfileName: String?
    var defaultProfileName: String?

    static let jsonPath = ("~/.config/karabiner/karabiner.json" as NSString).expandingTildeInPath as String
    
    enum IOError: Error {
        case ReadError(message: String)
        case WriteError
    }
    
    init?() {
        do {
            try read()
        } catch IOError.ReadError(let message) {
            NSLog(message)
            return nil
        } catch {
            return nil
        }
        fileMonitor.action = {
            do {
                try self.read()
            } catch IOError.ReadError(let message) {
                NSLog("Unable to read preferences, using old version")
                NSLog(message)
            } catch {
                NSLog("Unable to read preferences, using old version")
            }
        }
    }
    
    func read() throws {
        guard let inputStream = InputStream(fileAtPath: KarabinerConfiguration.jsonPath) else {
            throw IOError.ReadError(message: "Unable to read from Karabiner-Elements preferences file: \(KarabinerConfiguration.jsonPath)")
        }
        inputStream.open()
        guard let jsonOpt = try? JSONSerialization.jsonObject(with: inputStream, options: []) as? [String: Any] else {
            throw IOError.ReadError(message: "Karabiner-Elements preferences format is unrecognized.")
        }
        inputStream.close()
        guard let json = jsonOpt else {
            throw IOError.ReadError(message: "Karabiner-Elements preferences could not be read.")
        }
        
        guard let profiles = json["profiles"] as? [[String: Any]] else {
            throw IOError.ReadError(message: "Can't find Profiles array in Karabiner-Elements preferences.")
        }

        profileIndices = [:]
        selectedProfileName = .none
        selectedProfileIndex = .none
        defaultProfileName = .none
        
        for (index, profile) in profiles.enumerated() {
            guard let profileName = profile["name"] as? String else {
                NSLog("Can't get name of profile: \(profile).")
                continue
            }
            if index == 0 {
                defaultProfileName = profileName
            }
            guard let selected = profile["selected"] as? Bool else {
                NSLog("Can't determine whether profile is selected: \(profileName).")
                continue
            }
            if selected {
                selectedProfileIndex = index
                selectedProfileName = profileName
            }
            profileIndices[profileName] = index
        }

        self.json = json
        self.profiles = profiles
        print("Profiles: \(profileIndices) - selected: " + (selectedProfileName ?? "none"))
    }
    
    func write(jsonUpdate: [String: Any]) throws {
        guard let outputStream = OutputStream(url: URL(fileURLWithPath: KarabinerConfiguration.jsonPath), append: false) else {
            NSLog("Unable to write to Karabiner-Elements preferences file: \(KarabinerConfiguration.jsonPath)")
            throw IOError.WriteError
        }
        outputStream.open()
        guard JSONSerialization.writeJSONObject(jsonUpdate, to: outputStream, options: [.prettyPrinted], error: nil) > 0 else {
            throw IOError.WriteError
        }
        outputStream.close()
    }
    
    func selectProfileOrDefault(named nameToSelect: String) {
        if nameToSelect == selectedProfileName {
            return
        }
        let indexToSelect = profileIndices[nameToSelect] ?? 0
        if indexToSelect == selectedProfileIndex {
            return
        }
        fileMonitor.suspend {
            for index in profiles.indices {
                let selected = (indexToSelect == index)
                profiles[index]["selected"] = selected
            }
            var jsonUpdate = json
            jsonUpdate["profiles"] = profiles
            do {
                try write(jsonUpdate: jsonUpdate)
            } catch {
                NSLog("Can't write to Karabiner-Elements preferences file: \(KarabinerConfiguration.jsonPath)")
                return
            }
            json = jsonUpdate
            selectedProfileIndex = indexToSelect
            selectedProfileName = (indexToSelect == 0 ? defaultProfileName : nameToSelect)
            print("Profile is now \(selectedProfileName!)")
        }
    }
}

class FrontApplicationWatcher {
    init(onSwitchTo: @escaping (String) -> Void) {
        NSWorkspace.shared().notificationCenter.addObserver(forName: NSNotification.Name.NSWorkspaceDidActivateApplication, object: nil, queue: OperationQueue.main) { (notification) in
            guard
                let userInfo = notification.userInfo as? [String: Any],
                let application = userInfo[NSWorkspaceApplicationKey] as? NSRunningApplication,
                let bundleIdentifier = application.bundleIdentifier
            else {
                NSLog("Invalid NSWorkspaceDidActivateApplication userInfo")
                return
            }
            onSwitchTo(bundleIdentifier)
        }
    }
}

guard let config = KarabinerConfiguration() else {
    exit(1)
}

let applicationWatcher = FrontApplicationWatcher { (bundleIdentifier) in
    config.selectProfileOrDefault(named: bundleIdentifier)
}

RunLoop.current.run()
