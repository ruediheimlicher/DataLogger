//
//  AppDelegate.swift
//  DataLogger2
//
//  Created by Ruedi Heimlicher on 11.06.2017.
//  Copyright © 2017 Ruedi Heimlicher. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
   @IBOutlet weak var window: NSWindow!

   var main: NSWindowController!

   func showErrorInKeyWindow(message: String) 
   {
      
      if let window = NSApp.keyWindow {
         
         let alert = NSAlert()
         alert.messageText = "Error"
         alert.informativeText = message
         alert.addButton(withTitle: "Dismiss")
         alert.beginSheetModal(for: window, completionHandler: nil)
         
      }
      
   }


   func applicationDidFinishLaunching(_ aNotification: Notification)
   {
      // Insert code here to initialize your application
    /*
      // https://stackoverflow.com/questions/39876559/cocoa-mac-creating-window-from-appdelegate
      main = NSStoryboard(name : "Main", bundle: nil).instantiateController(withIdentifier: "MainWindow") as! NSWindowController
      let mainVc = NSStoryboard(name:"Main", bundle: nil).instantiateController(withIdentifier: "MainViewController") as! NSViewController
      main.window?.contentViewController = mainVc
      main.window?.makeKeyAndOrderFront(nil)
*/
   }

   func applicationWillTerminate(_ aNotification: Notification)
   {
      // Insert code here to tear down your application
      print("AppDelegate applicationWillTerminate")
      // NSApplication.shared().terminate(self)
   }


}

