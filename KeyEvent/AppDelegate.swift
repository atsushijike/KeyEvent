//
//  AppDelegate.swift
//  KeyEvent
//
//  Created by 寺家 篤史 on 2018/10/05.
//  Copyright © 2018年 Yumemi Inc. All rights reserved.
//

import Cocoa
import SnapKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

class ViewController: NSViewController {
    private let controlButton = NSButton()
    private let processPopUpButton = NSPopUpButton()
    private var selectedProcessId: Int32? {
        guard let id = processPopUpButton.selectedItem?.tag else { return nil }
        return Int32(id)
    }
    private var keyEventMonitor: Any?

    deinit {
        if let keyEventMonitor = keyEventMonitor {
            NSEvent.removeMonitor(keyEventMonitor)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        controlButton.title = "Start controling"
        controlButton.action = #selector(controlButtonDidSelect(sender:))
        controlButton.bezelStyle = .roundRect
        controlButton.target = self
        view.addSubview(controlButton)

        let menu = NSMenu()
        NSWorkspace.shared.runningApplications.forEach { (runningApplication) in
            let title = runningApplication.localizedName ?? runningApplication.bundleIdentifier ?? ""
            let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            menuItem.tag = Int(runningApplication.processIdentifier)
            menu.addItem(menuItem)
        }
        processPopUpButton.menu = menu
        processPopUpButton.isEnabled = false
        view.addSubview(processPopUpButton)

        controlButton.snp.makeConstraints { (make) in
            make.width.equalTo(120)
            make.height.equalTo(24)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(15)
        }
        processPopUpButton.snp.makeConstraints { (make) in
            make.width.equalTo(200)
            make.height.equalTo(24)
            make.centerX.equalToSuperview()
            make.top.equalTo(controlButton.snp.bottom).offset(15)
        }
    }

    @objc private func controlButtonDidSelect(sender: NSButton) {
        if processPopUpButton.isEnabled {
            // Stop monitoring for key events
            if let keyEventMonitor = keyEventMonitor {
                NSEvent.removeMonitor(keyEventMonitor)
            }
            keyEventMonitor = nil
            processPopUpButton.isEnabled = false
            controlButton.title = "Start controling"
        } else {
            // Start monitoring for key events
            keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] (event) in
                guard let `self` = self,
                    let pid = self.selectedProcessId,
                    let cgEvent = event.cgEvent else {
                        return nil
                }
                cgEvent.postToPid(pid)
                return nil  // Avoid system beep
            }
            processPopUpButton.isEnabled = true
            controlButton.title = "Stop controling"
        }
    }
}
