//
//  DataViewController.swift
//  DataInterface
//
//  Created by Ruedi Heimlicher on 28.12.2016.
//  Copyright © 2016 Ruedi Heimlicher. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation
import Darwin
import AudioToolbox

let TEENSYPRESENT   =   7

// USB Eingang
// Temperatur
let DSLO = 8
let DSHI = 9

// teensy
//ADC

let DEVICE = 0

let CHANNEL = 2


let BATT_MIN = 2.8


let   ANALOG0 = 3	// ADC 0 lo
let   ANALOG1 = 5	// ADC 0 hi
let   ANALOG2 = 7	// ADC 1 lo
let   ANALOG3 = 9	// ADC 1 hi

// Digi
let DIGI0 = 13 	// Digi Eingang
let DIGI1 = 14	// Digi Eingang

// Satellit






// end neue defines

// USB Ausgang
let SERVOALO = 10
let SERVOAHI = 11

let SERVO_OUT = 0xD0



// Task
let WRITE_MMC_TEST  =   0xF1

// Bytes fuer Sicherungsort der Daten auf SD
let TEENSY_DATA    =    0xFC // Daten des teensy lesen

let MESSUNG_START   =   0xC0 // Start der Messreihe
let MESSUNG_STOP   =   0xC1 // Start der Messreihe
let KANAL_WAHL     =    0xC2 // Kanalwahl
let READ_START   =   0xCA // Start read

let SAVE_SD_RUN = 0x02 // Bit 1
let SAVE_SD_STOP = 0x04 // Bit 2

let SAVE_SD_BYTE          =     1 //

let READ_ERR_BYTE = 1
//let ABSCHNITT_BYTE         =     2
let BLOCKOFFSETLO_BYTE    =     3 // Block auf SD fuer Sicherung
let BLOCKOFFSETHI_BYTE    =     4

let BLOCK_ANZAHL_BYTE   = 9 // Anzahl zu lesende Blocks
let DOWNLOADBLOCKNUMMER_BYTE   =   10 // aktuelle nummer des downloadblocks
let PACKETCOUNT_BYTE = 2

let DATACOUNT_LO    =   5 // Messung, laufende Nummer auf Block
let DATACOUNT_HI    =   6

let DEVICECOUNT_BYTE   = 3
let USB_BATT_BYTE = 7 // Byte fuer Batteriespannung im write_byte_array


let TAKT_LO_BYTE    =   14
let TAKT_HI_BYTE    =   15

let KANAL_BYTE   =    16 // Begine liste der aktivierte Kanaele der devices

//let KANAL_0_BYTE   =    16 // aktivierte Kanaele device 0
//let KANAL_1_BYTE    =   17 // aktivierte Kanaele device 1
//let KANAL_2_BYTE   =    18 // aktivierte Kanaele device 2
//let KANAL_3_BYTE    =   19 // aktivierte Kanaele device 3

let STARTMINUTELO_BYTE = 5
let STARTMINUTEHI_BYTE = 6

let DATA_START_BYTE   = 8    // erstes byte fuer Data auf USB

let HEADER_SIZE = 16
let PACKET_SIZE = 24 // Datenbreite fuer USB

let HEADER_OFFSET  =    4     // Erstes Byte im Block nach BLOCK_SIZE: Daten, die bei LOGGER_NEXT uebergeben werden

let LOGGER_START     =     0xA0
let LOGGER_CONT      =     0xA1
let LOGGER_NEXT      =     0xA2 // next block

let LOGGER_STOP      =     0xAF

let LOGGER_SETTING    =  0xB0 // Setzen der Settings fuer die Messungen
let MESSUNG_DATA    =  0xB1 // Setzen der Settings fuer die Messungen

let USB_STOP    = 0xAA


let CHECK_WL = 0xBA

let TEENSYVREF:Float = 249.0 // Korrektur von Vref des Teensy: nomineller Wert ist 256 2.56V

class DataViewController: NSViewController, NSWindowDelegate, AVAudioPlayerDelegate,NSMenuDelegate,NSTextViewDelegate,NSTabViewDelegate
{
   
   // Variablen
   var usbstatus: __uint8_t = 0
   
   var usb_read_cont = false; // kontinuierlich lesen
   var usb_write_cont = false; // kontinuierlich schreiben
   
   // Logger lesen
   var startblock:UInt16 = 1 // Byte 1,2: block 1 ist formatierung
   var blockcount:UInt16 = 0 // Byte 3, 4: counter beim Lesen von mehreren Bloecken
   
   var downloadblocknummer:UInt16 = 0 // Byte 3, 4: counter beim Lesen von mehreren Bloecken

   var download_totalblocks:UInt16 = 0 // Byte 3, 4: counter beim Lesen von mehreren Bloecken

   var download_intervall:UInt16 = 1 // Intervall aus download
   
   var downloaddatanummer:UInt32 = 0 // Byte 3, 4: counter beim Lesen von mehreren Bloecken

   
   var packetcount :UInt8 = 0 // byte 5: counter fuer pakete beim Lesen eines Blocks 10 * 48 + 32
   var lastpacket :UInt16 = 0 // byte 5: counter fuer pakete beim Lesen eines Blocks 10 * 48 + 32

   var messungDataArray:[[UInt8]] = [[]]
  
   var loggerDataArray:[[UInt8]] = [[]]
   var DiagrammDataArray:[[Float]] = [[]]
   
   var MessungStartzeit = 0
   
   var teensycode:UInt8 = 0
   
    var devicestatus:UInt8 = 0 // kontrolle der gelesenen Device
   
   var spistatus:UInt8 = 0;
   var DiagrammFeld:CGRect = CGRect.zero
   
   var taskArray :[[String:String]] = [[:]]
   
   
   var anzahlChannels = 0
   var anzahlStoreChannels = 1
   var swiftArray: [[String:String]] = [[:]]

 //  var swiftArray = [[String:String]](repeating:["on":"1"], count:8)
   
 //  var swifftArray = [[String:String]](repeating:[[String:String]](repeating:["x":"x"], count:20),count:8)
   var bb = Array(repeating:[[String:String]](repeating:["on":"1"], count:8),count:6)
   var aa = [[String:String]](repeating:["on":"1"], count:20)
   var BereichArray = [[Int:String]]()
   
//   var testArray = [[String:AnyObject]]()
   
   var teensy = usb_teensy()
   
   var   adcfloatarray:[Float] = []
   
   //https://stackoverflow.com/questions/31736079/swift-associative-array-with-multiple-keysvalues
   struct dataelement
   {
      var channel:Int
      var data:Float
   }
   var datazeile = [Float](repeating:0.0, count:10)
   
   var inputDataFeldstring:String = ""
   var newdata=0;
   
   var analogfloatarray:[Float] = Array(Array(repeating:0.0,count:10))
   
   var devicefloatarray:[[Float]] = Array(repeating:Array(repeating:0.0,count:10),count:6)

   var messungfloatarray:[[Float]] = Array(repeating:Array(repeating:0.0,count:24),count:6)
   
   var rawdataarray:[[UInt8]] = [Array(repeating:0,count:36)] // raw data vom teensy, mit Header


   var bereicharray:[[String]] = [[]]
   
    var devicearray:[String] = ["Teensy","Temperatur","ADC12BIT"]
   
   var tempAbszisse:Abszisse!
   
   var ordinateArray:[Abszisse] = [Abszisse]() // Abszissen
   var ordinateFeldArray:[NSRect] = [NSRect](repeating:NSZeroRect, count:8) // Felder der Abszissen
   
   var lastscrollposition:CGFloat = 0
   var lastscrollcounter:Int = 0
   
   
   var prefs = Preferences()
   
   // Diagramm
   @IBOutlet  var datagraph: DataPlot!
   @IBOutlet  var dataScroller: NSScrollView!
//   @IBOutlet  var dataAbszisse_Temperatur: Abszisse!
   
   @IBOutlet  var datagraph_Volt: DataPlot!
   @IBOutlet  var dataScroller_Volt: NSScrollView!
  
//   @IBOutlet  var dataAbszisse_Volt: Abszisse!
  
   @IBOutlet  var taskTab: NSTabView!
   
   @IBOutlet  var save_SD_check: NSButton!
   @IBOutlet  var Start_Messung: NSButton!
   
   @IBOutlet  var manufactorer: NSTextField!
   
   @IBOutlet  var Start: NSButton!
   
   @IBOutlet  var MessungStartzeitFeld: NSTextField!
   
   @IBOutlet  var USB_OK: NSTextField!
   
    @IBOutlet  var Test_Knopf: NSButton!
   
   @IBOutlet  var start_read_USB_Knopf: NSButton!
   @IBOutlet  var stop_read_USB_Knopf: NSButton!
   @IBOutlet  var cont_read_check: NSButton!
   
   @IBOutlet  var start_write_USB_Knopf: NSButton!
   @IBOutlet  var stop_write_USB_Knopf: NSButton!
   @IBOutlet  var cont_write_check: NSButton!
   
   
   @IBOutlet  var codeFeld: NSTextField!
   
   @IBOutlet  var data0: NSTextField!
   
   @IBOutlet  var data1: NSTextField!
   
   @IBOutlet  var inputDataFeld: NSTextView!
   
   
   @IBOutlet  var write_sd_startblock: NSTextField!
   @IBOutlet  var write_sd_anzahl: NSTextField!
   @IBOutlet  var read_sd_startblock: NSTextField!
   @IBOutlet  var read_sd_anzahl: NSTextField!
   @IBOutlet  var read_sd_progress: NSTextField!
   
   @IBOutlet  var messungcounter: NSTextField!
   @IBOutlet  var blockcounter: NSTextField!
   
   @IBOutlet  var downloadDataFeld: NSTextView!
   
   
   @IBOutlet  var data2: NSTextField!
   @IBOutlet  var data3: NSTextField!
   
   
   @IBOutlet  var H_Feld: NSTextField!
   
   @IBOutlet  var L_Feld: NSTextField!
   
   @IBOutlet  var spannungsanzeige: NSSlider!
   @IBOutlet  var extspannungFeld: NSTextField!
   
   @IBOutlet  var spL: NSTextField!
   @IBOutlet  var spH: NSTextField!
   
   @IBOutlet  var teensybatt: NSTextField!
   
   @IBOutlet  var extstrom: NSTextField!
   @IBOutlet  var Teensy_Status: NSButton!
 
   @IBOutlet  var WL_Status: NSButton!

   
   @IBOutlet  var extspannungStepper: NSStepper!
   @IBOutlet var  Vertikalbalken:rVertikalanzeige!
   
   // Datum
   @IBOutlet  var sec_Feld: NSTextField!
   @IBOutlet  var min_Feld: NSTextField!
   @IBOutlet  var std_Feld: NSTextField!
   @IBOutlet  var wt_Feld: NSTextField!
   @IBOutlet  var mon_Feld: NSTextField!
   @IBOutlet  var jahr_Feld: NSTextField!
   @IBOutlet  var datum_Feld: NSTextField!
   @IBOutlet  var zeit_Feld: NSTextField!
   @IBOutlet  var tagsec_Feld: NSTextField!
   @IBOutlet  var tagmin_Feld: NSTextField!
   
   
    // ADC
   @IBOutlet  var ADC0LO_Feld: NSTextField!
   @IBOutlet  var ADC0HI_Feld: NSTextField!
   @IBOutlet  var ADC0Feld: NSTextField!
   
   @IBOutlet  var ADC1LO_Feld: NSTextField!
   @IBOutlet  var ADC1HI_Feld: NSTextField!
   @IBOutlet  var ADC1Feld: NSTextField!
   
   @IBOutlet  var ServoASlider: NSSlider!
   
   // Logging
   @IBOutlet  var Start_Logger: NSButton!
   @IBOutlet  var Stop_Logger: NSButton!
   
   
   // Einstellungen
   @IBOutlet  var IntervallPop: NSComboBox!
   @IBOutlet  var ZeitkompressionPop: NSComboBox!
   @IBOutlet  var Channels_Feld: NSTextField!
   
   @IBOutlet  var storeChannels_Feld: NSTextField!
   @IBOutlet  var storeChannels_Stepper: NSStepper!
   @IBOutlet  var storeChannels_Pop: NSPopUpButton!
   
   
   @IBOutlet   var TaskListe: NSTableView!
   
   
   //    @IBOutlet   var TestListe: NSTableView!
   
   @IBOutlet  var Set_Settings: NSButton!
   
   // USB-code
   
   @IBOutlet var wl_callback_status_Feld: NSTextField!
   
   // mmc
   @IBOutlet  var mmcLOFeld: NSTextField!
   @IBOutlet  var mmcHIFeld: NSTextField!
   @IBOutlet  var mmcDataFeld: NSTextField!
   
   
   
   // Collection view
  // @IBOutlet weak var deviceCollectionView: NSCollectionView!
   
   
   // http://www.globalnerdy.com/2016/01/26/better-to-be-roughly-right-than-precisely-wrong-rounding-numbers-with-swift/
   func roundit(_ value: Double, toNearest: Double) -> Double
   {
      let temp = value / toNearest
      return round(temp) * toNearest
   }
   
   
   
   open func writeData(name:String, data:String)
   {
      /*
       // http://www.techotopia.com/index.php/Working_with_Directories_in_Swift_on_iOS_8
       do {
       let filelist = try filemgr.contentsOfDirectory(atPath: "/")
       
       for filename in filelist {
       print(filename)
       }
       } catch let error {
       print("Error: \(error.localizedDescription)")
       }
       */
      //print ("\nwriteData data: \(data)")
      
      //http://stackoverflow.com/questions/24097826/read-and-write-data-from-text-file
      // http://www.techotopia.com/index.php/Working_with_Directories_in_Swift_on_iOS_8
      
      do
      {
         let documentDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
         var datapfad = documentDirectoryURL.appendingPathComponent("LoggerdataDir")
         
         do
         {
            try FileManager.default.createDirectory(atPath: datapfad.path, withIntermediateDirectories: true, attributes: nil)
         }
         catch let error as NSError
         {
            print(error.localizedDescription);
         }
         
         
         //print ("datapfad: \(datapfad)")
         
         datapfad = datapfad.appendingPathComponent(name)
         
         //writing
         do
         {
            try data.write(to: datapfad, atomically: false, encoding: String.Encoding.utf8)
         }
         catch let error as NSError
         {
            print(error.localizedDescription);
         }
      }
      catch
      {
         print("catch write")
      }
      
      return
      
      
      
      if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
      {
         
         let path = dir.appendingPathComponent(data)
         
         //writing
         do
         {
            try data.write(to: path, atomically: false, encoding: String.Encoding.utf8)
         }
         catch {/* error handling here */}
         
         //reading
         do {
            let text2 = try String(contentsOf: path, encoding: String.Encoding.utf8)
            print("text2: \(text2)")
            inputDataFeld.string = text2
         }
         catch {/* error handling here */}
         
      }
   } // writeData
   
   
   func tagminute()-> Int
   {
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "gsw-CH")
      
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      return 60 * stunde + minute
   }
   
   
   func tagsekunde()-> Int
   {
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "gsw-CH")
      
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      let sekunde = calendar.component(.second, from: date)
      return 3600 * stunde + 60 * minute + sekunde
   }
   
   func datumstring()->String
   {
      let date = Date()
      let calendar = Calendar.current
      let jahr = calendar.component(.year, from: date)
      let tagdesmonats = calendar.component(.day, from: date)
      let monatdesjahres = calendar.component(.month, from: date)
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "gsw-CH")
      
      formatter.dateFormat = "dd.MM.yyyy"
      let datumString = formatter.string(from: date)
      print("datumString: \(datumString)*")
      return datumString
   }
   
   func zeitstring()->String
   {
      // http://dev.iachieved.it/iachievedit/handling-dates-with-swift-3-0/
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "de-CH")
      
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      let sekunde = calendar.component(.second, from: date)
      formatter.dateFormat = "hh:mm:ss"
      let zeitString = formatter.string(from: date)
      return zeitString
   }
   
   func datumprefix()->String
   {
      // http://dev.iachieved.it/iachievedit/handling-dates-with-swift-3-0/
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "de-CH")
      
      let jahr = calendar.component(.year, from: date)
      let tagdesmonats = calendar.component(.day, from: date)
      let monatdesjahres = calendar.component(.month, from: date)
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      
      
      
      formatter.dateFormat = "yyMMdd_HHmm"
      let prefixString = formatter.string(from: date)
      return prefixString
   }
   
   func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ())
   {
      DispatchQueue.main.asyncAfter(deadline: .now() + seconds)
      {
         completion()
      }
   }

   func delayWithMilliSeconds(_ millis: Int, completion: @escaping () -> ())
   {
     // https://cocoacasts.com/how-to-use-dispatch-after-in-swift-3/
      // milis muss Int sein
      DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(millis), qos: .background)
     {
         completion()
      }
   }

   func MessungDataString(data:[[Float]])-> String
   {
      var datastring:String = ""
      var datastringarray:[String] = []
      //      print("setMessungData: \(data)")
      
      for index in 0..<data.count
      {
         
         var tempzeilenarray:[Float] = data[index]
         if (tempzeilenarray.count > 0)
         {
            //print("tempzeilenarray: \(tempzeilenarray)")
            
            let nummer = tempzeilenarray[0]
            let nummerstring = String(format:"%3.0f", nummer)
            //print("nummerstring: \(nummerstring)")
            tempzeilenarray.remove(at: 0)
            let tempzeilenstring = tempzeilenarray.map{String($0)}.joined(separator: "\t")
            datastringarray.append(tempzeilenstring)
            datastring = datastring +  "\n" + nummerstring + "\t" + tempzeilenstring
         }
      }
      let prefix = datumprefix()
      let dataname = prefix + "_messungdump.txt"
      
      //   writeData(name: dataname,data:datastring)
      
      return datastring
   }

   func IntDataString(data:[[UInt8]])-> String
   {
      var datastring:String = ""
      var datastringarray:[String] = []
      //      print("setMessungData: \(data)")
      var datacounter = 1
      for index in 0..<data.count
      {
         
         var tempzeilenarray:[UInt8] = data[index]
         if (tempzeilenarray.count > 0)
         {
            //print("tempzeilenarray: \(tempzeilenarray)")
            
            let nummer = tempzeilenarray[0]
            let nummerstring = String(format:"%3.0f", nummer)
            //print("nummerstring: \(nummerstring)")
            //tempzeilenarray.remove(at: 0)
            let tempzeilenstring = tempzeilenarray.map{String($0)}.joined(separator: "\t")
            datastringarray.append(tempzeilenstring)
            datastring = datastring +  "\n" + String(datacounter) + "\t" + tempzeilenstring
            datacounter += 1
         }
      }
      let prefix = datumprefix()
      //let dataname = prefix + "_messungdump.txt"
      
      //   writeData(name: dataname,data:datastring)
      
      return datastring
   }

   
   

   @IBAction func myPopUpButtonWasSelected(sender:NSButton)
   {
      
      print("myPopUpButtonWasSelected")
      // if let menuItem = sender as? NSMenuItem, mindex = find(allTheThings, menuItem.title) {
      //     sendThatIndexIntoTheWorld(mindex)
      //  }
   }
   
   func dialogOKCancel(question: String, text: String) -> Int 
   {
      // https://stackoverflow.com/questions/29433487/create-an-nsalert-with-swift
      let alert = NSAlert()
      alert.messageText = question
      alert.informativeText = text
      alert.alertStyle = NSAlertStyle.warning
      alert.addButton(withTitle: "OK")
      alert.addButton(withTitle: "Cancel")
      return alert.runModal()// == NSAlertFirstButtonReturn
      
   }

   func dialogAlertMult(message: String, information: String, buttonOK: String, buttonCancel: String) -> Int
   {
      let alert = NSAlert()
      alert.messageText = message
      alert.informativeText = information
      alert.addButton(withTitle: buttonOK)
      alert.addButton(withTitle: buttonCancel)
      alert.alertStyle = NSAlertStyle.warning
      var antwort = 0
      let fenster = NSApplication.shared().windows.first
        return alert.runModal()
   }
   
   override func viewDidAppear() 
   {
      self.view.window?.delegate = self
   }
  
   func windowShouldClose(_ sender: Any) 
   {
      
      //print("windowShouldClose")
      
      //NSApplication.shared().terminate(self)
   }
   
   //MARK: - viewDidLoad
   override func viewDidLoad()
   {
      super.viewDidLoad()
      
      // Notific einrichten
      //      NotificationCenter.default.addObserver(self, selector: #selector(DataViewController.USBfertigAktion(_:)), name: NSNotification.Name(rawValue: "NSWindowWillCloseNotification"), object: nil)
      
      // http://dev.iachieved.it/iachievedit/notifications-and-userinfo-with-swift-3-0/
      
 //     var antwort = dialogOKCancel(question: "fertig?",text:"was auch immer")
      
 //     print("antwort: \(antwort)")
      
//      antwort = dialogAlertMult(message: "wirklich?", information: "das ist heikel", buttonOK: "sicher", buttonCancel: "Mist")
//      print("antwort: \(antwort)")
        
      print("datumprefix: \(datumprefix())")
      let nc = NotificationCenter.default //
      
      nc.addObserver(forName:Notification.Name(rawValue:"NSWindowWillCloseNotification"),// Name im Aufruf in usb.swift
         object:nil, queue:nil,
         using:USBfertigAktion)
      
      
      nc.addObserver(forName:Notification.Name(rawValue:"newdata"),// Name im Aufruf in usb.swift
         object:nil, queue:nil,
         using:newLoggerDataAktion)
      
      let milesToPoint = ["point1":120.0,"point2":50.0,"point3":70.0]
      let kmToPoint = milesToPoint.map { a,miles in miles * 1.6093 }
      
      USB_OK.textColor = NSColor.red
      USB_OK.stringValue = "??";
      
      //MARK: -   TaskListe
      
       TaskListe.delegate = self
       TaskListe.dataSource = self
       TaskListe.target = self
      
      IntervallPop.addItems(withObjectValues:["1","2","5","10","20","30","60","120","180","300"])
      IntervallPop.selectItem(at:0)
      
      // var swiftArray: [[String:String]] = [[:]]
      swiftArray.removeAll()
      // var devicedic = [[String:String]](repeating:["":""], count:20)
      var dic = [[String:String]](repeating:["on":"1"], count:20)
     
      dic[0]["on"] = String(1)
      dic[0]["device"] = devicearray[0]
      dic[0]["deviceID"] = "0"
      dic[0]["description"] = "Teensy"

      var tempDic = [String:String]()
      
      tempDic["on"] = String(1)
//      tempDic["device"] = "abcd" //devicearray[0]
 //     tempDic["deviceID"] = "0"
      tempDic["description"] = "Home"
      tempDic["A0"] = String(0)
      tempDic["analogAtitel"] = "ADC 2\tADC 3\tADC 4\tADC"
      tempDic["A1"] = String(1)
      tempDic["A"] = String(0) // Kanaele Analog
      tempDic["bereich"] = "0-80°\t0-160°\t-30-130°"
      tempDic["analog"] = "0"
      tempDic["bereichwahl"] = "0"
      tempDic["temperatur"] = "16.5°"
      tempDic["batterie"] = "1.0V"
      tempDic["stellen"] = "1"
      tempDic["majorteiley"] = "8"
      tempDic["minorteiley"] = "2"
//      print("tempDic: \(tempDic)")
      
       
      
      swiftArray.append(tempDic )
      
      aa[0]["on"] = String(1)
      aa[0]["device"] = devicearray[0]
      aa[0]["deviceID"] = "0"
      aa[0]["description"] = "Home"

      //aa[0] = tempDic 



      tempDic["on"] = String(1)
//      tempDic["device"] = devicearray[1]
 //     tempDic["deviceID"] = "1"
      tempDic["description"] = "Temperaturen messen"
      tempDic["A0"] = String(0)
      tempDic["A1"] = String(1)
      tempDic["A"] = String(7)
      tempDic["analogAtitel"] = "ADC 2\tADC 3\tADC 4\t--"
      tempDic["bereich"] = "0-80°\t0-160°\t-20-140°"
      tempDic["bereichwahl"] = "1"
      tempDic["analog"] = "6"
      tempDic["temperatur"] = "10.5°"
      tempDic["batterie"] = "1.0V"
      tempDic["stellen"] = "0"
      tempDic["majorteiley"] = "16"
      tempDic["minorteiley"] = "2"

      swiftArray.append(tempDic )
      //swiftArray[1] = tempDic 
      
      tempDic["on"] = String(1 )
//      tempDic["device"] = devicearray[2]
//      tempDic["deviceID"] = "2"
      tempDic["description"] = "Spannung messen mit 12 Bit"
      tempDic["A0"] = "1"
      tempDic["A1"] = "1"
      tempDic["A"] = "15"
      tempDic["analogAtitel"] = "ADC 0\tADC 1\tADC 2\tADC 3"

      tempDic["bereich"] = "0-8V\t0-16V"
      tempDic["bereichwahl"] = "1"
      tempDic["temperatur"] = "20.1°"
      tempDic["batterie"] = "4.20V"
      tempDic["stellen"] = "1"
      tempDic["majorteiley"] = "8"
      tempDic["minorteiley"] = "2"
      
      swiftArray.append(tempDic )
 // https://useyourloaf.com/blog/swift-guide-to-map-filter-reduce/
      let a = swiftArray.map({val in    val["description"]})
     
      
      // https://useyourloaf.com/blog/warning-converting-optional-to-string/
      var optionalValue: Int? = 42
      //print("Value is \(optionalValue ?? 0)")  // Warning
      
      
      var lineindex=0
      
      for var deviceline in swiftArray
      {
         if (lineindex < devicearray.count)
         {
            swiftArray[lineindex]["device"] = devicearray[lineindex]
            swiftArray[lineindex]["deviceID"] = String(lineindex)

         }
         lineindex += 1
      }
      var bereichDic = [String:[String]]()
      var zeile:[String] =  ["0-100","0-150","-30-150"]
      bereichDic ["temperatur"] = ["0-100","0-150","-30-150"]
      bereichDic ["ADC 12Bit"] = ["0 - 8V","0-16V"]

      
      
      //MARK: -   datagraph
      
      
      var farbe = NSColor.init(red: (0.0), green: (0.0), blue: (0.0), alpha: 0.0)
      var linienfarbeArray_blue = [NSColor](repeating:farbe, count:8)

      linienfarbeArray_blue[0] = NSColor( red: (0.69), green: (0.69), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[1] = NSColor( red: (0.59), green: (0.59), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[2] = NSColor( red: (0.50), green: (0.49), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[3] = NSColor( red: (0.41), green: (0.39), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[4] = NSColor( red: (0.32), green: (0.29), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[5] = NSColor( red: (0.23), green: (0.20), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[6] = NSColor( red: (0.14), green: (0.10), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[7] = NSColor( red: (0.05), green: (0.00), blue: (0.98), alpha: (1.00))      
      var linienfarbeArray_red = [NSColor](repeating:farbe, count:8)

      linienfarbeArray_red[0] = NSColor( red: (0.98), green: (0.57), blue: (0.59), alpha: (1.00))
      linienfarbeArray_red[1] = NSColor( red: (0.98), green: (0.49), blue: (0.52), alpha: (1.00))
      linienfarbeArray_red[2] = NSColor( red: (0.98), green: (0.41), blue: (0.45), alpha: (1.00))
      linienfarbeArray_red[3] = NSColor( red: (0.98), green: (0.32), blue: (0.38), alpha: (1.00))
      linienfarbeArray_red[4] = NSColor( red: (0.98), green: (0.24), blue: (0.31), alpha: (1.00))
      linienfarbeArray_red[5] = NSColor( red: (0.98), green: (0.16), blue: (0.24), alpha: (1.00))
      linienfarbeArray_red[6] = NSColor( red: (0.98), green: (0.08), blue: (0.16), alpha: (1.00))
      linienfarbeArray_red[7] = NSColor( red: (0.98), green: (0.00), blue: (0.09), alpha: (1.00))
      var linienfarbeArray_green = [NSColor](repeating:farbe, count:8)
      
      linienfarbeArray_green[0] = NSColor( red: (0.69), green: (0.98), blue: (0.69), alpha: (1.00))
      linienfarbeArray_green[1] = NSColor( red: (0.60), green: (0.91), blue: (0.60), alpha: (1.00))
      linienfarbeArray_green[2] = NSColor( red: (0.52), green: (0.83), blue: (0.50), alpha: (1.00))
      linienfarbeArray_green[3] = NSColor( red: (0.44), green: (0.76), blue: (0.41), alpha: (1.00))
      linienfarbeArray_green[4] = NSColor( red: (0.35), green: (0.68), blue: (0.32), alpha: (1.00))
      linienfarbeArray_green[5] = NSColor( red: (0.27), green: (0.61), blue: (0.23), alpha: (1.00))
      linienfarbeArray_green[6] = NSColor( red: (0.19), green: (0.53), blue: (0.14), alpha: (1.00))
      linienfarbeArray_green[7] = NSColor( red: (0.11), green: (0.45), blue: (0.05), alpha: (1.00))
      self.datagraph.wantsLayer = true
      
      //self.datagraph.layer?.backgroundColor = CGColor.black
     // self.datagraph.setDatafarbe(farbe:NSColor.red, index:0)
      
      self.datagraph.linienfarbeArray[0] = linienfarbeArray_green
      self.datagraph.linienfarbeArray[1] = linienfarbeArray_blue
      self.datagraph.linienfarbeArray[2] = linienfarbeArray_red
      
//    self.datagraph.setlinienfarbeArray(farbearray:linienfarbeArray_blue, index:0)
//    self.datagraph.setlinienfarbeArray(farbearray:linienfarbeArray_red, index:1)
//    self.datagraph.setlinienfarbeArray(farbearray:linienfarbeArray_green, index:2)
      

      // MARK: - taskTab
 //     taskTab.selectTabViewItem(withIdentifier: "data")
      let ident = taskTab.selectedTabViewItem?.identifier
      let datatabsubviews = taskTab.tabViewItem(at:0).view?.subviews 
      var ordinateframe:NSRect = NSZeroRect
      ordinateframe.size.width = 28
      ordinateframe.size.height = datagraph.frame.size.height
      ordinateframe.origin.x = dataScroller.frame.origin.x - ordinateframe.size.width
      ordinateframe.origin.y = dataScroller.frame.origin.y + dataScroller.frame.size.height - dataScroller.contentView.frame.size.height - 1// addidtion der Scrollerhoehe, korr um 1 px
      
//      print("ordinateframe: \(ordinateframe)")
      //ordinateframe.origin.x -= 100
      let ordinateoffsetx = ordinateframe.size.width // verschiebung der einzelnen ordinaten
      
      for nr in 0..<swiftArray.count 
      {
         var dataordinate:Abszisse = Abszisse.init(frame: ordinateframe)
         dataordinate.setAbszisseFeldHeight(h: self.datagraph.DiagrammFeldHeight())
         dataordinate.identifier = "dataordinate\(nr)"
         dataordinate.setLinienfarbe(farbe: datagraph.linienfarbeArray[nr][7].cgColor)
         dataordinate.setMajorTeileY(majorteiley: Int(swiftArray[nr]["majorteiley"]!)!)
         dataordinate.setMinorTeileY(minorteiley: Int(swiftArray[nr]["minorteiley"]!)!)
         dataordinate.setStellen(stellen: Int(swiftArray[nr]["stellen"]!)!)
         dataordinate.setDevice(devicestring:swiftArray[nr]["device"]!)
         dataordinate.setDeviceID(deviceIDstring:swiftArray[nr]["deviceID"]!)
         dataordinate.wantsLayer = true
         let color : CGColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
         dataordinate.layer?.backgroundColor = color

         
         ordinateArray.append(dataordinate)
         
         taskTab.tabViewItem(at:0).view?.addSubview(dataordinate)
         
         ordinateFeldArray[nr] = ordinateframe
         ordinateframe.origin.x -= ordinateoffsetx
      }
      ordinateFeldArray[3] = ordinateframe
      
      let ordinatebgfarbe:NSColor  = NSColor(red: (0.0), green: (0.0), blue: (0.0), alpha: 0.0)
      //self.dataAbszisse_Volt.tag = 1
      
     
 
  //    self.dataAbszisse_Volt.setLinienfarbe(farbe: linienfarbe_Volt.cgColor)
//      self.dataAbszisse_Volt.setLinienfarbe(farbe: linienfarbe_Temperatur.cgColor)

      //var tasklist:[String] = ["Temperatur","ADC12Bit","Aux"]
      
      var kanaldic:[String:String] = [:]
      
      kanaldic["taskwahl"] = "0"
      kanaldic["taskcheck"] = "0"
      taskArray.removeAll()
      for _ in 0..<8
      {
         taskArray.append(kanaldic)
      }
      taskArray[0]["taskcheck"] = "1" // Ein kanal ist immer aktiviert
      
      taskArray[1]["taskcheck"] = "1" //
      
      taskArray[2]["taskcheck"] = "1" //
  //   taskArray[3]["taskcheck"] = "1" //
      
      taskArray[4]["taskcheck"] = "1" //
    taskArray[5]["taskcheck"] = "1" //
      anzahlChannels = countChannels() // Anzahl aktivierte kanaele
      Channels_Feld.intValue  = Int32(anzahlChannels)
      
      adcfloatarray = [Float] ( repeating: 0.0, count: 8 )
      // var tempwerte = [Float] ( repeating: 0.0, count: 9 )
      
      TaskListe.reloadData()
      
      //ordinateArray[0].frame.origin.y += 10
      //ordinateArray[0].frame = ordinateFeldArray[3]
  //    ordinateArray[2].frame = ordinateFeldArray[0]
      
    //  inputDataFeld.enclosingScrollView?.documentView?.frame.size.width = 1000
   //   print("xxx\(inputDataFeld.enclosingScrollView?.contentSize.width )")
      inputDataFeld.delegate = self
      
      // https://stackoverflow.com/questions/25179008/display-text-using-a-nsscrollview
      
    //  let contentsize = inputDataFeld.enclosingScrollView?.contentSize
      
     inputDataFeld.enclosingScrollView?.documentView?.frame.size.width = 2000 // muss
//    inputDataFeld.enclosingScrollView?.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
      inputDataFeld.enclosingScrollView?.hasHorizontalScroller = true
      inputDataFeld.enclosingScrollView?.hasVerticalScroller = true
      inputDataFeld.enclosingScrollView?.autohidesScrollers = false
      
//    inputDataFeld.maxSize = NSMakeSize(CGFloat.greatestFiniteMagnitude,CGFloat.greatestFiniteMagnitude)
      
      
//      inputDataFeld.textContainer?.containerSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
      
//      inputDataFeld.textContainer!.widthTracksTextView    =   true
      
      
     // inputDataFeld!.lineBreakMode = NSLineBreakByTruncatingTail
     // var   size = inputDataFeld.textContainer!.containerSize
     // size.width = 1.0e5;
     // inputDataFeld.textContainer!.containerSize = size
       
 //     inputDataFeld.textContainer?.containerSize = NSMakeSize(inputDataFeld.enclosingScrollView!.contentSize.width, CGFloat.greatestFiniteMagnitude)
      //inputDataFeld.textContainer?.containerSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)

       
      
      //    
  //    inputDataFeld.textContainer?.containerSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
 //     var paragraph:NSMutableParagraphStyle = NSMutableParagraphStyle.default() as! NSMutableParagraphStyle
 //     paragraph.lineBreakMode = NSLineBreakMode(rawValue: 2)! 
      
      downloadDataFeld.delegate = self
      downloadDataFeld.enclosingScrollView?.documentView?.frame.size.width = 20000 // muss
      downloadDataFeld.enclosingScrollView?.hasHorizontalScroller = true
      downloadDataFeld.enclosingScrollView?.hasVerticalScroller = true
      downloadDataFeld.enclosingScrollView?.autohidesScrollers = false
      downloadDataFeld.isHorizontallyResizable = false
      //downloadDataFeld.textContainer?.containerSize =  NSMakeSize((downloadDataFeld.enclosingScrollView?.contentSize.width)!, CGFloat.greatestFiniteMagnitude)
      downloadDataFeld.textContainer?.containerSize =  CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
      downloadDataFeld.textContainer?.widthTracksTextView = true
      
      
      // https://stackoverflow.com/questions/24002369/how-to-call-objective-c-code-from-swift
      let feld:NSRect = Vertikalbalken.frame
      Vertikalbalken = rVertikalanzeige(frame:feld)
      self.view.addSubview(Vertikalbalken)
     // Vertikalbalken.autoresizingMask |= NSViewMinYMargin
      //print("setAutoresizesSubviews: \(Vertikalbalken.autoresizingMask)")
      
      
      
      setupPrefs()
      
   }//viewDidLoad
   
   
   
   // ****************************************************************************
   //MARK: -   newLoggerDataAktion
   // ****************************************************************************
   // http://dev.iachieved.it/iachievedit/notifications-and-userinfo-with-swift-3-0/
   
   func newLoggerDataAktion(notification:Notification) -> Void
   {
      //print("ViewController newLoggerDataAktion info: \(notification.name)")
      //print("ViewController newLoggerDataAktion  userinfo data: \(notification.userInfo?["data"])");
      
      tagsec_Feld.integerValue = tagsekunde()
      teensy.new_Data = false
      // NSBeep()
      let code:Int = Int(teensy.read_byteArray[0])
      let codestring = int2hex(UInt8(code))
 //     print("newLoggerDataAktion code: \(code) \(codestring)")
      
    /*  
      print("read_byteArray code: ")
      for  index in 0..<16
      {
         print("\(teensy.read_byteArray[index])", terminator: "\t")
      }
      print("\n")
*/
      /*
      print("last_read_byteArray code: ")
      for  index in 0..<16
      {
         print("\(teensy.last_read_byteArray[index])", terminator: "\t")
      }
      print("\n")
*/
 //     print("newLoggerDataAktion data: ")

   //   print("newLoggerDataAktion data: ts\t\(tagsekunde())\t", terminator: "")
      /*
      print("last")

      for  index in 16..<32
      {
         print("\(teensy.last_read_byteArray[index])", terminator: "\t")
      }
 */
//      print("\naktuell")

//      for  index in 16..<32
//      {
//         print("\(teensy.read_byteArray[index])", terminator: "\t")
//      }

//      print("")
      
      
      switch (code)
      {
//MARK: READ_START      
         case READ_START:
         print("\nnewLoggerDataAktion READ_START:")
         let batt = (teensy.read_byteArray[USB_BATT_BYTE]) * 2
         print("READ_START batt: \(batt) messungcounter: \(teensy.read_byteArray[3])")
         print("\nREAD_START: read_byteArray code: ")
 
         for  index in 0..<DATA_START_BYTE
         {
            print("\(teensy.read_byteArray[index])", terminator: "\t")
         }
         print("")
         print("\nREAD_START: read_byteArray data: ")
         for  index in DATA_START_BYTE..<BUFFER_SIZE
         {
            print("\(teensy.read_byteArray[index])", terminator: "\t")
         }
         print("")
         
         for zeilenindex in 0..<swiftArray.count
         {
            let startdevicebatteriespannung = Float(teensy.read_byteArray[DATA_START_BYTE + zeilenindex]) * 2
               if startdevicebatteriespannung > 0
               {
                  let s = String(format:"%2.02fV", startdevicebatteriespannung/100)
                  swiftArray[zeilenindex]["batterie"] = String(format:"%2.02fV", startdevicebatteriespannung/100)
               }
         }
         cont_read_check.state = 0;
         TaskListe.reloadData()
         
      case TEENSY_DATA:
         /*
         print("TEENSY_DATA: ")
         for index in 16...24
         {
            print("\(teensy.read_byteArray[index])\t", terminator: "")
         }
 */
         let analog0LO = UInt16(teensy.read_byteArray[ANALOG0  + DATA_START_BYTE])
         let analog0HI = UInt16(teensy.read_byteArray [ANALOG0 + 1  + DATA_START_BYTE])
         let teensy0 = analog0LO | (analog0HI<<8)
         //print(" analog0: \(analog0LO) \(analog0HI) teensy0: \(teensy0) ")
         //print("")
         let teensy0float = Float(teensy0)
 //        print(" teensy0: \(teensy0) ")
         Vertikalbalken.setLevel(Int32(teensy0float*0xFF/1023))

         //MARK: CHECK_WL
      case CHECK_WL:
         //print("CHECK_WL:")
         //print("WL-status: \(teensy.read_byteArray[2])")
         // status der  device checken
         
         let wl_callback_status = (teensy.read_byteArray[2])
         let devicecount = (teensy.read_byteArray[DEVICECOUNT_BYTE])
         
         var deviceindex:Int = 0
         var changestatus = false
         for devicelinie in swiftArray
         {
            var zeile = devicelinie
            let device = devicelinie["device"]!
            let analog = devicelinie["A"]! // Tastenstatus Kanaele            print ("deviceindex: \(deviceindex) analog: \(analog)")
            let devicecode = UInt8(deviceindex)
            let oldstatus = Int(swiftArray[deviceindex]["on"]!)
            
            if (wl_callback_status & (1<<devicecode) > 0)
            {
               //print("device \(String(describing: device)) ist da")
               if (oldstatus == 0)
               {
                  swiftArray[deviceindex]["on"] = "1"
                  changestatus = true
               }
            }
            else
            {
               if (oldstatus == 1)
               {
                  swiftArray[deviceindex]["on"] = "0"
                  changestatus = true
               } 
            }
            deviceindex += 1
         }
         
         for zeilenindex in 0..<swiftArray.count
         {
            let startdevicebatteriespannung = Float(teensy.read_byteArray[DATA_START_BYTE + zeilenindex]) * 2
            if startdevicebatteriespannung > 0
            {
               let s = String(format:"%2.02fV", startdevicebatteriespannung/100)
               swiftArray[zeilenindex]["batterie"] = String(format:"%2.02fV", startdevicebatteriespannung/100)
            }
         }
         
  //     print("wl_callback_status:\t\(wl_callback_status) devicecount: \(devicecount)")
         wl_callback_status_Feld.intValue = Int32(wl_callback_status)
         
         teensy.read_OK = false
         usb_read_cont = false
         cont_read_check.state = 0;
         
         if (changestatus == true)
         {
            TaskListe.reloadData()
         }
         reorderAbszisse()
         break
         
         // ****************************************************************************
         //MARK: LOGGER_SETTINGS
      // ****************************************************************************
      case LOGGER_SETTING:
         print("LOGGER_SETTINGS:")
         print("Nr: \(teensy.read_byteArray[DATACOUNT_LO]) \(teensy.read_byteArray[DATACOUNT_HI]) ")
         
         // ****************************************************************************
         //MARK: LOGGER_START
      // ****************************************************************************
      case LOGGER_START: // Antwort auf LOGGER_START, Block geladen, Header des Blocks lesen
         
         print("\n*** newLoggerDataAktion LOGGER_START code: \(code) startblock: \(startblock)")
         
         // ladefehler
         let readerr: UInt8 = teensy.read_byteArray[READ_ERR_BYTE] // eventueller fehler ist im Byte 1
         if (readerr == 0) // alles OK
         {
            //print("newLoggerDataAktion LOGGER_START: OK")
            print("newLoggerDataAktion LOGGER_START  \nraw data:\n\(teensy.read_byteArray)\n")
            
            print("LOGGER_START CODE read_byteArray")
            
            for index in 0..<DATA_START_BYTE
            {
               print("\(teensy.read_byteArray[index])\t", terminator: "")
            }
            
            print ("")
            
            print("LOGGER_START DATA read_byteArray")
            
            for index in DATA_START_BYTE..<BUFFER_SIZE
            {
               print("\(teensy.read_byteArray[index])\t", terminator: "")
            }
            
            print ("")

            print("Header: ") // Daten oberhalb Block, nur fuer Kontrolle beim Download
            for index in (PACKET_SIZE)..<BUFFER_SIZE
            {
               print("\(index)\t\(teensy.read_byteArray[index])\t", terminator: "")
            }
            print ("")
            
            print("Header: ")
            
            // Daten sind nach DATA_STARTBYTE und HEADER_OFFSET
            // blockcounter
            var header_add = 0
            let tempblockdatacounter = UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add]) | (UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add + 1])<<8)
            print("tempblockdatacounter: \(tempblockdatacounter)")
            
            // lastpacket
            lastpacket = UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add]) | (UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add + 1])<<8)
            print("lastpacket: \(lastpacket)")

            header_add += 2
            // blockdatacounter
            let tempdatacounter = UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add]) | (UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add + 1])<<8)
            print("tempdatacounter: \(tempdatacounter)")
            
             
           // lastpacket = 0xFF
            
            header_add += 2
            // messungcounter
            let tempmessungcounter = UInt16(teensy.read_byteArray[DATA_START_BYTE  + HEADER_OFFSET + header_add]) | (UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add + 1])<<8)
            print("tempmessungcounter: \(tempmessungcounter)")
            
            header_add += 2
            // wl_callback_status: aktivierte devices
            let download_wl_callback_status = UInt16(teensy.read_byteArray[DATA_START_BYTE  + HEADER_OFFSET + header_add])
            print("download_wl_callback_status: \(download_wl_callback_status)")
            
            // 
            
            header_add += 2
            // intervall
            download_intervall = UInt16(teensy.read_byteArray[DATA_START_BYTE +  HEADER_OFFSET + header_add]) | (UInt16(teensy.read_byteArray[DATA_START_BYTE  + HEADER_OFFSET + header_add + 1])<<8)
            
            print("download_intervall: \(download_intervall)")
            

            //print("Kontrolle LOGGER_START teensy.last_read_byteArrayheader:")
            
            //for  index in 0..<HEADER_SIZE
            //{
            
            //print("\(teensy.last_read_byteArray[index])", terminator: "\t")
            //}
            //print("\n")
            packetcount = 0
            
            cont_log_USB(paketcnt: (packetcount))
            
         }
         else
         {
            print("newLoggerDataAktion LOGGER_START: Error")
         }
         // ****************************************************************************
         //MARK: LOGGER_CONT
      // ****************************************************************************
      case LOGGER_CONT:
         print("\nnewLoggerDataAktion LOGGER_CONT: \(code) packetcount: \(teensy.read_byteArray[PACKETCOUNT_BYTE])")
         let packetcount: UInt16 = UInt16(teensy.read_byteArray[PACKETCOUNT_BYTE]) // Byte 8
          downloaddatanummer += 1
         
         var last = false
         // header lesen byte 0 ist device und status
         let status: UInt8 = teensy.read_byteArray[DATA_START_BYTE]
         //print("status: \(status)")
         if (status & (1<<7) > 0)
         {
            print("last data \(downloaddatanummer)")
         }
         
         //print("lastpacket : \(lastpacket)")
        
         read_sd_progress.intValue = Int32(downloaddatanummer)
         
         if ((messungcounter.intValue > 0) && (UInt32(messungcounter.intValue) < downloaddatanummer))
         {
            print("fertig geladen bei \(downloaddatanummer)")
            
         }
         
         if ((lastpacket > 0) && (packetcount == lastpacket))
         {
            print("fertig geladen bei packetcount: \(packetcount)")
            last = true
         }
         
         //print("\nnewLoggerDataAktion LOGGER_CONT: \(code)\n teensy.last_read_byteArray: \(teensy.last_read_byteArray)")
         // ladefehler
         let readerr: UInt8 = teensy.read_byteArray[1] // eventueller fehler ist im Byte 1
         if (readerr == 0) // alles OK
         {
            
         }
         else
         {
            print("newLoggerDataAktion LOGGER_CONT: error");
         }
         
         // gelesene Daten
         
         if (teensy.read_byteArray.count > 1)
         {
            
            let messung = UInt16(teensy.read_byteArray[DATA_START_BYTE + 2]) | UInt16(teensy.read_byteArray[DATA_START_BYTE + 3]) << 8
 //           print("newLoggerDataAktion LOGGER_CONT: \(code) device: \(teensy.read_byteArray[DATA_START_BYTE + DEVICE]) Messung: \(messung) packetcount: \(teensy.read_byteArray[2])\n\traw Data\(teensy.read_byteArray)")
            
            if (Test_Knopf.state == 1)
            {
               
//               print("LOGGER_CONT TEST read_byteArray")
               
               for index in 0..<BUFFER_SIZE
               {
//                  print("\(teensy.read_byteArray[index])\t", terminator: "")
               }
               
               var temparray = teensy.read_byteArray[DATA_START_BYTE...(BUFFER_SIZE-1)] // Teilarray mit Daten, DATA_START_BYTE: 16
               let anz = temparray.count

//               print ("")
               var index = DATA_START_BYTE
               var newzeilenarray:[UInt16]! = []
               
               while (index < temparray.count) // index in temparray ist gleich wie im originalarray
               {
                  let tempwert:UInt16 = UInt16(temparray[index])
                  newzeilenarray.append(tempwert)
                  
                  if ((index > 0) && (index%24 == 0)) // neue zeile im String nach 16 Daten (8 werte)
                  {
                     //   print ("\nindex: \(index) newzeilenarray: \n\(newzeilenarray)")
                     let tempstring = newzeilenarray.map{String($0)}.joined(separator: "\t")
                     //print ("index: \(index)\t\(tempstring)")
                     inputDataFeld.string = inputDataFeld.string! + "\n" + tempstring
                     newzeilenarray.removeAll(keepingCapacity: true)
                  }
                  index = index + 1
               }

            }
            
            
            else if ((teensy.read_byteArray[DATA_START_BYTE + 1] == 0) && Test_Knopf.state == 0)
            {
               print("mist")
               //break;
            }
            else
            {
               //print("ok")
               
               
               /*
               print("LOGGER_CONT CODE read_byteArray")
               
               for index in 0..<DATA_START_BYTE
               {
                  print("\(teensy.read_byteArray[index])\t", terminator: "")
               }
               
               print ("")
               
               */
               print("LOGGER_CONT DATA read_byteArray")
               
               for index in DATA_START_BYTE..<BUFFER_SIZE
               {
                  print("\(teensy.read_byteArray[index])\t", terminator: "")
               }
               
               print ("")
               
               
               let tempmessungcounter = UInt16(teensy.read_byteArray[DATA_START_BYTE + 2]) | UInt16(teensy.read_byteArray[DATA_START_BYTE + 3])<<8
               
               print("tempmessungcounter: \(tempmessungcounter)")
               
               // http://stackoverflow.com/questions/25581324/swift-how-can-string-join-work-custom-types
               var temparray = teensy.read_byteArray[DATA_START_BYTE...(BUFFER_SIZE-1)] // Teilarray mit Daten, DATA_START_BYTE: 16
               let anz = temparray.count
               
//               print("LOGGER_CONT temparray: \(temparray)")
               
               //if (teensy.read_byteArray[DATA_START_BYTE + 1] != 0)
               //{
               var index = 0
               // hi und lo zusammenfuegen, neu speichern in newzeilenarray
               var newzeilenarray:[UInt16]! = []
               
               //let tempwert = temparray[DATA_START_BYTE + 1]
               
               while (index < temparray.count) // index in temparray ist gleich wie im originalarray
               {
                  let tempwert = temparray[DATA_START_BYTE + index]
                  index = index + 1
                  newzeilenarray.append(UInt16(tempwert))

               } // while
//               print ("newzeilenarray full: \n\(newzeilenarray)")
               
               let paragraphStyle = NSMutableParagraphStyle()
              // print("tabstops A: \(paragraphStyle.tabStops)")
               
               let tabInterval:CGFloat = 28.0
               paragraphStyle.tabStops.removeAll()
               
               for cnt in 0..<32 
               {    // Add 32 tab stops, at desired intervals...
                  paragraphStyle.tabStops.append(NSTextTab(textAlignment: .right, location: (CGFloat(cnt) * tabInterval), options: [:]))
               }               
               //print("tabstops: \(paragraphStyle.tabStops)")

               var tempstring = newzeilenarray.map{String($0)}.joined(separator: "\t") + "\n" // String erzeugen
               
               let attrdatatext = NSMutableAttributedString(string: tempstring)
               let datatextRange = NSMakeRange(0, tempstring.characters.count)
               attrdatatext.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: datatextRange)
               downloadDataFeld.textStorage?.append(attrdatatext)
               
               //let loremtext = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."
            // print("\(teensy.read_byteArray)")
               
               
            loggerDataArray.append(teensy.read_byteArray);
               
             // Umkehrung
               var teensyU16array = [UInt16]()
               print("\nUmkehrung teensy.read_byteArray:")
               for element in teensy.read_byteArray
               {
                  print("\(element)",terminator:"\t")
                  teensyU16array.append(UInt16(element))
               }
               print("")
               var spiegelarray = messungfloatzeileFromIntArray(data:teensyU16array)
               print("\nspiegelarray:")
               for zeile in spiegelarray
               {
                  print("\(zeile)\t")
               }
               print("")
               
            }
            
         }
         
         
         if ((packetcount < 20) && (last == false)) // 480 bytes pro block
         {
            // Anfrage fuer naechstes Paket schicken
            //packetcount =   packetcount + 1
            
            self.cont_log_USB(paketcnt: (UInt8(packetcount)))
         }
         else
         {
            // Block full
            downloadblocknummer = downloadblocknummer + 1
            print("LOGGER_CONT FULL startblock: \(startblock) blockcount: \(blockcount) downloadblocknummer: \(downloadblocknummer)")
           /*
            print("teensy.read_byteArray")
            var  index:UInt8 = 0;
            for index in 0..<BUFFER_SIZE
            {
               print("\(teensy.read_byteArray[index])\t", terminator: "")
            }
            
            print ("")
             */
            if (downloadblocknummer < blockcount) // noch weitere Blocks laden
            {
               print("LOGGER_CONT next downloadblocknummer: \(downloadblocknummer)")
               next_log_USB(downloadblocknummer: UInt16(downloadblocknummer))    
               
            }
            else
            {
               // download beenden
               print("LOGGER_CONT write file")
               
               teensy.read_OK = false
               teensy.write_byteArray[0] = UInt8(LOGGER_STOP)
               usb_read_cont = false
               cont_read_check.state = 0;
               let prefix = datumprefix()
               let dataname = "Logger/" + prefix + "_loggerdump.txt"
               
               var downloadstring = "\n" // nummer
               for tabpos in 0..<24
               {
                  downloadstring = downloadstring + "\(tabpos)\t"
               }
               
               downloadstring = downloadstring + "\n" + downloadDataFeld.string!
               
               
               writeData(name: dataname,data:downloadstring)

               //writeData(name: dataname,data:downloadDataFeld.string!)
              
               print("\(dataname)\n")
               print(downloadDataFeld.string!)
               let senderfolg = teensy.start_write_USB()
               print("LOGGER_CONT senderfolg: \(senderfolg)")
            }
            
         }
         
         // ****************************************************************************
         //MARK: LOGGER_NEXT
         // ****************************************************************************
         
      case LOGGER_NEXT:
         print("\nLOGGER_NEXT packetcount: \(packetcount)") // analog LOGGER_START, Antwort vom Logger auf LOGGER_NEXT: next block ist geladen
         
         /*
         print("teensy.read_byteArray")
         var  index:UInt8 = 0;
         
         print("LOGGER_NEXT CODE read_byteArray")

         for index in 0..<DATA_START_BYTE
         {
            print("\(teensy.read_byteArray[index])\t", terminator: "")
         }
         
         print ("")
         
         print("LOGGER_NEXT DATA read_byteArray")
         
         for index in DATA_START_BYTE..<BUFFER_SIZE
         {
            print("\(teensy.read_byteArray[index])\t", terminator: "")
         }
         
         print ("")
         */
         //print("Header: ")
         // blockcounter
         var header_add = 0
         let tempblockdatacounter = UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add]) | (UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add + 1])<<8)
         print("tempblockdatacounter: \(tempblockdatacounter)")
         
         // lastpacket
         lastpacket = UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add]) | (UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add + 1])<<8)
         print("lastpacket: \(lastpacket)")
         
         header_add += 2
         // blockdatacounter
         let tempdatacounter = UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add]) | (UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add + 1])<<8)
         print("tempdatacounter: \(tempdatacounter)")
         
         
           
         header_add += 2
         // messungcountercounter
         let tempmessungcounter = UInt16(teensy.read_byteArray[DATA_START_BYTE  + HEADER_OFFSET + header_add]) | (UInt16(teensy.read_byteArray[DATA_START_BYTE + HEADER_OFFSET + header_add + 1])<<8)
         print("tempmessungcounter: \(tempmessungcounter)")

         header_add += 2
         // wl_callback_status: aktivierte devices
         let download_wl_callback_status = UInt16(teensy.read_byteArray[DATA_START_BYTE  + HEADER_OFFSET + header_add])
         print("download_wl_callback_status: \(download_wl_callback_status)")
         
         // 
         
         header_add += 2
         // intervall
         let download_intervall = UInt16(teensy.read_byteArray[DATA_START_BYTE +  HEADER_OFFSET + header_add]) | (UInt16(teensy.read_byteArray[DATA_START_BYTE  + HEADER_OFFSET + header_add + 1])<<8)
         
         print("download_intervall: \(download_intervall)")
         
         if (packetcount < 20) // 480 bytes pro block
         {
             cont_log_USB(paketcnt: (packetcount))            
         }
         else
         {         
            blockcount -= 1
            print("LOGGER_NEXT blockcount: \(blockcount)")
            if (blockcount > 0) // noch weitere Blocks laden
            {
               print("LOGGER_NEXT next_log")
               
               next_log_USB(downloadblocknummer: UInt16(blockcount))
               
            }
            else
            {
               // download beenden
               print("LOGGER_NEXT write")
               teensy.read_OK = false
               teensy.write_byteArray[0] = UInt8(LOGGER_STOP) // Messungen im terensy wieder aufnehmen
               usb_read_cont = false
               cont_read_check.state = 0;
               
               
               let prefix = datumprefix()
               let dataname = "Logger/" + prefix + "_loggerdump.txt"
               
               var downloadstring = "n" // nummer
               for tabpos in 0..<32
               {
                  downloadstring = downloadstring + "\(tabpos)\t"
               }
               
               downloadstring = downloadstring + "\n" + downloadDataFeld.string!

               
               writeData(name: dataname,data:downloadstring)
              // writeData(name: dataname,data:downloadDataFeld.string!)
               
               print("\n")
            }
         }
         // ****************************************************************************
         //MARK: LOGGER_STOP
         // ****************************************************************************
         
      case LOGGER_STOP:
         
         packetcount = 0
         print("\nLOGGER_STOP")
         
         teensy.read_OK = false
         teensy.write_byteArray[0] = UInt8(LOGGER_STOP)
         usb_read_cont = false
         cont_read_check.state = 0;
         
         let prefix = datumprefix()
         let dataname = "Logger/" + prefix + "_loggerdump.txt"
         
         
         writeData(name: dataname,data:inputDataFeld.string!)
         
         //print("\n")
  //       var senderfolg = teensy.start_write_USB()
         
         
         print("\nnewLoggerDataAktion LOGGER_Stop loggerDataArray:")
         // print ("loggerDataArray:\n\(loggerDataArray)")
         
         
         // ****************************************************************************
      // ****************************************************************************
      case WRITE_MMC_TEST: break
         print("code ist WRITE_MMC_TEST")
         
         // ****************************************************************************
         // MARK: USB_STOP
         // ****************************************************************************
         
      case USB_STOP: break
         //print("code ist USB_STOP")
         
         // ****************************************************************************
         // MARK: MESSUNG_START
      // ****************************************************************************
      case MESSUNG_START:
         print("\ncode ist MESSUNG_START")
         print("teensy.read_byteArray")
         print("\t\(teensy.read_byteArray)")
         blockcounter.intValue = 0
         
         
         // ****************************************************************************
         // MARK: MESSUNG_STOP
         // ****************************************************************************
         
      case MESSUNG_STOP:
         print("code ist MESSUNG_STOP")
         print("teensy.read_byteArray")
         print("\(teensy.read_byteArray)")
         //blockcounter.intValue = 0
         let counterLO = Int32(teensy.read_byteArray[DATACOUNT_LO])
         let counterHI = Int32(teensy.read_byteArray[DATACOUNT_HI])
         let counter = (counterLO ) | ((counterHI )<<8)
         messungcounter.intValue = counter
         
         let blockposition = (Int32(teensy.read_byteArray[BLOCKOFFSETLO_BYTE]) & 0x00FF) | ((Int32(teensy.read_byteArray[BLOCKOFFSETHI_BYTE])  & 0x00FF)<<8)
         blockcounter.intValue = blockposition
         read_sd_anzahl.intValue = blockposition
         
         print("messungDataArray: ") // Array der Daten von readbytearray von DATA_START_BYTE an
         for line in messungDataArray
         {
            print("\(line)")
         }

         print("rawdataarray") 

         for line in rawdataarray
         {
            print("\(line)")
         }
         
         
         
         if (DiagrammDataArray.count > 1)
         {
            var messungstring:String = MessungDataString(data:DiagrammDataArray)
            
            let prefix = datumprefix()
            let intervall = IntervallPop.integerValue
            //let startblock = write_sd_startblock.integerValue
            
            var kopfstring = prefix + "\n" + "startzeit\t\(MessungStartzeit)\tintervall\t\(intervall)\tstartblock\t\(startblock)\nKanäle: \t\(anzahlChannels)"
            
            messungstring = kopfstring + messungstring
            
            let datastring:String = IntDataString(data:messungDataArray) // Array der Daten von readbytearray von DATA_START_BYTE an
            
            

            messungstring = messungstring + "\n" + "Data raw"  + "\n"
            messungstring = messungstring + "n\t" // nummer
            for tabpos in 0..<24
            {
               messungstring = messungstring + "\(tabpos)\t"
            }
            
            messungstring = messungstring + "\n" + datastring
            //let dataname = prefix + "_messungdump.txt"
            let dataname = "Messungen/" + prefix + "_messungdump.txt"
            writeData(name: dataname,data:messungstring)
         }
         

         // USB read beenden
         /*
         teensy.read_OK = false
          usb_read_cont = false
          cont_read_check.state = 0;
         */
         
         
         
         
      // ****************************************************************************
      // MARK: MESSUNG_DATA
      // ****************************************************************************
      
      case MESSUNG_DATA: // wird gesetzt, wenn vom Teensy im Timertakt Daten gesendet werden
         print("\ncode ist MESSUNG_DATA")
         //        print("teensy.read_byteArray")
         //        print("\(teensy.last_read_byteArray)")
         
         //var rawdatazeile:[Int] = Array(repeating:0,count:32) // raw data vom teensy, mit Header
         
         var rawdatazeile:[UInt8] = teensy.read_byteArray
         
         print("rawdatazeile read_byteArray. Data ab byte 8")
         
         for index in 0..<teensy.read_byteArray.count
         {
            print("\(teensy.read_byteArray[index])\t", terminator: "")
         }
         
         print ("")

         rawdataarray.append(rawdatazeile)
         
         let counterLO = Int32(teensy.read_byteArray[DATACOUNT_LO])
         let counterHI = Int32(teensy.read_byteArray[DATACOUNT_HI])
         
         var devicenummer = Int32((teensy.read_byteArray[DEVICE + DATA_START_BYTE])) & 0x0F // Device, 1-4
         let datacode = (Int32((teensy.read_byteArray[DEVICE + DATA_START_BYTE])) & 0xF0) >> 4   // Code fuer Datenbereich
         
         var channelnummer = Int32((teensy.read_byteArray[CHANNEL + DATA_START_BYTE]))
         
         //        print ("devicenummer: \(devicenummer)\tchannelnummer: \(channelnummer)")
         devicenummer &= 0x0F
         //print ("\ndevicenummer B: \(devicenummer)")
         
         
         let wl_callback_status = UInt8(teensy.read_byteArray[2])
         
   //      let devicecount = (teensy.read_byteArray[DEVICECOUNT_BYTE])
         
         // status der  device checken
         var deviceindex:Int = 0
         
         var changestatus = false
         
         
         for devicelinie in swiftArray
         {
            //var zeile = devicelinie
            let device = devicelinie["device"]!
            let analog = devicelinie["A"]! // Tastenstatus Kanaele           
            //print ("deviceindex: \(deviceindex) analog: \(analog)")
            let devicecode = UInt8(deviceindex)
            let oldstatus = Int(swiftArray[deviceindex]["on"]!) // bisheriger status, nur update wenn changed
            if (wl_callback_status & (1<<devicecode) > 0)
            {
               //print("device \(String(describing: device)) ist da")
               if (oldstatus == 0)
               {
                  swiftArray[deviceindex]["on"] = "1"
                  changestatus = true
               }
            }
            else
            {
               if (oldstatus == 1)
               {
                  swiftArray[deviceindex]["on"] = "0"
                  changestatus = true
               } 
            }
            deviceindex += 1
         } // for deviceline
         
         if (changestatus == true)
         {
            TaskListe.reloadData()
            
            reorderAbszisse()
         }
         
         //print("wl_callback_status:\t\(wl_callback_status)")
         wl_callback_status_Feld.intValue = Int32(wl_callback_status)
         
         let blockposition = (Int32(teensy.read_byteArray[BLOCKOFFSETLO_BYTE]) & 0x00FF) | ((Int32(teensy.read_byteArray[BLOCKOFFSETHI_BYTE])  & 0x00FF)<<8)
         blockcounter.intValue = blockposition
         
         let counter = (counterLO ) | ((counterHI )<<8)
         //print("counter:\t\(counter)")
         if (messungcounter.intValue != counter)
         {
            print("*********************** ")
            print("\nneue Messung Nr: \(counter) \t Block: \(blockposition)")
            print("*********************** ")
            devicestatus = 0
            // String beginnen
            inputDataFeldstring = messungcounter.stringValue  + "\t" + String(tagsekunde()-MessungStartzeit) + "\t" 
            
         }
         
         messungcounter.intValue = counter
         
         
 //        var tempinputDataFeldstring = String(tagsekunde()-MessungStartzeit) + "\t" + messungcounter.stringValue + "\t" 
         
         
//         let batterieLO = Int32(teensy.read_byteArray[5]) // batteriespannung teensy
//         let batterieHI = Int32(teensy.read_byteArray[6])
         let teensybatterie = Int32(teensy.read_byteArray[USB_BATT_BYTE])
         
         teensybatt.stringValue = NSString(format:"%.1f", teensybatterie) as String
         print("teensybatterie: \(teensybatterie)")      
         
         blockcounter.intValue = Int32(blockposition)
         
         
         
         var  analog0float:Float = 0
         var  analog1float:Float = 0
         var  analog2float:Float = 0
         var  analog3float:Float = 0
         
         var batteriefloat:Float = 0
         
         /*
          struct dataelement
          {
          var channel:Int
          var data:Float
          }
          
          */
         
         let DIAGRAMMDATA_OFFSET:Int = 4
         
         let messungzeitfloat = Float(tagsekunde())
         let messungzeit = tagsekunde()
        
         let task = Int(devicenummer)
         
         // wl_callback_status , devicenummer
         
         print("wl_callback_status: \(wl_callback_status) devicenummer: \(devicenummer) devicestatus: \(devicestatus)")
         
         switch (task)
         {
         case 0:
            
            print ("switch keine devicenummer: \(devicenummer)")
            
         case 1:
            // MARK: MESSUNG_DATA Device 1
            //print ("")
  /*
            print("task 1 CODE read_byteArray\tcount: \(counter)\t", terminator: "")
            
            for index in 0..<DATA_START_BYTE
            {
               print("\(teensy.read_byteArray[index])\t", terminator: "")
            }
            
            print ("")
*/
            
            
            print("\ntask 1 DATA read_byteArray\tcount: \(counter) *\t", terminator: "\n")
            
            for index in DATA_START_BYTE..<BUFFER_SIZE // DATA ab 8
            {
               print("\(teensy.read_byteArray[index])\t", terminator: "")
            }
            
            print ("")
            
    //        var temparray = teensy.read_byteArray[DATA_START_BYTE...(BUFFER_SIZE-1)] // Teilarray mit Daten, DATA_START_BYTE: 16
            var temparray:[UInt8] = []
           
            for pos in DATA_START_BYTE..<BUFFER_SIZE
            {
               temparray.append(teensy.read_byteArray[pos]) // DATA-Bereich schreiben
            }
            messungDataArray.append(temparray) //Array der Daten von readbytearray von DATA_START_BYTE an

            if (wl_callback_status & (1<<UInt8(task)) > 0) // device ist aktiv
            {
               print("\ndevice 1 aktiv")
               devicestatus |= (1<<UInt8(task))
               let device = swiftArray[task]
               
 //              print("wl_callback_status: \(wl_callback_status) devicenummer: \(devicenummer)  devicestatus: \(devicestatus)")
               
               //print("device \(String(describing: device)) ist da")
               //               swiftArray[task]["on"] = "1"
               inputDataFeldstring += ( String(devicenummer) + ":" + "\t")
               
               let devicebatteriespannung = Float(teensy.read_byteArray[USB_BATT_BYTE]) * 2 // halber Wert vom device
              
               
               //print ("switch task: \(task)\t devicebatteriespannung: \(devicebatteriespannung/100)")
               
               swiftArray[task]["batterie"] = String(format:"%2.02fV", devicebatteriespannung/100)

               
               //var messungfloatarray:[[Float]] = Array(repeating:Array(repeating:0,count:10),count:6)
               var devicearray:[Float] = Array(repeating:0.0,count:16)
               
               let analog0lo:Int32 =  Int32(teensy.read_byteArray[ANALOG0 + DATA_START_BYTE])
               let analog0hi:Int32 =  Int32(teensy.read_byteArray[ANALOG0+1 + DATA_START_BYTE])
               let analog0 = analog0lo | (analog0hi<<8)
               //print ("analog0lo: \(analog0lo) analog0hi: \(analog0hi)  analog0: \(analog0)");
               analog0float = Float(analog0) // * TEENSYVREF / 1024   // Kalibrierung teensy2: VREF ist 2.49 anstatt 2.56
               //print ("task 1 analog0float: \(analog0float)");
               
               devicearray[0] = analog0float
               
               messungfloatarray[task][DIAGRAMMDATA_OFFSET + 0] = analog0float
               
               adcfloatarray[0]  = analog0float
               //adcfloatarray[0]  = 0.0
               
               let analog1lo:Int32 =  Int32(teensy.read_byteArray[ANALOG1 + DATA_START_BYTE])
               let analog1hi:Int32 =  Int32(teensy.read_byteArray[ANALOG1+1 + DATA_START_BYTE])
               let analog1 = analog1lo | (analog1hi<<8)
               analog1float = Float(analog1) // * TEENSYVREF / 1024   // Kalibrierung teensy2: VREF ist 2.49 anstatt 2.56
               //print ("task 1 analog1float: \(analog1float)");
               
               analog1float = floorf(fabs(analog1float)*2.f) / 2.f
               //print ("analog1float floor: \(analog1float)");
               adcfloatarray[1]  = analog1float
               
               devicearray[1] = analog1float
               messungfloatarray[task][DIAGRAMMDATA_OFFSET + 1] = analog1float
               
               //adcfloatarray[1]  = 0.0
               
               var adc1anzeige = Float(roundit(Double(analog1float), toNearest: 0.5))
               
               //            ADC1Feld.stringValue = NSString(format:"%.01f", analog0float) as String
               
               // PT1000
               let analog2lo:Int32 =  Int32(teensy.read_byteArray[ANALOG2 + DATA_START_BYTE])
               let analog2hi:Int32 =  Int32(teensy.read_byteArray[ANALOG2+1 + DATA_START_BYTE])
               let analog2 = analog2lo | (analog2hi<<8)
               analog2float = Float(analog2)
               
               adcfloatarray[2]  = analog2float
               
               devicearray[2] = analog2float
               messungfloatarray[task][DIAGRAMMDATA_OFFSET + 2] = analog2float
               
               //print("task 1 analog2float: \(analog2float) )");
               
               
               let analog3lo:Int32 =  Int32(teensy.read_byteArray[ANALOG3 + DATA_START_BYTE])
               let analog3hi:Int32 =  Int32(teensy.read_byteArray[ANALOG3+1 + DATA_START_BYTE])
               let analog3 = analog3lo | (analog3hi<<8)
               analog3float = Float(analog3)
               adcfloatarray[3]  = analog3float
               
               devicearray[3] = analog3float
               messungfloatarray[task][DIAGRAMMDATA_OFFSET + 3] = analog3float
               
               //print("task 1 analog3float: \(analog3float) )");
               
               /*
                analog2float = analog2float * 2.56 / 1023
                print("analog2float B: \(analog2float) )");
                analog2float *= 20 // Anzeigewert anpassen
                
                print("analog2float C: \(analog2float) )");
                */
               
               let batteriespannung = Int32(teensy.read_byteArray[USB_BATT_BYTE])
               batteriefloat = Float(batteriespannung)
               
               print("batteriefloat USB_BATT_BYTE: \(batteriefloat)");
               let batt:String? = swiftArray[task]["batterie"]
               if (batteriefloat < Float(BATT_MIN))
               {
                  
                  var SD_antwort = dialogAlertMult(message: "Batteriespannung", information: "Die Batteriespannung betraegt nur noch \(batteriefloat)V", buttonOK: "Oops", buttonCancel: "")
                                        
                  if let batt = swiftArray[task]["batterie"]
                  {
                     print("Device 1 low batt: \(batt)")
                  }
                  return

               }
               
               // print ("")
            }
            else
            {
               
            }

            break
            
         case 2:
            // MARK: MESSUNG_DATA Device 2
             print("\ndevice 2 aktiv")
            //print ("")
            
            //print ("switch devicenummer: \(devicenummer)")
            
/*            
            print("task 2 CODE read_byteArray\tcount: \(counter)\t", terminator: "")
            
            for index in 0..<DATA_START_BYTE
            {
               print("\(teensy.read_byteArray[index])\t", terminator: "")
            }
            
            print ("")
 */           
            print("task 2 DATA read_byteArray\tcount: \(counter) *\t", terminator: "")
            
            for index in DATA_START_BYTE..<BUFFER_SIZE
            {
               print("\(teensy.read_byteArray[index])\t", terminator: "")
            }
            
            print ("")
            
            var temparray:[UInt8] = []
            
            for pos in DATA_START_BYTE..<BUFFER_SIZE
            {
               temparray.append(teensy.read_byteArray[pos])
            }
            messungDataArray.append(temparray)


            if (wl_callback_status & (1<<UInt8(task)) > 0)
            {
               devicestatus |= (1<<UInt8(task))
               let device = swiftArray[task]
               //print("device \(String(describing: device)) ist da")
               //               swiftArray[task]["on"] = "1"
               inputDataFeldstring += ( String(devicenummer) + ":" + "\t")
 //              print("wl_callback_status: \(wl_callback_status) devicenummer: \(devicenummer)  devicestatus: \(devicestatus)")
               
               let devicebatteriespannung = Float(teensy.read_byteArray[USB_BATT_BYTE]) * 2 // halber Wert vom device

               //print ("switch task: \(task)\t devicebatteriespannung: \(devicebatteriespannung/100)")
               let temp = Float(devicebatteriespannung)/100
               let tempstr = String(format:"%2.01f", temp)
               swiftArray[task]["batterie"] = String(format:"%2.02fV", devicebatteriespannung/100)
               
               
               let analog0lo:Int32 =  Int32(teensy.read_byteArray[ANALOG0 + DATA_START_BYTE])
               let analog0hi:Int32 =  Int32(teensy.read_byteArray[ANALOG0+1 + DATA_START_BYTE])
               
               let analog0 = analog0lo | (analog0hi<<8)
               //print ("analog0lo: \(analog0lo) analog0hi: \(analog0hi)  analog0: \(analog0)");
               analog0float = Float(analog0) // * TEENSYVREF / 1024   // Kalibrierung teensy2: VREF ist 2.49 anstatt 2.56
               //print ("task 2 analog0float: \(analog0float)");
               let analog0float_norm = analog0float / 0x1000 * 4.096
               adcfloatarray[5]  = analog0float / 0x800 * 4.096 * 10 // Wert wird im device halbiert, max ist 8V
               
               //print ("task 2 analog0float_norm: \(analog0float_norm)");
               
               messungfloatarray[task][DIAGRAMMDATA_OFFSET + 0] = analog0float  // DIAGRAMMDATA_OFFSET 4
               
               
               let analog1lo:Int32 =  Int32(teensy.read_byteArray[ANALOG1 + DATA_START_BYTE])
               let analog1hi:Int32 =  Int32(teensy.read_byteArray[ANALOG1+1 + DATA_START_BYTE])
               let analog1 = analog1lo | (analog1hi<<8)
               analog1float = Float(analog1) // * TEENSYVREF / 1024   // Kalibrierung teensy2: VREF ist 2.49 anstatt 2.56
               //print ("task 2 analog1float: \(analog1float)");
               
               analog1float = floorf(fabs(analog1float)*2.f) / 2.f
               //print ("analog1float floor: \(analog1float)");
               messungfloatarray[task][DIAGRAMMDATA_OFFSET + 1] = analog1float
               
               var adc1anzeige = Float(roundit(Double(analog1float), toNearest: 0.5))
               
               //          ADC1Feld.stringValue = NSString(format:"%.01f", analog0float) as String
               
               
               let analog2lo:Int32 =  Int32(teensy.read_byteArray[ANALOG2 + DATA_START_BYTE])
               let analog2hi:Int32 =  Int32(teensy.read_byteArray[ANALOG2+1 + DATA_START_BYTE])
               let analog2 = analog2lo | (analog2hi<<8)
               
               analog2float = Float(analog2)
               
  //             Vertikalbalken.setLevel(Int32(analog2float*0xFF/2500))
               
               //swiftArray[task]["batterie"] = String(analog2)
               
               messungfloatarray[task][DIAGRAMMDATA_OFFSET + 2] = analog2float
               spannungsanzeige.floatValue = analog2float
               spannungsanzeige.needsDisplay = true
               //print("task 2 analog2float: \(analog2float)");
               
               let analog3lo:Int32 =  Int32(teensy.read_byteArray[ANALOG3 + DATA_START_BYTE])
               let analog3hi:Int32 =  Int32(teensy.read_byteArray[ANALOG3+1 + DATA_START_BYTE])
               let analog3 = analog3lo | (analog3hi<<8)
               analog3float = Float(analog3)
               //            adcfloatarray[3]  = analog3float
               messungfloatarray[task][DIAGRAMMDATA_OFFSET + 3] = analog3float
               
               let batteriespannung = Int32(teensy.read_byteArray[USB_BATT_BYTE])
               batteriefloat = Float(batteriespannung)
               if (batteriefloat < Float(BATT_MIN))
               {
                  print("low batt: \(swiftArray[task]["batterie"])")
               }
               // print ("")
            }
         default:
            print ("")
            print ("---------------------")
            print ("")
            break
         }
         
         TaskListe.reloadData()
         
          
         //        analog1float = floorf(fabs(analog1float)*2.f) / 2.f
         // http://www.globalnerdy.com/2016/01/26/better-to-be-roughly-right-than-precisely-wrong-rounding-numbers-with-swift/
         
            
 //        let NR_LO = Int32(teensy.read_byteArray[DATACOUNT_LO + DATA_START_BYTE])
//         let NR_HI = Int32(teensy.read_byteArray[DATACOUNT_HI + DATA_START_BYTE])
         
 //        let messungnummer = NR_LO | (NR_HI<<8)
         
 //        let nrstring = String(messungnummer )
         _ = NumberFormatter()
         
         //print("messungnummer: \(messungnummer) adcfloat: \(adcfloat) String: \(adcfloat)");
         //        ADC1Feld.stringValue = NSString(format:"%.01f", analog0float) as String
         
         //loggerDataArray.append([UInt8(ADC0LO)]);
         //         var tempinputDataFeldstring = String(tagsekunde()-MessungStartzeit) + "\t" //+  ADC1Feld.stringValue
         
         
         //   let ADC1LO:Int32 =  Int32(teensy.read_byteArray[ADCLO+2])
         //   let ADC1HI:Int32 =  Int32(teensy.read_byteArray[ADCHI+2])
         //    let adc1 = ADC1LO | (ADC1HI<<8)
         let tempzeit = tagsekunde()
       //  let tempzeitfloat = Float(tempzeit)
         
         
         let diff = tempzeit - MessungStartzeit
       //  let diffstring = String(format:"%.0", diff)
         
         //print("MessungStartzeit: \(MessungStartzeit) tempzeitfloat: \(tempzeitfloat)  diff: \(diff)")
         
         // https://stackoverflow.com/questions/24074479/how-to-create-a-string-with-format
     //    let data0zeile:[Float] = [Float(diff),Float(analog0float),Float(analog1float),Float(analog2float)]
         
         // MARK: Datenzeile
         
         
         //  analog1float = floorf(fabs(analog1float)*2.f) / 2.f
         // http://www.globalnerdy.com/2016/01/26/better-to-be-roughly-right-than-precisely-wrong-rounding-numbers-with-swift/

         //   print ("datazeile \(data0zeile)\n")
         // datenzeile fuer Diagramm
         
         var AnzeigeFaktor:Float = 1.0 // Faktor für y-wert, abhängig von Abszisse-Skala
         var SortenFaktor:Float = 1.0 // Anzeige in Diagramm durch Sortenfaktor teilen
         var NullpunktOffset:Int = 0
         var stellen:Int = 1
         var tempwerte = [Float] ( repeating: 0.00, count: 9 )     // eine Zeile mit messung-zeit und 8 floats
         tempwerte[0] = Float(diff) // Abszisse
         
         
         // Array mit werten fuer einen Datensatz im Diagramm
         var werteArray = [[Float]](repeating: [0.0,0.0,1.0,1.0], count: 9 ) // Data mit wert, deviceID, sortenfaktor anzeigefaktor
         
         werteArray[0] = [Float(tempzeit),1.0,1.0] // Abszisse
         
         //Index fuer Werte im Diagramm
         var diagrammkanalindex = 1    // index 0 ist ordinate (zeit)                                   // Index des zu speichernden Kanals
         
          //print ("devicecount \(devicecount)\n")
         let anzdevice = swiftArray.count      // Anzahl
         
 //        var tempinputDataFeldstring = String(tagsekunde()-MessungStartzeit) + "\t" + messungcounter.stringValue  
         var tempinputDataFeldstring = messungcounter.stringValue + "\t"  + String(tagsekunde()-MessungStartzeit)
         
         
         //print ("tempinputDataFeldstring \(tempinputDataFeldstring)\n")
         
         
         for device in 0..<anzdevice
         {
            
            var deviceDatastring = ("\(device) \t")
            let devicedata = swiftArray[device]
            if (devicedata["on"] == "1") // device vorhanden
            {
               
               //devicestatus |= (1<<UInt8(device))
               
               let analog = UInt8(devicedata["A"]!)! // code fuer tasten des SegmentedControl
               
               // Zeile der Daten aus teensy
               //              let messungfloatzeilenarray:[Float] = messungfloatarray[device]
               //              print("device: \(String(describing: devicedata["device"]!)) analogtasten: \(String(describing: analog)) eingang messungfloatzeilenarray: \(messungfloatzeilenarray)")
               
               let devicecode = UInt8(device)
               
               let deviceID = Int(devicearray.index(of:devicedata["device"]!)!)
               //var wert_norm:Float = 0
     //          tempinputDataFeldstring = tempinputDataFeldstring + String(deviceID) + "\t"
               
               let messungfloatzeilenarray:[Float] = messungfloatarray[device]  // Array mit float-daten des device
               print("device: \(deviceID)   messungfloatzeilenarray:\t* \(messungfloatzeilenarray)*")
               //print("device: \(String(describing: devicedata["device"]!)) analogtasten: \(String(describing: analog)) eingang messungfloatzeilenarray: \(messungfloatzeilenarray)")
               
               // Kanaele des device abfragen
               for kanal in 0..<4
               {
                  SortenFaktor = 1
                  AnzeigeFaktor = 1.0
                  stellen = 1
                  let kanalint = UInt8(kanal)
                  if ((analog & (1<<kanalint) > 0) ) // kanal aktiv
                  {
                     /*
                     let messungfloatzeilenarray:[Float] = messungfloatarray[device]  // Array mit float-daten des device
                     print("device: \(deviceID) kanal: \(kanal)  messungfloatzeilenarray:\t* \(messungfloatzeilenarray)*")
                     //print("device: \(String(describing: devicedata["device"]!)) analogtasten: \(String(describing: analog)) eingang messungfloatzeilenarray: \(messungfloatzeilenarray)")
                      */
                     let wert = messungfloatzeilenarray[Int(kanal) + DIAGRAMMDATA_OFFSET] // 4
                     
                     var wert_norm:Float = wert
                     
                     switch deviceID
                     {
                     case 0: // teensy
                        //print("switch  teensy deviceID : \(deviceID) kanal: \(kanal)")
                        break
                     case 1:
                        //let ordinateMajorTeileY = dataAbszisse_Temperatur.AbszisseVorgaben.MajorTeileY
                        //let ordinateNullpunkt = dataAbszisse_Temperatur.AbszisseVorgaben.Nullpunkt
                        //print("switch  temp deviceID : \(deviceID) kanal: \(kanal)")
                        switch kanal
                        {
                        case 0: // LM35
                           wert_norm = wert / 10.0 // LM-Wert kommt mit Faktor 10
                           
                        case 1: // KTY
                           wert_norm = wert // KTY_FAKTOR
                        case 2: // PT100
                           wert_norm = wert
                        case 3: // aux
                           wert_norm = wert
                           
                        default: break
                        }// swicht kanal
                        
                        
                        break // THERMOMETER
                        
                     case 2:  // ADC12BIT
                        
                        //print("switch  ADC deviceID : \(deviceID) kanal: \(kanal)")
                        
                        //let ordinateMajorTeileY = dataAbszisse_Volt.AbszisseVorgaben.MajorTeileY
                        
                        //let ordinateNullpunkt = dataAbszisse_Volt.AbszisseVorgaben.Nullpunkt
                        
                        stellen = 2
                        if (kanal == 0 || kanal == 2) // 8V, geteilt durch 2
                        {
                           //print("kanal 0,2")
                           wert_norm = wert / 0x1000 * 4.096 * 20
                           AnzeigeFaktor = 2.0 // Anzeige strecken
                           SortenFaktor = 10 // Anzeige in Diagramm durch Sortenfaktor teilen: Volt kommt mit Faktor 10
                        }
                        if (kanal == 1 || kanal == 3)// 16V, geteilt durch 4
                        {
                           //print("kanal 1,3")
                           wert_norm = wert / 0x1000 * 4.096 * 40
                           SortenFaktor = 10 
                        }
                     //print("wert_norm: \(wert_norm)")
                     default: 
                        
                        break
                     }// switch device
                     
                     tempwerte[diagrammkanalindex] = wert_norm
                     werteArray[diagrammkanalindex] = [wert_norm, Float(deviceID), SortenFaktor, AnzeigeFaktor]
                     
                     // Zeile im Textfeld als string aufbauen
                     let stellenstring = "%.0\(stellen)f"
                     tempinputDataFeldstring = tempinputDataFeldstring + "\t" +  String(format:"%.\(stellen)f", wert_norm) 
                     //let formatstring = "%.\(stellen)f" as NSString
                     // let str = String(format:"%d, %f, %ld", INT_VALUE, FLOAT_VALUE, DOUBLE_VALUE)
                     //tempinputDataFeldstring = tempinputDataFeldstring + "\t" + (NSString(format:formatstring, wert_norm) as String)
                     
                     deviceDatastring = deviceDatastring  + "\t" +  String(format:"%.\(stellen)f", wert_norm)
                     diagrammkanalindex += 1
                     print("kanal: \(kanal) wert: \(wert) wert_norm: \(wert_norm)")

                  } // if (analog & (1<<kanalint) > 0)
                 
               } // for kanal
               //inputDataFeld.string = inputDataFeld.string! + String(messungnummer) +    tempinputDataFeldstring + "\t"

             } // if on
            
            }// for device
         
         print ("\n newLoggerDataAktion werteArray:")
         
         for zeile in werteArray
         {
            print("\(zeile)")
         }
         print("")
         
         print("Umkehrung")
         // Umkehrung
         var teensyU16array = [UInt16]()
         print("teensy.read_byteArray:")
         var z = 0
         for element in teensy.read_byteArray
         {
            print("\(element)", terminator:"\t")
            if z >= DATA_START_BYTE
            {
               teensyU16array.append(UInt16(element))
            }
            z = z + 1
         }
         print("")
         print("teensyU16array: \(teensyU16array)")
         
         var spiegelarray = werteArrayFromIntArray(data:teensyU16array)
         print("spiegelarray:")
         

         for zeile in spiegelarray
         {
            print("\(zeile)")
         }
         print("")
         print("end Umkehrung\n")
         
         if (devicestatus == wl_callback_status)
         {
            DiagrammDataArray.append(tempwerte)
            
            //           var paragraph:NSMutableParagraphStyle = NSMutableParagraphStyle.init() //as! NSMutableParagraphStyle
            //           paragraph.lineBreakMode = NSLineBreakMode(rawValue: 3)! 
            
            
            let text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."
            //       let teststring = tempinputDataFeldstring + text + "\n"
            
            
            //https://stackoverflow.com/questions/40478728/appending-text-to-nstextview-in-swift-3
            
            inputDataFeld.textStorage?.append(NSAttributedString(string:(tempinputDataFeldstring + "\n")))
            
         }
//         print("end for device.  devicestatus: \(devicestatus) wl_callback_status: \(wl_callback_status) devicestatus: \(devicestatus)")
         
         
         //       print ("tempinputDataFeldstring \(tempinputDataFeldstring)\n")
         
         
         
         
         // Zeile in inputDataFeld laden
         //        inputDataFeld.string = inputDataFeld.string! + String(messungnummer) + "\t" +  tempinputDataFeldstring  + "\n"
         
         inputDataFeld.scrollToEndOfDocument(nil)
         
         
         //tempwerte[1] = Float(analog0float)
         //tempwerte[2] = Float(analog1float)
         
         //tempwerte[3] = Float(adcfloat + 10)
         
         //print("tempwerte: \(tempwerte)")
        
         
         //print("DiagrammDataArray: \(DiagrammDataArray)")
         
         // Daten einsetzen in graph
         //         self.datagraph.setWerteArray(werteArray:tempwerte)
         
         
         
         
         //self.datagraph.setWerteArray(werteArray:tempwerte, anzeigefaktor:AnzeigeFaktor, nullpunktoffset: NullpunktOffset)
         
         //print("werteArray: \(werteArray)")
         
         
         self.datagraph.setWerteArray(werteArray:werteArray,  nullpunktoffset: NullpunktOffset)
         
         let PlatzRechts:Float = 20.0
         
         // breite des sichtbaren Bereichs
         let contentwidth = Float(self.dataScroller.contentView.bounds.size.width) 
         // The scroll view’s content view, the view that clips the document view
         
         // let lastdata = self.datagraph.DatenArray.last
         let lastxold = Float((self.datagraph.DatenArray.last?[0])!) // letzte ordinate
         let lastx = Float((self.datagraph.DatenDicArray.last?["x"])!)
         
         /*
          // MARK:*** Scrolling:
          https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/Scrolling.html#//apple_ref/doc/uid/TP40003463-SW1
          Adjust scroller: 
          https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/SynchroScroll.html#//apple_ref/doc/uid/TP40003537-SW5
          
          
          documentVisibleRect: The portion of the document view, in its own coordinate system, visible through the scroll view’s content view.
          
          */
         
         let currentScrollPosition = self.dataScroller.contentView.bounds.origin.x
         
         
         
         //       let newscrollorigin = NSMakePoint(currentScrollPosition - CGFloat(lastx),0.0)
         
         
         //// restore the scroll location
         //[[theScrollView documentView] scrollPoint:currentScrollPosition];
         
         //           self.dataScroller.documentView?.scroll(newscrollorigin)
         
         // http://stackoverflow.com/questions/9820669/i-dont-fully-understand-scrollrecttovisible-when-im-using-contentinset
         // https://developer.apple.com/reference/appkit/nsview/1483811-scrollrecttovisible?language=objc
         
         // http://stackoverflow.com/questions/35939381/programmatically-scroll-nsscrollview-to-the-right
         
         //        var scrollDelta = 10.0
         //        var rect:CGRect  = self.dataScroller.bounds;
         //       var scrollToRect:CGRect  = rect.offsetBy(dx: CGFloat(scrollDelta), dy: 0);
         
         //         self.dataScroller.documentView?.scrollToVisible(scrollToRect)
         
         
         
         // documentView: The view the scroll view scrolls within its content view
         
         // Nullpunkt des documentview
         let  docviewx = Float((self.dataScroller.documentView?.frame.origin.x)!)
         
         
         //        let aktuelledocpos = lastx + docviewx
         let grenze = (contentwidth / 10 * 8 ) + PlatzRechts
         
         //print(" docviewx:  \(docviewx)  aktuelledocpos: \(aktuelledocpos) grenze: \(grenze)")
         
         // print("\nmaxx: \(maxx) maxwidth: \(maxwidth) \tcurrentScrollPosition: \(currentScrollPosition)")
         if (counter == 0)
         {
            //            print("$$\tdocviewx:  \tlastx: \tdiff: \tcurrentScrollPosition:")
         }
         //print("$$$\(counter)\t\(docviewx)\t\(lastx) \t\(docviewx)\t\(lastx + docviewx)\t\(currentScrollPosition)")
         
         if (lastscrollposition != currentScrollPosition)
         {
            print("currentScrollPosition: \(currentScrollPosition)\t lastscrollposition: \(lastscrollposition) \tdocviewx: \(docviewx)  ")
            
            lastscrollposition = currentScrollPosition
            
            delayWithSeconds(3)
            {
               self.dataScroller.contentView.bounds.origin.x = 0
               
            }
            
         }
         
         if (((lastx) + docviewx ) > grenze) // docviewx ist negativ, wenn gegen links gescrollt wurde
         {
            let delta = contentwidth / 10 * 8
            
            print("lastdata zu gross \(lastx) delta:  \(delta)")
            self.dataScroller.documentView?.frame.origin.x -=   CGFloat(delta)
            
            self.dataScroller.contentView.needsDisplay = true
            
            
         }
         
         if (lastx > Float((self.dataScroller.documentView?.frame.size.width)! * 0.9))
         {
            print("currentScrollPosition: \(currentScrollPosition)\t lastx: \(lastx) \tdocviewx: \(docviewx)  ")    
            
            self.dataScroller.documentView?.frame.size.width += 1000
            self.dataScroller.contentView.bounds.origin.x = 0
            lastscrollposition = 0
            self.datagraph.augmentMaxX(maxX:1000)
            print("seite anfuegen \(lastx) new width:  \(dataScroller.documentView?.frame.size.width)")
         }
         
         // end data
         
         // ****************************************************************************
         // ****************************************************************************
         
      default: break
      print("code ist 0")
         
      } // switch code
      //return;
      
    //  var data = NSData(bytes: teensy.last_read_byteArray, length: 64)
      //print("data: \(data)")
      
      
 //     let b1: Int32 = Int32(teensy.last_read_byteArray[1])
 //     let b2: Int32 = Int32(teensy.last_read_byteArray[2])
      
      //print("b1: \(b1)\tb2: \(b2)\n");
      
      
 //     let rotA:Int32 = (b1 | (b2<<8))
      
   //   spannungsanzeige.intValue = Int32(rotA )
      
      // DS18S20
      
 //     let DSLOW:Int16 = Int16(teensy.last_read_byteArray[DSLO])
  //    let DSHIGH:Int16 = Int16(teensy.last_read_byteArray[DSHI])
/*      
      if (DSLOW > 0)
      {
         let temperatur = DSLOW | (DSHIGH<<8)
         
         //print("DSLOW: \(DSLOW)\tSDHIGH: \(DSHIGH) temperatur: \(temperatur)\n");
         
//         DSLO_Feld.intValue = Int32(DSLOW)
//         DSHI_Feld.intValue = Int32(DSHIGH)
         
         let  temperaturfloat:Float = Float(temperatur)/10.0
         _ = NumberFormatter()
         
       }
 */     
      teensy.new_Data = false
   }
   
   //MARK: -   Logger
   @IBAction func report_start_download_logger_USB(_ sender: AnyObject)
   {
      
      print("report_start_download_logger_USB");
      Stop_Logger.isEnabled = true
      zeit_Feld.stringValue = zeitstring()
      
      read_sd_progress.intValue = 0
      
      // tagmin_Feld.integerValue = tagminute
      tagsec_Feld.integerValue = tagsekunde()
      cont_read_check.state = 1
      teensy.read_OK = true
      usb_read_cont = (cont_read_check.state == 1)
      if (!teensy.teensy_present())
      {
         let erfolg = UInt8(teensy.USBOpen())
         if (erfolg == 0)
         {
            print("report_start_download_logger_USB: kein teensy da");
            return
         }
      }
      //_delay_us(100);
      let readerr = teensy.start_read_USB(usb_read_cont)
      
      if (readerr == 0)
      {
         print("Fehler in report_start_download_logger_USB")
      }
 //     Start_Logger.isEnabled = false
      Stop_Logger.isEnabled = true
      teensy.write_byteArray[0] = UInt8(LOGGER_START)
      startblock = UInt16(read_sd_startblock.integerValue)
      
      // index erster Block
      
      teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // byte 3
      teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)

      
      teensy.write_byteArray[DATACOUNT_LO] = UInt8(messungcounter.intValue & 0x00FF) // byte 3
      teensy.write_byteArray[DATACOUNT_HI] = UInt8((messungcounter.intValue & 0xFF00)>>8)

      
      
      blockcount = UInt16(read_sd_anzahl.integerValue) // Anzahl zu lesende blocks, angegeben im TextField read_sd_anzahl
      teensy.write_byteArray[BLOCK_ANZAHL_BYTE] = UInt8(blockcount & 0x00FF) // byte 9
      
      downloadblocknummer = 0
      teensy.write_byteArray[DOWNLOADBLOCKNUMMER_BYTE] = UInt8(downloadblocknummer & 0x00FF)
      
      packetcount=0
      
      teensy.write_byteArray[PACKETCOUNT_BYTE] = packetcount // beginn bei Paket 0
      
      // cont write aktivieren
      cont_write_check.state = 1
      //print("\nreport start download: teensy.last_read_byteArray: \(teensy.last_read_byteArray)")
      
      let senderfolg = teensy.start_write_USB()
      if (senderfolg > 0)
      {
         //inputDataFeld.string = inputDataFeld.string! + "\nBlock: " + String(startblock) + "\n"
         //inputDataFeld.string = "Block: " + String(startblock) + "\n"
         downloadDataFeld.string = "Block: " + String(startblock) + "\n"
      }
      else
      {
         downloadDataFeld.string = "Block: " + String(startblock) + "Start error" + "\n"
      }
      
   }
   
   //MARK: cont log
   func cont_log_USB(paketcnt: UInt8)
   {
      
      //print("cont_log_USB packetcount: \(paketcnt)");
      teensy.write_byteArray[0] = UInt8(LOGGER_CONT) // code
      teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF)
      teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
      
      teensy.write_byteArray[PACKETCOUNT_BYTE] = paketcnt // beginn bei Paket next
      teensy.write_byteArray[BLOCK_ANZAHL_BYTE] = 13
      
      var senderfolg = teensy.cont_write_USB()
      
   }
   
   //MARK: next log
   func next_log_USB(downloadblocknummer: UInt16) // teensy soll next block laden
   {
      
      print("\nnext_log_USB downloadblocknummer: \(downloadblocknummer)");
      teensy.write_byteArray[0] = UInt8(LOGGER_NEXT) // code
      
      
      packetcount=0
      teensy.write_byteArray[PACKETCOUNT_BYTE] = packetcount // beginn bei Paket 0
      
      // index erster Block
      //teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(blocknummer & 0x00FF)
      //teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((blocknummer & 0xFF00)>>8)
      
      teensy.write_byteArray[DOWNLOADBLOCKNUMMER_BYTE] = UInt8(downloadblocknummer & 0x00FF)
      
      //     delayWithSeconds(1)
      //     {
      
      var senderfolg = self.teensy.cont_write_USB()
      
      //    }
   }
   
   
   
   
   
   
   @IBAction func report_stop_log_USB(_ sender: AnyObject)
   {
      print("report_stop_log_USB");
      teensy.write_byteArray[0] = UInt8(LOGGER_STOP)
      
      var senderfolg = teensy.cont_write_USB()
      cont_read_check.state = 1
      
   }
   
   @IBAction func reportWriteCodeBit(_ sender: AnyObject)
   {
      print("reportBit1 tag: \(sender.tag)")
      let bit:UInt8 = UInt8(sender.tag)
      if (sender.state == 1)
      {
         usbstatus |= (1<<bit)
      }
      else
      {
         usbstatus &= ~(1<<bit)
      }
      codeFeld.intValue = Int32(usbstatus)
   }
   
   @IBAction func sendServoA(_ sender: AnyObject)
   {
      /*
      var formatter = NumberFormatter()
      var tempspannung:Double  = (extspannungFeld?.doubleValue)! * 100
      if (tempspannung > 3000)
      {
         tempspannung = 3000
          
      }
    */  
      let tempPos = ServoASlider.intValue
      
      //      extspannungFeld.doubleValue = ((tempspannung/100)+1)%12
      //var tempintspannung = UInt16(tempspannung)
      //print("tempPos: \(tempPos)");// L: \(spL.stringValue)\ttempintspannung H: \(spH.stringValue) ")
      //teensy.write_byteArray[0] = 0x01
      //print("write_byteArray 0: \(teensy.write_byteArray[0])")
      
      teensy.write_byteArray[0] = UInt8(SERVO_OUT)
      //teensy.write_byteArray[1] = UInt8(SAVE_SD_STOP)

      teensy.write_byteArray[SERVOALO] = UInt8(tempPos & (0x00FF))
      teensy.write_byteArray[SERVOAHI] = UInt8((tempPos & (0xFF00))>>8)
      //print("sendServoA: \(teensy.write_byteArray[SERVOALO])\t 11: \(teensy.write_byteArray[SERVOAHI])")
      var senderfolg = teensy.start_write_USB()
      //print("sendServoA senderfolg: \(senderfolg)")
      //teensy.write_byteArray[0] = 0x00 // bit 0 zuruecksetzen
      //senderfolg = teensy.report_start_write_USB()
   }
   
   
   
   @IBAction func sendSpannung(_ sender: AnyObject)
   {
      var formatter = NumberFormatter()
      var tempspannung:Double  = extspannungFeld.doubleValue * 100
      if (tempspannung > 3000)
      {
         tempspannung = 3000
         
      }
      //      extspannungFeld.doubleValue = ((tempspannung/100)+1)%12
      let tempintspannung = UInt16(tempspannung)
      //NSString(format:"%2X", a2)
      spL.stringValue = NSString(format:"%02X", (tempintspannung & 0x00FF)) as String
      spH.stringValue = NSString(format:"%02X", ((tempintspannung & 0xFF00)>>8)) as String
      print("tempintspannung L: \(spL.stringValue)\ttempintspannung H: \(spH.stringValue) ")
      teensy.write_byteArray[0] = 0x01
      print("write_byteArray 0: \(teensy.write_byteArray[0])")
      teensy.write_byteArray[1] = UInt8(tempintspannung & (0x00FF))
      teensy.write_byteArray[2] = UInt8((tempintspannung & (0xFF00))>>8)
      
      var senderfolg = teensy.start_write_USB()
      teensy.write_byteArray[0] = 0x00 // bit 0 zuruecksetzen
      //senderfolg = teensy.report_start_write_USB()
   }
   
   func setSpannung()
   {
      var beepSound = URL(fileURLWithPath: Bundle.main.path(forResource: "beep", ofType: "aif")!)
      
      
      var formatter = NumberFormatter()
      var tempspannung:Double  = extspannungFeld.doubleValue * 100
      if (tempspannung > 3000)
      {
         tempspannung = 3000
         
         
      }
      //      extspannungFeld.doubleValue = ((tempspannung/100)+1)%12
      let tempintspannung = UInt16(tempspannung)
      //NSString(format:"%2X", a2)
      spL.stringValue = NSString(format:"%02X", (tempintspannung & 0x00FF)) as String
      spH.stringValue = NSString(format:"%02X", ((tempintspannung & 0xFF00)>>8)) as String
      print("tempintspannung L: \(spL.stringValue)\ttempintspannung H: \(spH.stringValue) ")
      teensy.write_byteArray[0] = 0x01
      print("write_byteArray 0: \(teensy.write_byteArray[0])")
      teensy.write_byteArray[1] = UInt8(tempintspannung & (0x00FF))
      teensy.write_byteArray[2] = UInt8((tempintspannung & (0xFF00))>>8)
      
      var senderfolg = teensy.start_write_USB()
      teensy.write_byteArray[0] = 0x00 // bit 0 zuruecksetzen
      //senderfolg = teensy.report_start_write_USB()
   }
   
   
   
   @IBAction func sendStrom(_ sender: AnyObject)
   {
      print("send strom")
      var formatter = NumberFormatter()
      var tempstrom:Double  = extstrom.doubleValue * 100
      if (tempstrom > 3000)
      {
         tempstrom = 3000
         
      }
      let ired = NSString(format:"%2.2f", tempstrom/100)
      extstrom.stringValue = ired as String
      let tempintstrom = UInt16(tempstrom)
      //NSString(format:"%2X", a2)
      spL.stringValue = NSString(format:"%02X", (tempintstrom & 0x00FF)) as String
      spH.stringValue = NSString(format:"%02X", ((tempintstrom & 0xFF00)>>8)) as String
      print("tempintstrom L: \(spL.stringValue)\ttempintstrom H: \(spH.stringValue) ")
      teensy.write_byteArray[0] = 0x02
      print("write_byteArray 0: \(teensy.write_byteArray[0])")
      teensy.write_byteArray[1] = UInt8(tempintstrom & (0x00FF))
      teensy.write_byteArray[2] = UInt8((tempintstrom & (0xFF00))>>8)
      
      var senderfolg = teensy.start_write_USB()
      teensy.write_byteArray[0] = 0x00
   }
   
   func NSWindowWillCloseNotification(notification:Notification) -> Void
   {
      print("*** NSWindowWillCloseNotification \(notification)")
   }
   
   func USBfertigAktion(notification:Notification) -> Void
   {
      //print("USBfertigAktion \(notification)")
      //& http://stackoverflow.com/questions/30027780/swift-accessing-appdelegate-window-from-viewcontroller
      //     let appDelegate = NSApplication.shared().delegate as? AppDelegate
      //https://stackoverflow.com/questions/31467531/nswindow-returns-nil-nsapplication
      NSApp.activate(ignoringOtherApps: true)
      
      // https://stackoverflow.com/questions/43426391/how-do-you-reference-the-views-window-in-swift-3-x-using-storyboards-cocoa

      if (NSApplication.shared().mainWindow != nil)
      {
         //print("hauptfenster da")
         let hauptfenster:NSWindow = ((NSApplication.shared().mainWindow))!
         if (notification.object != nil)
         {
            //print("objektfenster da")
            let objektfenster :NSWindow = (notification.object as! NSWindow)
            if (hauptfenster == objektfenster)
            {
               //print("objektfenster ist hauptfenster")
               if (teensy.teensy_present() == true)
               {
                  teensy.write_byteArray[0] = UInt8(USB_STOP)
                  
                  //         teensy.write_byteArray[1] = UInt8(data0.intValue)
                  
                  let senderfolg = teensy.start_write_USB()
                  //print("USBfertigAktion teensy senderfolg: \(senderfolg)")
                  if (senderfolg > 0)
                  {
                     print("USBfertigAktion teensy schliessen OK")
                     //stop_messung()
                     stop_read_USB(self)
                     stop_write_USB(self)
                     
                  }
                  else
                  {
                     print("USBfertigAktion teensy schliessen nicht OK")
                     //stop_messung()
                     //stop_read_USB(self)
                     //stop_write_USB(self)
                     
                     //return
                  }
                  
               }
               else 
               {
                  print("kein teensy")
               }
               
               //print("beenden A")
               NSApplication.shared().terminate(self)
               //return
               
               
            }
            else 
            {
               //print("beenden B")
               return
               //NSApplication.shared().terminate(self)
               //return
            }
         }
      }
  //    let hauptfenster:NSWindow = ((NSApplication.shared().mainWindow))!
      
   //   let objektfenster :NSWindow = (notification.object as! NSWindow)
      
  //    if (hauptfenster == objektfenster)
      
         //print("hauptfenster")
         
         //teensycode &= ~(1<<7)
         //teensy.write_byteArray[15] = teensycode
      /*   
         teensy.write_byteArray[0] = UInt8(USB_STOP)
         
         //         teensy.write_byteArray[1] = UInt8(data0.intValue)
         
         let senderfolg = teensy.start_write_USB()
         if (senderfolg > 0)
         {
            print("*USBfertigAktion teensy schliessen OK")
            //stop_messung()
            stop_read_USB(self)
            stop_write_USB(self)
            
         }
         else
         {
            print("*USBfertigAktion teensy schliessen nicht OK")
            //stop_messung()
            //stop_read_USB(self)
            //stop_write_USB(self)
            
            //return
         }
      print("*beenden")

         NSApplication.shared().terminate(self)
         return
        */ 
      
    }
   
   @IBAction func check_USB(_ sender: NSButton)
   {

      let erfolg = UInt8(teensy.USBOpen())
      usbstatus = erfolg
      print("USBOpen erfolg: \(erfolg) usbstatus: \(usbstatus)")
 //     ordinateArray[0].frame = ordinateFeldArray[3]
 //     ordinateArray[0].needsDisplay = true
      if (rawhid_status()==1)
      {
         // NSBeep()
         //print("status 1")
         USB_OK.textColor = NSColor.green
         USB_OK.stringValue = "OK";
         manufactorer.stringValue = "Manufactorer: " + teensy.manufactorer()!
         Teensy_Status?.isEnabled = true;
         start_read_USB_Knopf?.isEnabled = true;
         stop_read_USB_Knopf?.isEnabled = true;
         start_write_USB_Knopf?.isEnabled = true;
         stop_write_USB_Knopf?.isEnabled = true;
         WL_Status?.isEnabled = true;
         Start_Messung?.isEnabled = true;
         Set_Settings?.isEnabled = true;
         cont_read_check?.isEnabled = true;
         cont_write_check?.isEnabled = true;
         
         Start_Logger.isEnabled = true
         
         swiftArray[0]["on"] = "1" // teensy ist da
         delayWithSeconds(1)
         {
            self.check_WL()
         }
         NSSound(named: "Frog")?.play()
      }
      else
         
      {
         //print("status 0")
         USB_OK.textColor = NSColor.red
         USB_OK.stringValue = "X";
         Teensy_Status?.isEnabled = false;
         start_read_USB_Knopf?.isEnabled = false;
         stop_read_USB_Knopf?.isEnabled = false;
         start_write_USB_Knopf?.isEnabled = false;
         stop_write_USB_Knopf?.isEnabled = false;
         cont_read_check?.isEnabled = false;
         cont_write_check?.isEnabled = false;         
         Start_Messung?.isEnabled = false;
         Set_Settings?.isEnabled = false;

         WL_Status?.isEnabled = false;
      }
      //print("antwort: \(teensy.status())")
      
   }
   
   @IBAction func stop_read_USB(_ sender: AnyObject)
   {
      teensy.read_OK = false
      usb_read_cont = false
      cont_read_check.state = 0;
      
   }
   
   @IBAction func stop_write_USB(_ sender: AnyObject)
   {
      usb_write_cont = false
      cont_write_check.state = 0;
   }
   
   @IBAction func close_USB(_ sender: AnyObject)
   {
      teensy.close_hid()
      manufactorer.stringValue = ""
      USB_OK.stringValue = "??"
   }
   
   //MARK: - Device Action
    
    @IBAction func reportBereichPop(_ sender: NSPopUpButton)
    {
      print("reportBereichPop tag: \(sender.tag) selected tag: \(String(describing: sender.selectedItem?.tag)) index: \(sender.indexOfSelectedItem)")
      var  selectedDevice:Int = (sender.selectedItem?.tag)! - (10 * sender.tag)
      selectedDevice /= 10
      print("tag: \(sender.tag)")
      print("reportBereichPop: selectedDevice: \(selectedDevice)")
      
      let bereichselektion = sender.indexOfSelectedItem
      switch (selectedDevice)
      {
      case 0: // teensy
         ordinateArray[selectedDevice].setStellen(stellen:0)
         swiftArray[selectedDevice]["bereichwahl"] = String(bereichselektion)

         
      case 1: // Temperatur
         
         ordinateArray[selectedDevice].setStellen(stellen:0)
         switch bereichselektion
         {
         case 0: // 0-80
            let Vorgaben:[String:Float] = ["MajorTeileY": 8,"MinorTeileY": 4 ,"Nullpunkt":0]
            ordinateArray[selectedDevice].setVorgaben(vorgaben: Vorgaben)
         case 1: // 0-160
            let Vorgaben:[String:Float] = ["MajorTeileY": 16,"MinorTeileY": 4 ,"Nullpunkt":0]
            ordinateArray[selectedDevice].setVorgaben(vorgaben: Vorgaben)
         case 2: // -30-100
            let Vorgaben:[String:Float] = ["MajorTeileY": 16,"MinorTeileY": 4,"Nullpunkt":2]
            ordinateArray[selectedDevice].setVorgaben(vorgaben: Vorgaben)
         default: break
         }
         swiftArray[selectedDevice]["bereichwahl"] = String(bereichselektion)
         //dataAbszisse_Temperatur.setMaxY(maxY: 160)
         
      case 2: // ADC
         ordinateArray[selectedDevice].setStellen(stellen:1)
         switch bereichselektion
         {
         case 0: // 0-8
            let Vorgaben:[String:Float] = ["MajorTeileY": 8,"MinorTeileY": 4]
            ordinateArray[selectedDevice].setVorgaben(vorgaben: Vorgaben)
         case 1: // 0-16
            let Vorgaben:[String:Float] = ["MajorTeileY": 16,"MinorTeileY": 2]
            ordinateArray[selectedDevice].setVorgaben(vorgaben: Vorgaben)

         default:
            break
         }// switch index
         swiftArray[selectedDevice]["bereichwahl"] = String(bereichselektion)
         
      default:
            break;
      }
      ordinateArray[selectedDevice].update()
   }
      
   /*
   fileprivate func configureDeviceCollectionView() {
      // 1
      let flowLayout = NSCollectionViewFlowLayout()
      flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
      flowLayout.sectionInset = EdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
      flowLayout.minimumInteritemSpacing = 20.0
      flowLayout.minimumLineSpacing = 20.0
      deviceCollectionView.collectionViewLayout = flowLayout
      // 2
      view.wantsLayer = true
      // 3
      deviceCollectionView.layer?.backgroundColor = NSColor.black.cgColor
   }
   */
      
   //MARK: - Konfig Messung
   @IBAction func reportSetSettings(_ sender: NSButton)
   {
      
      print("reportSetSettings")
      print("\(swiftArray)")
      teensy.write_byteArray[0] = UInt8(LOGGER_SETTING)
      //Task lesen
      
      let save_SD = save_SD_check?.state
      var loggersettings:UInt8 = 0
      if ((save_SD == 1)) // Daten auf SD sichern
      {
         loggersettings = loggersettings | 0x01 // Bit 0
         
      }
      
      teensy.write_byteArray[SAVE_SD_BYTE] = loggersettings
      //Intervall lesen
      // let selectedItem = IntervallPop.indexOfSelectedItem
      let intervallwert = IntervallPop.intValue
      
      // Taktintervall in array einsetzen
      teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(intervallwert & 0x00FF)
      teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((intervallwert & 0xFF00)>>8)
      //    print("reportTaskIntervall teensy.write_byteArray[TAKT_LO_BYTE]: \(teensy.write_byteArray[TAKT_LO_BYTE])")
      // Abschnitt auf SD
      
      // Zeitkompression setzen
      //let selectedKomp = ZeitkompressionPop.indexOfSelectedItem
      let kompressionwertwert = ZeitkompressionPop.intValue
      
      let kompvorgabe = ["zeitkompression":Float(kompressionwertwert)]
      datagraph.setVorgaben(vorgaben:kompvorgabe)
            
      //Angabe zum  Startblock lesen. default ist 0
      startblock = UInt16(write_sd_startblock.integerValue)
      
      // read_sd_startblock.intValue = Int32(startblock)
      teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
      teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
            
      let senderfolg = teensy.start_write_USB()
      if (senderfolg > 0)
      {
         NSSound(named: "Glass")?.play()
      }
   }
   
   @IBAction func reportTaskIntervall(_ sender: NSComboBox)
   {
      print("reportTaskIntervall index: \(sender.indexOfSelectedItem)")
      if (sender.indexOfSelectedItem >= 0)
      {
         let wahl = String(describing: sender.objectValueOfSelectedItem!)// as! String
         let index = sender.indexOfSelectedItem
         // print("reportTaskIntervall wahl: \(wahl) index: \(index)")
         // http://stackoverflow.com/questions/24115141/swift-converting-string-to-int
         let integerwahl:UInt16? = UInt16(wahl)
         print("reportTaskIntervall integerwahl: \(integerwahl!)")
         
         if let integerwahl = UInt16(wahl)
         {
            print("By optional binding :", integerwahl) // 20
         }
         
         //et num:Int? = Int(firstTextField.text!);
         // Taktintervall in array einsetzen
         teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(integerwahl! & 0x00FF)
         teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((integerwahl! & 0xFF00)>>8)
         //    print("reportTaskIntervall teensy.write_byteArray[TAKT_LO_BYTE]: \(teensy.write_byteArray[TAKT_LO_BYTE])")
      
         datagraph.setIntervall(intervall:Int(wahl)!)
      
      }
   }
   
   @IBAction func reportCheckbox(sender:NSButton)
   {
      print("reportCheckbox \(sender.state) tag: \(sender.tag)")
      let knopftag = Int(sender.tag)
      let zeile = knopftag%1000
      print("reportCheckbox zeile: \(zeile)")
      
      let knopfstatus = Int((swiftArray[zeile]["check"]!))//.integerValue
      
      if (knopfstatus == 1)
      {
         swiftArray[zeile]["check"] = "0"
      }
      else{
         swiftArray[zeile]["check"] = "1"
      }
      
      print("tableViewData nach Check:\n\(swiftArray)")
      
      //self.tableView.reloadData()
   }

   
   @IBAction func reportKanalwahl(_ sender: NSButton)
   {
      print("reportKanalwahl tag: \(sender.tag) ")
      
      let knopftag = Int(sender.tag)
      let zeile = knopftag%1100
      let key = "A" + String(zeile%10)
      print("reportKanalwahl zeile: \(zeile) key: \(key)")
      
      let knopfstatus = Int((swiftArray[zeile]["A0"]!))//.integerValue
      if (knopfstatus == 1)
      {
         swiftArray[zeile][key] = "0"
      }
      else{
         swiftArray[zeile][key] = "1"
      }
      
      print("tableViewData nach Kanalwahl:\n\(String(describing: swiftArray[zeile]["A0"]))")

   
   
   }
   
   @IBAction func reportWahlPop(_ sender: NSPopUpButton)
   {
      print("reportWahlPop sender tag: \(sender.tag) ")
      let index = (sender.tag / 10) - 10
      let zeile = sender.indexOfSelectedItem
      print("reportWahlPop sender zeile: \(zeile) ")
      
      taskArray[index]["taskwahl"] = String(zeile)
      /*
       let zeile = TaskListe.selectedRow
       var zelle = swiftArray[TaskListe.selectedRow]
       print("reportWahlPop zeile: \(zeile) zelle: \(zelle)")
       // tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int)
       //var wahlzeile = sender.indexOfSelectedItem
       let col:NSTableColumn = TaskListe.tableColumn(withIdentifier: "wahl")!
       
       let cell = col.dataCell
       // let itemliste = cell.itemArray
       // let item = cell.indexOfSelectedItem
       // let t = cell.title
       // let check = zelle["task"] as! Int
       // if (check == 0)
       */
   }
   
   
   @IBAction func reportChannelPop(_ sender: NSPopUpButton)
   {
      //print("reportChannelPop sender tag: \(sender.tag!) ")
      let index = (sender.tag / 10) - 10
      let zeile = sender.indexOfSelectedItem
      let channeltag = (sender.selectedItem?.tag)! - 400
      anzahlStoreChannels = channeltag
      print("reportChannelPop sender zeile: \(zeile) tag: \(channeltag)")
   }
   
   @IBAction func reportTaskCheck(_ sender: NSButton)
   {
      print("reportTaskCheck  sender tag: \(sender.tag) state: \(sender.state)")
      let index = (sender.tag / 1000) 
      let laststate = taskArray[index]["taskcheck"]
      print("reportTaskCheck  taskArray: \n\(taskArray) laststate: \(laststate)")

      taskArray[index]["taskcheck"] = String(sender.state)
      print("reportTaskCheck  taskArray: \n\(taskArray)")
      anzahlChannels = countChannels()
      Channels_Feld.intValue  = Int32(anzahlChannels)
   
   }
   
   
    @IBAction func reportAnalogTasten(_ sender: NSSegmentedControl)
    {
      let anz = sender.segmentCount
      let segment = sender.selectedSegment
      let segtag = sender.tag
      let zeile =  sender.tag % 10
      //print("vor: \(swiftArray[zeile]["A"]!)")
      let wert = swiftArray[zeile]["A"]!
      var selectcode = UInt8(wert)!
      print("reportAnalogTasten: anz: \(anz)  segment: \(segment)  segtag: \(segtag) zeile: \(zeile)")
      let status =  sender.isSelected(forSegment:segment)
      
      let seg = UInt8(segment)
      selectcode ^= (1<<seg)
 
      if (sender.isSelected(forSegment:segment))
      {
               
      }
      else
      {
         //swiftArray[zeile]["A"] = "0"
      }
       swiftArray[zeile]["A"] = String(describing: selectcode)
      
      //print("nach: \(swiftArray[zeile]["A"]!)")
      
   }
   
   func countChannels() ->Int
   {
      var anzahl = 0
      for zeile in taskArray
      {
         let a = zeile
         
         let rawstatus = zeile["taskcheck"]
         
         let status = Int(zeile["taskcheck"]!)
         if (status == 1)
         {
            anzahl = anzahl + 1
         }
      }
      
      return anzahl
   }
   
   @IBAction func report_zeitkompression(_ sender: NSComboBox)
   {
      let kompvorgabe:Float = sender.floatValue
      datagraph.setZeitkompression(kompression:kompvorgabe)
      
   }
   
   
   
   @IBAction func report_start_messung(_ sender: NSButton)
   {
 
      //print("start_messung sender: \(sender.state)") // gibt neuen State an
      var lineindex = 0
      for line in taskArray
      {
         //print("kanal: \(lineindex)\t\(String(describing: line["taskcheck"]!))")
         lineindex += 1
      }
      
      if (Channels_Feld.intValue == 0)
      {
         print("kein Kanal")
         return
      }
      
      // Messung starten
      if (sender.state == 1)
      {
         //print("start_messung start ")
         
         teensy.close_hid()
         
         let erfolg = UInt8(teensy.USBOpen())
         if (erfolg > 0)
         {
            usbstatus = erfolg
            //print("start_messung start OK")
         }
         else
         {
            
            print("start_messung error ")
            
            return;
         }
         
         // Sichern auf SD?
         var save_SD = save_SD_check?.state
         if (save_SD == 0)
         {
            var SD_antwort = dialogAlertMult(message: "Sicherung auf MMC", information: "Messungen auf MMC schreiben", buttonOK: "Sicher", buttonCancel: "Nein")
            print("antwort: \(SD_antwort)")
            if (SD_antwort == 1000) // JA
            {
               save_SD = 1
               save_SD_check?.state = 1
            }
         }

//         cont_read_check.state = 0;
         WL_Status.isEnabled = false

         //http://stackoverflow.com/questions/38031137/how-to-program-a-delay-in-swift-3
         //        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (timer) in
         // do stuff 1 seconds later
         //        }
         
         //teensy.write_byteArray.removeAll(keepingCapacity: true)
         //teensy.read_byteArray.removeAll(keepingCapacity: true)
         for var zeile in teensy.read_byteArray
         {
            zeile = 0
         }
         
         /*
          // aus reportTaskIntervall
          let wahl = sender.objectValueOfSelectedItem! as! String
          let index = sender.indexOfSelectedItem
          // print("reportTaskIntervall wahl: \(wahl) index: \(index)")
          // http://stackoverflow.com/questions/24115141/swift-converting-string-to-int
          let integerwahl:UInt16? = UInt16(wahl)
          print("reportTaskIntervall integerwahl: \(integerwahl!)")
          
          if let integerwahl = UInt16(wahl)
          {
          print("By optional binding :", integerwahl) // 20
          }
          
          //et num:Int? = Int(firstTextField.text!);
          // Taktintervall in array einsetzen
          teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(integerwahl! & 0x00FF)
          teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((integerwahl! & 0xFF00)>>8)
          //    print("reportTaskIntervall teensy.write_byteArray[TAKT_LO_BYTE]: \(teensy.write_byteArray[TAKT_LO_BYTE])")
          
          */
         
         // Intervall einsetzen
         var index = IntervallPop.indexOfSelectedItem
         //
         if (index < 0)
         {
            index = 0
            IntervallPop.selectItem(at:index)
         }
         let wahl = IntervallPop.objectValueOfSelectedItem as! String
         //print("reportTaskIntervall wahl: \(wahl) index: \(index)")
         
         let integerwahl:UInt16? = UInt16(wahl)
         //print("report_start_messung integerwahl: \(integerwahl!)")
         // Taktintervall in array einsetzen
         teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(integerwahl! & 0x00FF)
         teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((integerwahl! & 0xFF00)>>8)
         
         for  kan in 0..<swiftArray.count
         {
            let kanalindex = KANAL_BYTE
            let kanalstatus:UInt8 = UInt8(swiftArray[kan]["A"]!)!
            
            teensy.write_byteArray[KANAL_BYTE + kan] = kanalstatus //kanalauswahl
         }

         
         // code setzen
         teensy.write_byteArray[0] = UInt8(MESSUNG_START)
         
         if (save_SD == 1)
         {
            teensy.write_byteArray[1] = UInt8(SAVE_SD_RUN)
         }
 
//          teensy.write_byteArray[1] = UInt8(SAVE_SD_RUN)
         // Abschnitt auf SD
   //      teensy.write_byteArray[ABSCHNITT_BYTE] = 0
         
         //Angabe zum  Startblock aktualisieren
         startblock = UInt16(write_sd_startblock.integerValue)
         read_sd_startblock.intValue = Int32(startblock)
         teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
         teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
         
         //print("block lo: \(teensy.write_byteArray[BLOCKOFFSETLO_BYTE]) hi: \(teensy.write_byteArray[BLOCKOFFSETHI_BYTE])")
         
         
         let zeit = tagsekunde()
         print("start_messung startblock: \(startblock)  zeit: \(zeit)")
         
         let startminute = tagminute()
         teensy.write_byteArray[STARTMINUTELO_BYTE] = UInt8(startminute & 0x00FF)
         teensy.write_byteArray[STARTMINUTEHI_BYTE] = UInt8((startminute & 0xFF00)>>8)
         
         // 
         
         
         //        print("\nreport start messungT: teensy.last_read_byteArray: \(teensy.last_read_byteArray)")
         print("\nreport start messung: teensy.write_byteArray: \(teensy.write_byteArray)")
         
         DiagrammDataArray.removeAll()
         messungcounter.intValue = 0;
         
         inputDataFeld.string = "Messung tagsekunde: \(zeit)\n"
         
         downloadDataFeld.string = "Messung tagsekunde: \(zeit)\n"
 /*        
         let paragraphStyle = NSMutableParagraphStyle()
         paragraphStyle.tabStops = [NSTextTab(textAlignment: NSTextAlignment.left, location: 100, options: [:])]
         paragraphStyle.headIndent = 10
         let text = "xcvbnmvcxyxcvbnmbvcx cvbnmnvcxycvb cvb nmnv   cxy   cvb cvb  nmnv\t \(zeit)  cxy cvb\t\(String(zeit))\n"
         inputDataFeld.textStorage?.append(NSAttributedString(string: text, attributes: [NSParagraphStyleAttributeName: paragraphStyle]))
         inputDataFeld.textStorage?.append(NSAttributedString(string: "yxcvbnmvcxyxcvbnmbvcx cvbnmnvcxycvb cvb nmnv   cxy   cvb cvb  nmnv\t \(zeit)  cxy cvb\t\(String(zeit))\n"))
  */       
         
         
         dataScroller.documentView?.frame.origin.x = 0
         dataScroller.documentView?.frame.size.width = 1000
         let startscrollpunkt = NSMakePoint(0.0,0.0)
         dataScroller.contentView.scroll(startscrollpunkt)
         self.dataScroller.contentView.needsDisplay = true

         delayWithSeconds(1)
         {            
            
            self.datagraph.initGraphArray()
            self.datagraph.setStartsekunde(startsekunde:self.tagsekunde())
            self.datagraph.setMaxY(maxY: 160)
            self.datagraph.setDisplayRect()
            
            self.usb_read_cont = (self.cont_read_check.state == 1) // cont_Read wird bei aktiviertem check eingeschaltet
            
            self.teensy.write_byteArray[0] = UInt8(MESSUNG_START)
            //Do something
            
            let readerr = self.teensy.start_read_USB(true)
            if (readerr == 0)
            {
               print("Fehler in report_start_messung")
            }
            self.MessungStartzeitFeld.integerValue = self.tagsekunde()
            self.MessungStartzeit = self.tagsekunde()

         }
         
         var senderfolg = teensy.start_write_USB()
         if (senderfolg > 0)
         {
            NSSound(named: "Glass")?.play()
            
         }

      }
      else
      {
         //print("start_messung stop")
         stop_messung()
       }
      
     // let startscrollpunkt = NSMakePoint(dataScroller.frame.size.width,0.0)
   }

   /*
   @IBAction func report_stop_messung(_ sender: NSButton)
   {
      print("report_stop_messung") // gibt neuen State an
      
      print("stop_messung")
      teensy.write_byteArray[0] = UInt8(MESSUNG_STOP)
      teensy.write_byteArray[1] = UInt8(SAVE_SD_STOP)
      
      teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
      teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
      
//      teensy.read_OK = false
//      usb_read_cont = false
//      cont_read_check.state = 0;
      
      //print("DiagrammDataArray: \(DiagrammDataArray)")
      
      var messungstring:String = MessungDataString(data:DiagrammDataArray)
      
      let prefix = datumprefix()
      let intervall = IntervallPop.integerValue
      //let startblock = write_sd_startblock.integerValue
      
      var kopfstring = prefix + "\n" + "startzeit\t\(MessungStartzeit)\tintervall\t\(intervall)\tstartblock\t\(startblock)\nKanäle: \t\(anzahlChannels)"
      
      messungstring = kopfstring + messungstring
      
      let dataname = "Messungen/" + prefix + "_messungdump.txt"
      
      writeData(name: dataname,data:messungstring)
      
      //   let MessungDataString = DiagrammDataArray.map{String($0)}.joined(separator: "\n")
      /*
       print("messungstring: \(messungstring)\n")
       let erfolg = saveData(data: messungstring)
       if (erfolg == 0)
       {
       print("MessData sichern OK")
       NSSound(named: "Glass")?.play()
       }
       else
       {
       print("MessData sichern misslungen")
       
       }
       */
      
      
      var senderfolg = teensy.start_write_USB()
      if (senderfolg > 0)
      {
         NSSound(named: "Glass")?.play()
      }
      
   }
 */  
   func stop_messung()
   {
          teensy.write_byteArray[0] = UInt8(MESSUNG_STOP)
         teensy.write_byteArray[1] = UInt8(SAVE_SD_STOP)
         
         teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
         teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
         
      // in callback-Antwort MESSUNG_STOP verschoben
 //        teensy.read_OK = false
 //        usb_read_cont = false
 //        cont_read_check.state = 0;
         
         print("DiagrammDataArray count: \(DiagrammDataArray.count)")
         
        // var messungstring:String = MessungDataString(data:DiagrammDataArray)
         
         let prefix = datumprefix()
         let intervall = IntervallPop.integerValue
         //let startblock = write_sd_startblock.integerValue
 
       
      var senderfolg = teensy.start_write_USB()
      if (senderfolg > 0)
      {
         NSSound(named: "Glass")?.play()
         
      }
      print("stop_messung") // gibt neuen State an
      
 
   }
   
   func check_WL()
   {
//      teensy.close_hid()
      /*
      let erfolg = UInt8(teensy.USBOpen())

      if (erfolg == 0)
         {
            print("check_WL: kein teensy da");
            return
         }
 */
  //    print("\nreportcheck_WL: teensy.write_byteArray vor: \(teensy.write_byteArray)")
      MessungStartzeit = tagsekunde()
      teensy.write_byteArray[TAKT_LO_BYTE] = 1
      teensy.write_byteArray[TAKT_HI_BYTE] = 0
      // code setzen
      teensy.write_byteArray[0] = UInt8(CHECK_WL)
      
      // Sichern auf SD
      teensy.write_byteArray[1] = 0
      
      // Abschnitt auf SD
 //     teensy.write_byteArray[ABSCHNITT_BYTE] = 0

      //Angabe zum  Startblock aktualisieren
      startblock = 1
      teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
      teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
      cont_read_check.state = 1
      self.usb_read_cont = true
      //print("\nreportcheck_WL: teensy.write_byteArray nach: \(teensy.write_byteArray)")
      
      delayWithSeconds(1)
      {
         
         
         self.usb_read_cont = true // cont_Read einschalten
         
         self.teensy.write_byteArray[0] = UInt8(CHECK_WL)
         //Do something
         
         let readerr = self.teensy.start_read_USB(true)
         if (readerr == 0)
         {
            print("Fehler in check_WL")
         }
      }


      var senderfolg = teensy.start_write_USB()
      if (senderfolg > 0)
      {
         NSSound(named: "Tink")?.play()
      }

   }
   
   @IBAction func report_check_WL(_ sender: AnyObject)
   {
      check_WL()
   }
   
   func reorderAbszisse()
   {
      for ordinate in ordinateArray
      {
         ordinate.isHidden = true
      }
      var posarray:[Int] = []
      var pos:Int = 0
      for ind in 0..<swiftArray.count
      {
         if Int(swiftArray[ind]["on"]!) == 0
         {
            
         }
         else
         {
            posarray.append(Int(swiftArray[ind]["deviceID"]!)!)
            
         }
      
      }
      
      for ind in 0..<posarray.count
      {
         let deviceid = posarray[ind]
         let ordinatefeld = ordinateFeldArray[pos] 
         ordinateArray[deviceid].frame = ordinatefeld
         ordinateArray[deviceid].isHidden = false
         ordinateArray[deviceid].needsDisplay = true
         pos += 1
      }
      //print("reorderAbszisse posarray: \(posarray)")
   }
   
   @IBAction func report_start_write_USB(_ sender: AnyObject)
   {
      //NSBeep()
      //print("report_start_write_USB code: \(codeFeld.intValue)")
      print("report_start_write_USB code string: \(codeFeld.stringValue)")
      let code:UInt8 = UInt8(codeFeld.stringValue, radix: 16)!
      
      // teensy.write_byteArray[0] = UInt8(codeFeld.intValue)
      teensy.write_byteArray[0] = code
      teensy.write_byteArray[DATA_START_BYTE+1] = UInt8(data0.intValue)
      teensy.write_byteArray[DATA_START_BYTE+2] = UInt8(data1.intValue)
      teensy.write_byteArray[DATA_START_BYTE+3] = UInt8(data2.intValue)
      teensy.write_byteArray[DATA_START_BYTE+4] = UInt8(data3.intValue)
      //      print("new write_byteArray in report_start_write_USB: ", terminator: "\n")
      var i=0;
      
      //for  i in 0...63
      while i < 32
      {
         print("\(i)\t \(teensy.write_byteArray[i])\n", terminator: "")
         i = i+1
      }
      print("*")
      
      let dateA = Date()
      
      var senderfolg = teensy.start_write_USB()
      
      
      let dauer1 = Date() //
      let diff =  (dauer1.timeIntervalSince(dateA))*1000
      print("dauer report_start_write_USB: \(diff)")
      
      usb_write_cont = (cont_write_check.state == 1)
      
      //println("report_start_write_USB senderfolg: \(senderfolg)")
      
      
      if (usb_write_cont)
      {
         var timer : Timer? = nil
         timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(DataViewController.cont_write_USB(_:)), userInfo: nil, repeats: true)
         // http://stackoverflow.com/questions/38031137/how-to-program-a-delay-in-swift-3
         RunLoop.current.add(timer!, forMode: .commonModes)
         
      }
      
   }
   
   func cont_write_USB(_ timer: Timer)
   {
      print("*** \tcont_write usb: \(usb_write_cont)")
      // if (usb_write_cont)
      if (cont_write_check.state == 1)
      {
         
         //NSBeep()
         //teensy.write_byteArray[0] = UInt8((codeFeld.intValue)%0xff)
         //println("teensycode vor: \(teensycode)")
         
         teensycode |= UInt8((codeFeld.intValue)%0x0f)
         print("teensycode: \(teensycode)")
         teensy.write_byteArray[15] = teensycode
         teensy.write_byteArray[0] = UInt8((codeFeld.intValue)%0xff)
         
         teensy.write_byteArray[DATA_START_BYTE+1] = UInt8((data0.intValue)%0xff)
         teensy.write_byteArray[DATA_START_BYTE+2] = UInt8((data0.intValue)%0xff)
         teensy.write_byteArray[DATA_START_BYTE+3] = UInt8((data0.intValue)%0xff)
         
         print("spannungsanzeige: \(spannungsanzeige.intValue)")
         
         teensy.write_byteArray[8] = UInt8((spannungsanzeige.intValue)%0xff);
         teensy.write_byteArray[9] = UInt8(((spannungsanzeige.intValue)>>8)%0xff);
         //print("spannungsanzeige high: \(spannungsanzeige.intValue)")
         
         var c0 = codeFeld.intValue + 1
         //codeFeld.intValue = c0
         let c1 = data0.intValue + 1
         data0.intValue = c1
         
         var senderfolg = teensy.cont_write_USB()
         
      }
      else
      {
         timer.invalidate()
      }
      
   }
   
   @IBAction func Teensy_setState(_ sender: NSButton)
   {
      return
      if (sender.state > 0)
      {
         sender.title = "Teensy ON"
         teensycode |= (1<<7)
         teensy.write_byteArray[15] = teensycode
         // teensy.write_byteArray[0] |= UInt8(Teensy_Status.intValue)
         // teensy.write_byteArray[1] = UInt8(data0.intValue)
         
         var senderfolg = teensy.start_write_USB()
         
      }
      else
      {
         sender.title = "Teensy OFF"
         teensy.read_OK = false;
         //teensy.write_byteArray[15] = 0
         teensycode &= ~(1<<7)
         teensy.write_byteArray[15] = teensycode
         teensy.write_byteArray[0] |= UInt8(Teensy_Status.intValue)
         teensy.write_byteArray[1] = UInt8(data0.intValue)
         var senderfolg = teensy.start_write_USB()
         
      }
   }
   
   @IBAction func report_start_read_USB(_ sender: AnyObject)
   {
      // MARK: report_start_read_USB   
         //print("start_messung sender: \(sender.state)") // gibt neuen State an
        
      var lineindex = 0
         for line in taskArray
         {
            //print("kanal: \(lineindex)\t\(String(describing: line["taskcheck"]!))")
            lineindex += 1
         }
         
         if (Channels_Feld.intValue == 0)
         {
            print("kein Kanal")
            return
         }
         
         // Messung starten
         if (true)
         {
            //print("start_messung start ")
            /*
           teensy.close_hid()
            
            let erfolg = UInt8(teensy.USBOpen())
            if (erfolg > 0)
            {
               usbstatus = erfolg
               print("start_messung start OK")
            }
            else
            {
               
               print("start_messung error ")
            }
            */
            //         cont_read_check.state = 0;
            WL_Status.isEnabled = false
            
            //http://stackoverflow.com/questions/38031137/how-to-program-a-delay-in-swift-3
            //        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (timer) in
            // do stuff 1 seconds later
            //        }
            
            //teensy.write_byteArray.removeAll(keepingCapacity: true)
            //teensy.read_byteArray.removeAll(keepingCapacity: true)
            for var zeile in teensy.read_byteArray
            {
               zeile = 0
            }
            
            /*
             // aus reportTaskIntervall
             let wahl = sender.objectValueOfSelectedItem! as! String
             let index = sender.indexOfSelectedItem
             // print("reportTaskIntervall wahl: \(wahl) index: \(index)")
             // http://stackoverflow.com/questions/24115141/swift-converting-string-to-int
             let integerwahl:UInt16? = UInt16(wahl)
             print("reportTaskIntervall integerwahl: \(integerwahl!)")
             
             if let integerwahl = UInt16(wahl)
             {
             print("By optional binding :", integerwahl) // 20
             }
             
             //et num:Int? = Int(firstTextField.text!);
             // Taktintervall in array einsetzen
             teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(integerwahl! & 0x00FF)
             teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((integerwahl! & 0xFF00)>>8)
             //    print("reportTaskIntervall teensy.write_byteArray[TAKT_LO_BYTE]: \(teensy.write_byteArray[TAKT_LO_BYTE])")
             
             */
            
            // Intervall einsetzen
            var index = IntervallPop.indexOfSelectedItem
            //
            if (index < 0)
            {
               index = 0
               IntervallPop.selectItem(at:index)
            }
            let wahl = IntervallPop.objectValueOfSelectedItem as! String
            //print("reportTaskIntervall wahl: \(wahl) index: \(index)")
            
            let integerwahl:UInt16? = UInt16(wahl)
            //print("report_start_messung integerwahl: \(integerwahl!)")
            // Taktintervall in array einsetzen
            teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(integerwahl! & 0x00FF)
            teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((integerwahl! & 0xFF00)>>8)
            
            
            
            
            MessungStartzeitFeld.integerValue = tagsekunde()
            MessungStartzeit = tagsekunde()
            
            // code setzen
            teensy.write_byteArray[0] = UInt8(READ_START)
            
            // Sichern auf SD
            teensy.write_byteArray[1] = UInt8(SAVE_SD_RUN)
            
            // Abschnitt auf SD
 //           teensy.write_byteArray[ABSCHNITT_BYTE] = 0
            
            //Angabe zum  Startblock aktualisieren
            startblock = UInt16(write_sd_startblock.integerValue)
     //       read_sd_startblock.intValue = Int32(startblock)
            
            teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
            teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
            
            //print("block lo: \(teensy.write_byteArray[BLOCKOFFSETLO_BYTE]) hi: \(teensy.write_byteArray[BLOCKOFFSETHI_BYTE])")
            
            
            let zeit = tagsekunde()
            print("start_messung startblock: \(startblock)  zeit: \(zeit)")
            
            let startminute = tagminute()
            teensy.write_byteArray[STARTMINUTELO_BYTE] = UInt8(startminute & 0x00FF)
            teensy.write_byteArray[STARTMINUTEHI_BYTE] = UInt8((startminute & 0xFF00)>>8)
            //        print("\nreport start messungT: teensy.last_read_byteArray: \(teensy.last_read_byteArray)")
            print("\nreport start read: teensy.write_byteArray: \(teensy.write_byteArray)")
            
            DiagrammDataArray.removeAll()
            
            
            inputDataFeld.string = "Start read tagsekunde: \(zeit)\n"
            /*        
             let paragraphStyle = NSMutableParagraphStyle()
             paragraphStyle.tabStops = [NSTextTab(textAlignment: NSTextAlignment.left, location: 100, options: [:])]
             paragraphStyle.headIndent = 10
             let text = "xcvbnmvcxyxcvbnmbvcx cvbnmnvcxycvb cvb nmnv   cxy   cvb cvb  nmnv\t \(zeit)  cxy cvb\t\(String(zeit))\n"
             inputDataFeld.textStorage?.append(NSAttributedString(string: text, attributes: [NSParagraphStyleAttributeName: paragraphStyle]))
             inputDataFeld.textStorage?.append(NSAttributedString(string: "yxcvbnmvcxyxcvbnmbvcx cvbnmnvcxycvb cvb nmnv   cxy   cvb cvb  nmnv\t \(zeit)  cxy cvb\t\(String(zeit))\n"))
             */       
            
            
            dataScroller.documentView?.frame.origin.x = 0
            dataScroller.documentView?.frame.size.width = 1000
            let startscrollpunkt = NSMakePoint(0.0,0.0)
            dataScroller.contentView.scroll(startscrollpunkt)
            self.dataScroller.contentView.needsDisplay = true
            
            self.codeFeld.intValue = 0
            
            
            delayWithSeconds(1)
            {            
/*
               
               self.datagraph.initGraphArray()
               self.datagraph.setStartsekunde(startsekunde:self.tagsekunde())
               self.datagraph.setMaxY(maxY: 160)
               self.datagraph.setDisplayRect()
 */              
               self.usb_read_cont = (self.cont_read_check.state == 1) // cont_Read wird bei aktiviertem check eingeschaltet
               
               //self.teensy.write_byteArray[0] = UInt8(MESSUNG_START)
               //Do something6
               
               let readerr = Int32(self.teensy.start_read_USB(true))
               self.codeFeld.intValue = readerr

               if (readerr == 0)
               {
                  print("Fehler in report_start_messung")
               }
            }
            
         
         
         
         let senderfolg = teensy.start_write_USB()
         if (senderfolg > 0)
         {
            NSSound(named: "Glass")?.play()
         }
         // let startscrollpunkt = NSMakePoint(dataScroller.frame.size.width,0.0)
      }
      return;
      
      print("report_start_read_USB")
      //myUSBController.startRead(1)
      
      usb_read_cont = (cont_read_check.state == 1) // cont_Read wird bei aktiviertem check eingeschaltet
      teensy.write_byteArray[0] = UInt8(MESSUNG_START)
      // Intervall einsetzen
      var index = IntervallPop.indexOfSelectedItem
      //
      if (index < 0)
      {
         index = 0
         IntervallPop.selectItem(at:index)
      }
      let wahl = IntervallPop.objectValueOfSelectedItem as! String
      //print("reportTaskIntervall wahl: \(wahl) index: \(index)")
      
      let integerwahl:UInt16? = UInt16(wahl)
      //print("report_start_messung integerwahl: \(integerwahl!)")
      // Taktintervall in array einsetzen
      teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(integerwahl! & 0x00FF)
      teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((integerwahl! & 0xFF00)>>8)
      

     // 
      delayWithSeconds(1)
      {            
         
         self.usb_read_cont = (self.cont_read_check.state == 1) // cont_Read wird bei aktiviertem check eingeschaltet
         
         self.teensy.write_byteArray[0] = UInt8(MESSUNG_START)
         //Do something
         
         let readerr = Int32(self.teensy.start_read_USB(true))
         self.codeFeld.intValue = readerr
         if (readerr == 0)
         {
            print("Fehler in report_start_read")
         }
         else
         {
            print("report_start_read OK")
         }
      }
      
      let DSLOW:Int32 = Int32(teensy.read_byteArray[DSLO])
      let DSHIGH:Int32 = Int32(teensy.read_byteArray[DSHI])
      
      if (DSLOW > 0)
      {
         let temperatur = DSLOW | (DSHIGH<<8)
         
        }
        
      
      let analog0lo:Int32 =  Int32(teensy.read_byteArray[ANALOG0])
      let analog0hi:Int32 =  Int32(teensy.read_byteArray[ANALOG0+1])
      ADC0LO_Feld.intValue = analog0lo
      ADC0HI_Feld.intValue = analog0hi
      
      let analog0 = analog0lo | (analog0hi<<8)
      let  analog0float:Float = Float(analog0)/0xFFFF*5.0
      _ = NumberFormatter()
      
      //print("adcfloat: \(adcfloat) String: \(adcfloat)");
      ADC0Feld.stringValue = NSString(format:"%.02f", analog0float) as String
      
      //print ("adc0: \(adc0)");
      
      //teensy.start_teensy_Timer()
      
      //     var somethingToPass = "It worked"
      
      //      let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("tester:"), userInfo: somethingToPass, repeats: true)
      /*
       if (usb_read_cont == true)
       {
       var timer : Timer? = nil
       
       // Auslesen der Ergebnisse in teensy
       //       timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(DataViewController.cont_read_USB(_:)), userInfo: nil, repeats: true)
       }
       */
   }
   
   @IBAction func report_cont_read(_ sender: AnyObject)
   {
      //audioPlayer.play()
      NSSound(named: "Glass")?.play()
      let systemSoundID: SystemSoundID = 1016
      AudioServicesPlaySystemSound (systemSoundID)
      if (sender.state == 0)
      {
         usb_read_cont = false
      }
      else
      {
         usb_read_cont = true
      }
      //println("report_cont_read usb_read_cont: \(usb_read_cont)")
   }
   
   
   @IBAction func report_cont_write(_ sender: AnyObject)
   {
      NSSound(named: "Glass")?.play()
      
      if (sender.state == 0)
      {
         usb_write_cont = false
      }
      else
      {
         usb_write_cont = true
      }
      //println("report_cont_write usb_write_cont: \(usb_write_cont)")
   }
   
   
   open func int2hex(_ int:UInt8)->(String)
   {
      return String(format:"%2X", int)
   }
   
   
   @IBAction func ExitNow(_ sender: AnyObject)
   {
      NSLog("ExitNow");
      NSApplication.shared().terminate(self)
   }
   
   
   
   @IBAction func reportSaveMessung(sender: AnyObject)
   {
      // https://eclecticlight.co/2016/12/23/more-fun-scripting-with-swift-and-xcode-alerts-and-file-save/
      var fileContentToWrite:String = (inputDataFeld.string)!
      if (fileContentToWrite.characters.count == 0)
      {
         fileContentToWrite = "empty file"
      }
      // http://stackoverflow.com/questions/36436964/setting-initial-directory-for-nsopenpanel
      let FS = NSSavePanel()
      FS.canCreateDirectories = true
      FS.allowedFileTypes = ["txt"]
      FS.title = "Messung sichern"
      FS.nameFieldLabel = "Messung:"
      FS.nameFieldStringValue = datumprefix() + "_data"
      let messungPfad = "~/Documents/LoggerdataDir/Messungen" as NSString
      let messungURL = NSURL.fileURL(withPath: messungPfad.expandingTildeInPath , isDirectory: true)
      FS.directoryURL = messungURL
      //which should also allow “txt”
      FS.begin { result in
         if result == NSFileHandlingPanelOKButton {
            guard let url = FS.url else { return }
            do {
               try fileContentToWrite.write(to: url, atomically: false, encoding: String.Encoding.utf8)
            } catch {
               print ("SaveResBut error \(error.localizedDescription)")
               //we should really have an error alert here instead
            }
         }
      }
   }
   
   open func messungfloatzeileFromIntArray(data:[UInt16]) -> [Float]
   {
      let DIAGRAMMDATA_OFFSET = 4
      let LOGGERDATA_OFFSET = 8
      var messungfloatzeile = [Float]()
      
      let task = Int(data[0]) // devicenummer
      var kanalstatus = UInt(data[4]) // eingeschaltete Kanaele
      print ("task \(task) kanalstatus: \(kanalstatus)")
      
      for delta in 0..<4
      {
         var analogfloat = Float(Int32(data[LOGGERDATA_OFFSET + 2 * delta]) | (Int32(data[LOGGERDATA_OFFSET + 2 * delta + 1]))<<8)
         
         //print ("analog0lo: \(analog0lo) analog0hi: \(analog0hi)  analog0: \(analog0)");
         print ("kanal \(delta)  analogfloat: \(analogfloat) \tkanalstatus: ((kanalstatus & (1<<UInt(delta)) > 0))");
         messungfloatzeile.append(analogfloat)
         if (kanalstatus & (1<<UInt(delta)) > 0)
         {
            //print("1")
         }
         else
         {
            //print("0")
         }
      }
      
      return messungfloatzeile
   }
   
   open func werteArrayFromIntArray(data:[UInt16]) -> [[Float]]
   {
      print("\nwerteArrayFromIntArray data: \(data)")
      let DIAGRAMMDATA_OFFSET = 4
      let LOGGERDATA_OFFSET = 8
      
      var AnzeigeFaktor:Float = 1.0 // Faktor für y-wert, abhängig von Abszisse-Skala
      var SortenFaktor:Float = 1.0 // Anzeige in Diagramm durch Sortenfaktor teilen
      var NullpunktOffset = 0
      var stellen:Int = 1

      var tempwerte = [Float] ( repeating: 0.00, count: 9 )     // eine Zeile mit messung-zeit und 8 floats

      var werteArray = [[Float]](repeating: [0.0,0.0,1.0,1.0], count: 9 ) // Data mit wert, deviceID, sortenfaktor anzeigefaktor
       
     
      
      let messungcounter = UInt16(data[2] | (data[3] << 8))
      print("werteArrayFromIntArray messungcounter: \(messungcounter)")

       werteArray[0] = [Float(messungcounter),1.0,1.0] // Abszisse
      
      let deviceID = Int(data[0]) // devicenummer
      
      
      let kanalstatus = Int(data[4]) // eingeschaltete Kanaele
         
//      werteArray.append(Float(messungcounter))
      tempwerte[0] =  Float(messungcounter)
      
       let wl_callback_status = UInt8(wl_callback_status_Feld.intValue)
      
      
      
      //Index fuer Werte im Diagramm
      var diagrammkanalindex = 1    // index 0 ist ordinate 
      
      var tempinputDataFeldstring = String(messungcounter) + "\t"
      
      var downloadfloatzeile = messungfloatzeileFromIntArray(data:data) // floats aus uint8-data
      
      print("werteArrayFromIntArray downloadfloatzeile:\n* \(downloadfloatzeile)*")

      
      for kanal in 0..<4
      {
         SortenFaktor = 1
         AnzeigeFaktor = 1.0
         stellen = 1
         let kanalint = UInt8(kanal)
         let wert = downloadfloatzeile[Int(kanal)]
         var wert_norm:Float = wert
         
         switch deviceID
         {
         case 0: // teensy
            //print("switch  teensy deviceID : \(deviceID) kanal: \(kanal)")
            break
         case 1:
            //let ordinateMajorTeileY = dataAbszisse_Temperatur.AbszisseVorgaben.MajorTeileY
            //let ordinateNullpunkt = dataAbszisse_Temperatur.AbszisseVorgaben.Nullpunkt
            //print("switch  temp deviceID : \(deviceID) kanal: \(kanal)")
            switch kanal
            {
            case 0: // LM35
               wert_norm = wert / 10.0 // LM-Wert kommt mit Faktor 10
               
            case 1: // KTY
               wert_norm = wert // KTY_FAKTOR
            case 2: // PT100
               wert_norm = wert
            case 3: // aux
               wert_norm = wert
               
            default: break
            }// swicht kanal
            
            
            break // THERMOMETER
            
         case 2:  // ADC12BIT
            
            //print("switch  ADC deviceID : \(deviceID) kanal: \(kanal)")
            
            //let ordinateMajorTeileY = dataAbszisse_Volt.AbszisseVorgaben.MajorTeileY
            
            //let ordinateNullpunkt = dataAbszisse_Volt.AbszisseVorgaben.Nullpunkt
            
            stellen = 2
            if (kanal == 0 || kanal == 2) // 8V, geteilt durch 2
            {
               //print("kanal 0,2")
               wert_norm = wert / 0x1000 * 4.096 * 20
               AnzeigeFaktor = 2.0 // Anzeige strecken
               SortenFaktor = 10 // Anzeige in Diagramm durch Sortenfaktor teilen: Volt kommt mit Faktor 10
            }
            if (kanal == 1 || kanal == 3)// 16V, geteilt durch 4
            {
               //print("kanal 1,3")
               wert_norm = wert / 0x1000 * 4.096 * 40
               SortenFaktor = 10 
            }
         //print("wert_norm: \(wert_norm)")
         default: 
            
            break
         }// switch device
         
         print("kanal: \(kanal) wert: \(wert) wert_norm: \(wert_norm)")
         
         tempwerte[diagrammkanalindex] = wert_norm
         werteArray[diagrammkanalindex] = [wert_norm, Float(deviceID), SortenFaktor, AnzeigeFaktor]

         
         diagrammkanalindex += 1
      } // for kanal
      
      //print("tempwerte: \(tempwerte)")
      
       
      self.datagraph.setWerteArray(werteArray:werteArray,  nullpunktoffset: NullpunktOffset)
      return werteArray
      
      let PlatzRechts:Float = 20.0
      
      // breite des sichtbaren Bereichs
      let contentwidth = Float(self.dataScroller.contentView.bounds.size.width) 
      // The scroll view’s content view, the view that clips the document view


      let lastx = Float((self.datagraph.DatenDicArray.last?["x"])!)

      let currentScrollPosition = self.dataScroller.contentView.bounds.origin.x
      // Nullpunkt des documentview
      let  docviewx = Float((self.dataScroller.documentView?.frame.origin.x)!)
      let grenze = (contentwidth / 10 * 8 ) + PlatzRechts

      if (lastscrollposition != currentScrollPosition)
      {
         print("currentScrollPosition: \(currentScrollPosition)\t lastscrollposition: \(lastscrollposition) \tdocviewx: \(docviewx)  ")
         
         lastscrollposition = currentScrollPosition
         
         delayWithSeconds(3)
         {
            self.dataScroller.contentView.bounds.origin.x = 0
            
         }
         
      }

      if (((lastx) + docviewx ) > grenze) // docviewx ist negativ, wenn gegen links gescrollt wurde
      {
         let delta = contentwidth / 10 * 8
         
         print("lastdata zu gross \(lastx) delta:  \(delta)")
         self.dataScroller.documentView?.frame.origin.x -=   CGFloat(delta)
         
         self.dataScroller.contentView.needsDisplay = true
         
         
      }
      
      if (lastx > Float((self.dataScroller.documentView?.frame.size.width)! * 0.9))
      {
         print("currentScrollPosition: \(currentScrollPosition)\t lastx: \(lastx) \tdocviewx: \(docviewx)  ")    
         
         self.dataScroller.documentView?.frame.size.width += 1000
         self.dataScroller.contentView.bounds.origin.x = 0
         lastscrollposition = 0
         self.datagraph.augmentMaxX(maxX:1000)
         print("seite anfuegen \(lastx) new width:  \(dataScroller.documentView?.frame.size.width)")
      }

      
      return werteArray
      
      
      let anzdevice = 4
      for device in 0..<anzdevice
      {
         
         var deviceDatastring = ("\(device) \t")
         let devicedata = swiftArray[device]
         if (devicedata["on"] == "1") // device vorhanden
         {
            
            //devicestatus |= (1<<UInt8(device))
            
            let analog = UInt8(devicedata["A"]!)! // code fuer tasten des SegmentedControl
            
            // Zeile der Daten aus teensy
            //              let messungfloatzeilenarray:[Float] = messungfloatarray[device]
            //              print("device: \(String(describing: devicedata["device"]!)) analogtasten: \(String(describing: analog)) eingang messungfloatzeilenarray: \(messungfloatzeilenarray)")
            
            let devicecode = UInt8(device)
            
            let deviceID = Int(devicearray.index(of:devicedata["device"]!)!)
            
            //          tempinputDataFeldstring = tempinputDataFeldstring + String(deviceID) + "\t"
            
            // Kanaele des device abfragen
            for kanal in 0..<4
            {
               SortenFaktor = 1
               AnzeigeFaktor = 1.0
               stellen = 1
               let kanalint = UInt8(kanal)
               
               if ((analog & (1<<kanalint) > 0) ) // kanal aktiv
               {
                  let messungfloatzeilenarray:[Float] = messungfloatarray[device]
                  //print("device: \(String(describing: devicedata["device"]!)) analogtasten: \(String(describing: analog)) eingang messungfloatzeilenarray: \(messungfloatzeilenarray)")
                  let wert = messungfloatzeilenarray[Int(kanal) + DIAGRAMMDATA_OFFSET] // 4
                  
                  var wert_norm:Float = wert
                  
                  switch deviceID
                  {
                  case 0: // teensy
                     //print("switch  teensy deviceID : \(deviceID) kanal: \(kanal)")
                     break
                  case 1:
                     //let ordinateMajorTeileY = dataAbszisse_Temperatur.AbszisseVorgaben.MajorTeileY
                     //let ordinateNullpunkt = dataAbszisse_Temperatur.AbszisseVorgaben.Nullpunkt
                     //print("switch  temp deviceID : \(deviceID) kanal: \(kanal)")
                     switch kanal
                     {
                     case 0: // LM35
                        wert_norm = wert / 10.0 // LM-Wert kommt mit Faktor 10
                        
                     case 1: // KTY
                        wert_norm = wert // KTY_FAKTOR
                     case 2: // PT100
                        wert_norm = wert
                     case 3: // aux
                        wert_norm = wert
                        
                     default: break
                     }// swicht kanal
                     
                     
                     break // THERMOMETER
                     
                  case 2:  // ADC12BIT
                     
                     //print("switch  ADC deviceID : \(deviceID) kanal: \(kanal)")
                     
                     //let ordinateMajorTeileY = dataAbszisse_Volt.AbszisseVorgaben.MajorTeileY
                     
                     //let ordinateNullpunkt = dataAbszisse_Volt.AbszisseVorgaben.Nullpunkt
                     
                     stellen = 2
                     if (kanal == 0 || kanal == 2) // 8V, geteilt durch 2
                     {
                        //print("kanal 0,2")
                        wert_norm = wert / 0x1000 * 4.096 * 20
                        AnzeigeFaktor = 2.0 // Anzeige strecken
                        SortenFaktor = 10 // Anzeige in Diagramm durch Sortenfaktor teilen: Volt kommt mit Faktor 10
                     }
                     if (kanal == 1 || kanal == 3)// 16V, geteilt durch 4
                     {
                        //print("kanal 1,3")
                        wert_norm = wert / 0x1000 * 4.096 * 40
                        SortenFaktor = 10 
                     }
                  //print("wert_norm: \(wert_norm)")
                  default: 
                     
                     break
                  }// switch device
                  
                  tempwerte[diagrammkanalindex] = wert_norm
                  werteArray[diagrammkanalindex] = [wert_norm, Float(deviceID), SortenFaktor, AnzeigeFaktor]
                  
                  // Zeile im Textfeld als string aufbauen
                  let stellenstring = "%.0\(stellen)f"
                  tempinputDataFeldstring = tempinputDataFeldstring + "\t" +  String(format:"%.\(stellen)f", wert_norm) 
                  //let formatstring = "%.\(stellen)f" as NSString
                  // let str = String(format:"%d, %f, %ld", INT_VALUE, FLOAT_VALUE, DOUBLE_VALUE)
                  //tempinputDataFeldstring = tempinputDataFeldstring + "\t" + (NSString(format:formatstring, wert_norm) as String)
                  
                  deviceDatastring = deviceDatastring  + "\t" +  String(format:"%.\(stellen)f", wert_norm)
                  diagrammkanalindex += 1
                  
               } // if (analog & (1<<kanalint) > 0)
               
            } // for kanal
            //inputDataFeld.string = inputDataFeld.string! + String(messungnummer) +    tempinputDataFeldstring + "\t"
            
         } // if on
         
      } // for device
      
      if (devicestatus == wl_callback_status)
      {
         DiagrammDataArray.append(tempwerte)

         
         inputDataFeld.textStorage?.append(NSAttributedString(string:(tempinputDataFeldstring + "\n")))
         
      } // if devicestatus
      
         return werteArray
   }

   
   
   
   // MARK: reportOpenData
   @IBAction func reportOpenData(sender: AnyObject)
   {
      // https://eclecticlight.co/2016/12/23/more-fun-scripting-with-swift-and-xcode-alerts-and-file-save/
      //and so on to build the text to be written out to the file
      let FS = NSOpenPanel()
      FS.canCreateDirectories = true
      FS.allowedFileTypes = ["txt"]
      FS.title = "Messung sichern"
      FS.nameFieldLabel = "Messung:"
      FS.nameFieldStringValue = datumprefix() + "_data"
      let messungPfad = "~/Documents/LoggerdataDir" as NSString
      let messungURL = NSURL.fileURL(withPath: messungPfad.expandingTildeInPath , isDirectory: true)
      FS.directoryURL = messungURL
      // http://stackoverflow.com/questions/41349781/nsopenpanel-nssavepanel-crashes-in-swift-3
      if (FS.runModal() == NSModalResponseOK)
      {
         let result = FS.url // Pathname of the file
         
         if (result != nil)
         {
            let path = result!.path
            print("browseFile path: \(path)")
            //filename_field.stringValue = path
            do
            {
               let datastring = try String(contentsOf: result!, encoding: String.Encoding.utf8)
               //print("datastring\n\(datastring)\n")
               inputDataFeld.string = datastring
               //let loggerdataDicArray = datagraph.diagrammDataDicFromLoggerData(loggerdata: datastring)
               
               let loggerDataArray:[[UInt16]] = datagraph.diagrammDataArrayFromLoggerData(loggerdata: datastring)
               
               print("reportOpenData loggerdataArray\n")
               for zeile in loggerDataArray
               {
                  print("\(zeile)")
                  
               }
               
               
               self.datagraph.initGraphArray()
               self.datagraph.setStartsekunde(startsekunde:0)
               self.datagraph.setMaxY(maxY: 150)
               self.datagraph.setDisplayRect()
               
               let NullpunktOffset = 0
               
               var index = 0
               for zeile in loggerDataArray
               {
                  
                  let werteArray = werteArrayFromIntArray(data:zeile)
                  print("index: \(index) werteArray")
                  for zeile in werteArray
                  {
                     print(" \(zeile)")
                  }
                  //print("tempwerte: index \(index) * \(werteArray)")
                  self.datagraph.setWerteArray(werteArray:werteArray,  nullpunktoffset: NullpunktOffset)
                  index = index + 1
                  
               }
               
               print("anzdaten: \(index)")
            }
            catch
            {
               print("Fehler beim Oeffnen an Pfad: \(path)")
               inputDataFeld.string = "Fehler beim Oeffnen an Pfad: \(path)"
            }
         }
         
      }
      else
      {
         print("User clicked on \"Cancel\"")
         return
      }
      
   }

   /*
   func numberOfRows(in tableView: NSTableView) -> Int
   {
      // OK

      return self.swiftArray.count
   }
  */
  
   func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool
   {
      let item = tabView.indexOfTabViewItem(tabViewItem!)

      //let abc:String = String(describing: tabViewItem?.identifier)
     let i = Int(item)
      let e = tabViewItem?.identifier as? Int
     //print(Array(abc.characters))
      //print("shouldSelect: ident: \(String(describing: tabViewItem?.identifier))")
      print("abc: \(item)")
      
      
      return true
   }

   
   func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?
   {
      
      // var tempzeile = swiftArray[row]
      
      guard swiftArray[row]["device"] != nil
         else
      {
         return nil
      }
      let objekt = self.swiftArray[row]
      
      return objekt[(tableColumn?.identifier)!]
      
      //print("objectValueFor row:\(row) ident: \(tableColumn?.identifier)")
      if (tableColumn?.identifier == "on")
      {
         //let temp = self.taskArray.object(at: row) as! NSDictionary
         //let swifttemp = swiftArray[row] as [String:AnyObject]
         
         //let val:Int =   temp.value(forKey:"task") as! Int
         // print("task val: \(val)")
         //return (val + 1)%2
         //return (self.taskArray.object(at: row)as! NSDictionary)["task"]
         return swiftArray[row]["on"]
      }
      else if (tableColumn?.identifier == "description")
      {
         
         //  return (self.taskArray.object(at: row)as! NSDictionary)["description"]
         return swiftArray[row]["description"]
      }
      else if (tableColumn?.identifier == "bereich")
      {
         
         //return (self.taskArray.object(at: row)as! NSDictionary)["util"]
         return swiftArray[row]["bereich"]
      }
      else if (tableColumn?.identifier == "A0")
      {
         let wahlzelle = tableColumn?.dataCell(forRow: row) as? NSPopUpButtonCell
         let auswahl = wahlzelle?.indexOfSelectedItem
         
         //print("task wahl: auswahl: \(auswahl) items: \(wahlzelle?.itemTitles)")
         return auswahl
         // dfghjkly<xcvbnm,asdfghjksdfghjasf<yxcvbnmxxxxxxsxdcfghj
      }
      
      return "***"
   }
   
   public func tableView(tableView: NSTableView, willDisplayCell cell: NSCell, forRowAtIndexPath indexPath: NSIndexPath)
   {
      print("willDisplayCell pfad \(indexPath) ")
      if let myCell = cell as? NSPopUpButtonCell
      {
         
         print("willDisplayCell pfad \(indexPath) items: \(myCell.itemArray) \n \(myCell.itemTitles)")
         //perform your code to cell
      }
   }
   
   func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool
   {
      // OK
      let listeident = tableView.identifier
      if (listeident == "taskliste")
      {
         //print ("taskliste shouldSelectRow row: \(row) ")
      }
      else if (listeident == "testliste")
      {
         print ("testliste shouldSelectRow row: \(row) ")
      }
      
      return true
   }
   
   private func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int)
   {
      let listeident = tableView.identifier
      if (listeident == "device")
      {
         let ident = tableColumn?.identifier
         self.swiftArray[row][ident!] = object as! String
         //      (self.swiftArray[row] as! NSMutableDictionary).setObject(object!, forKey: (tableColumn?.identifier)! as NSCopying)
      }
   }
   
   // http://stackoverflow.com/questions/36365242/cocoa-nspopupbuttoncell-not-displaying-selected-value
   
   func numberOfRowsInTableView(tableView: NSTableView) -> Int
   {
      let listeident = tableView.identifier
      print("numberOfRowsInTableView ident: \(String(describing: listeident))")
      if (listeident == "device")
      {
         return self.swiftArray.count
      }
      return 0
   }
   
   /*
   func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject?
   {
      let listeident = tableView.identifier
      print("objectValueFor^TableColumn ident: \(listeident)")
      if (listeident == "device")
      {
         
         let zeile = swiftArray[row]
         print("objectValueForTableColumn zeile: \(zeile["device"])")
         if tableColumn!.identifier == "description"
         {
            print("objectValueForTableColumn util: \(description)")
            return zeile["description"] as AnyObject
         }
         else if tableColumn!.identifier == "wahl"
         {
            print("taskArray objectValueForTableColumn wahl: \(zeile["wahl"])")
            
            let wahlzelle = tableColumn?.dataCell(forRow: row) as? NSPopUpButtonCell
            
            return zeile["wahl"] as AnyObject
            
            // let zelle = tableView (_, dataCellFor: tableColumn?, row: row)
            
            // return swiftArray.availableResolutions.indexOf(display.resolution)
         }
      }
         
      else if (listeident == "testliste")
      {
         let zeile = testArray[row]
         print("testArray objectValueForTableColumn zeile: \(zeile["util"])")
         
      }
 
      return nil
   }
  */
   /*
    func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int)
    {
    let display = swiftArray[row]
    if tableColumn!.identifier == "wahl"
    {
    display.name = object as! String
    }
    else if tableColumn!.identifier == "resolutionCell" {
    display.resolution = display.availableResolutions[object as! Int]
    }
    }
    */
   /*
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell?
    {
    if let cell = tableColumn?.dataCell(forRow: row) as? NSCell
    {
    let listeident = tableView.identifier
    //print("dataCellFor ident: \(listeident)")
    if (listeident == "taskliste")
    {
    
    if tableColumn!.identifier == "wahl"
    {
    if let popupButtonCell = cell as? NSPopUpButtonCell
    {
    
    
    popupButtonCell.removeAllItems()
    popupButtonCell.addItems(withTitles:["Temperatur","Strom","Spannung"])
    popupButtonCell.synchronizeTitleAndSelectedItem()
    
    }
    }
    }
    else if (listeident == "testliste")
    {
    if tableColumn!.identifier == "taskwahl"
    {
    //print("dataCellFor taskwahl")
    let wahlzelle = tableColumn?.dataCell(forRow:row)as! NSPopUpButtonCell
    print("items: \(wahlzelle.itemTitles)")
    return wahlzelle
    
    if let popupButtonCell = cell as? NSPopUpButtonCell
    {
    
    // popupButtonCell.removeAllItems()
    popupButtonCell.addItems(withTitles:["aaa","bbb","ccc"])
    let sel:Selector = #selector(DataViewController.tuWasA(_:))
    popupButtonCell.action = sel
    popupButtonCell.synchronizeTitleAndSelectedItem()
    
    }
    
    }
    else if tableColumn!.identifier == "taskcheck"
    {
    print("dataCellFor taskcheck")
    let wahlzelle = tableColumn?.dataCell(forRow:row)as! NSButtonCell
    if row < testArray.count
    {
    let listezeile = testArray[row]
    print("dataCellFor taskcheck row \(row): listezeile: \(listezeile)")
    }
    if wahlzelle.state == 1
    {
    print("state 1")
    wahlzelle.state = 0
    }
    else
    {
    print("state 0")
    wahlzelle.state = 1
    }
    return wahlzelle
    
    }
    
    }
    return cell
    }
    return nil
    }
    */
   /*
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell?
    {
    
    
    //print ("dataCellForTableColumn  row: \(row) ")
    if tableColumn == nil
    {
    //print ("nil")
    return nil
    }
    let ident:String = tableColumn!.identifier
    
    if tableColumn!.identifier != "wahl"
    {
    
    return nil
    }
    
    let cell = NSPopUpButtonCell()
    cell.isBordered = false
    
    cell.menu!.addItem(withTitle: "Temperatur", action: nil, keyEquivalent: "")
    cell.menu!.addItem(withTitle: "Spannung", action: nil, keyEquivalent: "")
    cell.menu!.addItem(withTitle: "ON-OFF", action: nil, keyEquivalent: "")
    cell.selectItem(at: 1) // <--- obviously ignored ?!
    
    let selektion = cell.indexOfSelectedItem
    //print("selektion: \(selektion)")
    
    if (cell.menu!.title == "Temperatur")
    {
    print("Temperatur")
    }
    
    return cell
    }
    */
   // numberOfRowsInTableView: and tableView:objectValueForTableColumn:row:
   
   
   /*
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
    
    let result  = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) //as! BPTableCell
    
    //result.itemField.stringValue = items[row]
    //result.itemLabel.stringValue = labels[row]
    
    return result
    }
    */
   
   func tuWasA(_ sender: NSMenuItem)
   {
      print("tuWasA")
   }
   
   func tuWasB(_ sender: NSMenuItem)
   {
      print("tuWasB")
   }
   
}


extension NSTextView {
   func appendText(line: String) {
         let attrDict = [NSFontAttributeName: NSFont.systemFont(ofSize: 10.0)]
         let astring = NSAttributedString(string: "\(line)\n", attributes: attrDict)
         self.textStorage?.append(astring)
         let loc = self.string?.lengthOfBytes(using: String.Encoding.utf8)
         
         let range = NSRange(location: loc!, length: 0)
         self.scrollRangeToVisible(range)
      
   }
}


extension DataViewController:NSTableViewDataSource, NSTableViewDelegate
{
   func numberOfRows(in tableView: NSTableView) -> Int {
      return swiftArray.count
   }
   
   
   func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
   {
      
      let ident = tableColumn?.identifier
      //print ("viewFor row: \(row) ident: \(ident)")
      if tableColumn?.identifier == "imageIcon"
      {
         let result = tableView.make(withIdentifier: "imageIcon", owner: self) as! NSTableCellView
         result.imageView?.image = NSImage(named:swiftArray[row]["imageIcon"]!)
         return result
      }
      else if tableColumn?.identifier == "jobTitle"
      {
         let result:NSPopUpButton = tableView.make(withIdentifier: "jobTitle", owner: self) as! NSPopUpButton
         result.selectItem(withTitle: swiftArray[row]["jobTitle"]! )
         return result
      }
      else if  tableColumn?.identifier == "on"
      {
         let result = tableView.make(withIdentifier:(tableColumn?.identifier)!, owner: self) as! NSTableCellView
         let wert = swiftArray[row][(tableColumn?.identifier)!]
         //print("check value: \(wert)")
         let sub = result.subviews
         
 //        print("check element on sub: \(sub)")
         //var checkbox:NSButton = result.objectValue as! NSButton
         let element = result.subviews[0]
//         print("check element on: \(element)")
         let knopf = element as! NSButton
         knopf.toolTip = "aktiv"
         knopf.tag = 1000 + row
         let status = Int(knopf.state)
         let sollstatus = (swiftArray[row][(tableColumn?.identifier)!]! )
         let soll = Int(sollstatus)//.integerValue
         //knopf.state = 0
         knopf.state = soll!
 //        print("check tag: \(knopf.tag) status: \(status)")
         return result
         
      }
 /*
      else if  tableColumn?.identifier == "A0"
      {
         let result = tableView.make(withIdentifier:(tableColumn?.identifier)!, owner: self) as! NSTableCellView
         let wert = swiftArray[row][(tableColumn?.identifier)!]
         //print("check value: \(wert)")
         let sub = result.subviews
         
         //var checkbox:NSButton = result.objectValue as! NSButton
         let element = result.subviews[0]
//         print("check element A0: \(element)")
         let knopf = element as! NSButton
         knopf.tag = 1100 + row
         let status = Int(knopf.state)
         let sollstatus = (swiftArray[row][(tableColumn?.identifier)!]! )
         //let sollstatusint = (sollstatus as! Int)
         let soll = sollstatus.integerValue
         knopf.state = soll!
//         print("A0 tag: \(knopf.tag) status: \(status)")
         return result
         
      }

      else if  tableColumn?.identifier == "A1"
      {
         let result = tableView.make(withIdentifier:(tableColumn?.identifier)!, owner: self) as! NSTableCellView
         let wert = swiftArray[row][(tableColumn?.identifier)!]
         //print("check value: \(wert)")
         let sub = result.subviews
         
         //var checkbox:NSButton = result.objectValue as! NSButton
         let element = result.subviews[0]
//         print("check element A0: \(element)")
         let knopf = element as! NSButton
         knopf.tag = 1200 + row
         let status = Int(knopf.state)
         let sollstatus = (swiftArray[row][(tableColumn?.identifier)!]! )
         //let sollstatusint = (sollstatus as! Int)
         let soll = sollstatus.integerValue
         knopf.state = soll!
//         print("A1 tag: \(knopf.tag) status: \(status)")
         return result
         
      }
*/
      else if  tableColumn?.identifier == "A" // SegmentedControl
      {
         let result = tableView.make(withIdentifier:(tableColumn?.identifier)!, owner: self) as! NSTableCellView
         let wert = (swiftArray[row][(tableColumn?.identifier)!])
    //     print("A value: \(wert)")
         let sub = result.subviews
         
         let element = result.subviews[0]
         //         print("check element A0: \(element)")
         let knopf = element as! NSSegmentedControl
         
         //knopf.toolTip = "Kanal waehlen"
         let titelarray = swiftArray[row]["analogAtitel"]?.components(separatedBy: "\t")
         //titelarray = titelarray?[0]
         knopf.tag = 1500 + row
         let anz = Int(knopf.segmentCount)
         // https://stackoverflow.com/questions/38369544/how-to-convert-anyobject-type-to-int-in-swift
         let code = Int(wert!)
         let selectcode = UInt8(wert!)
         
         for pos in 0..<anz
         {
            if ((titelarray) != nil)
            {
            knopf.setLabel((titelarray?[pos])!, forSegment: pos)
            }
            let temp = UInt8(pos)
            if ((selectcode! & (1<<temp)) > 0)
            {
               knopf.setSelected(true, forSegment: pos)
            }
            else
            {
               knopf.setSelected(false, forSegment: pos)
            }
         }
        
         //let sollstatus = (swiftArray[row][(tableColumn?.identifier)!]! )
         //let sollstatusint = (sollstatus as! Int)
         //let soll = sollstatus.integerValue
         //knopf.state = soll!
         //         print("A1 tag: \(knopf.tag) status: \(status)")
         return result
         
      }
          else if  tableColumn?.identifier == "bereich" // PopUpButton
      {
         let result = tableView.make(withIdentifier:(tableColumn?.identifier)!, owner: self) as! NSTableCellView
         //print("bereich")
         let sub = result.subviews
         
         let element = result.subviews[0]
         //         print("check element A0: \(element)")
         let knopf = element as! NSPopUpButton
         let knopftag = knopf.tag
         knopf.toolTip = "Bereich waehlen"
         //print("knopftag: \(knopftag)")
         //let result:NSPopUpButton = tableView.make(withIdentifier: "bereich", owner: self) as! NSPopUpButton
         let titlestring = swiftArray[row][(tableColumn?.identifier)!]
         let titles:[String] = titlestring!.components(separatedBy: "\t")
        // let titles:[String] = swiftArray[row][(tableColumn?.identifier)!]! as! Array
         
         knopf.removeAllItems()
         knopf.addItems(withTitles: titles)
         var zeilenindex = 0
         for _ in titles
         {
            //print("zeilenindex: \(zeilenindex) zeile: \(zeile)")
            knopf.item(at: zeilenindex)?.tag = knopftag * 10 + 10 * row + zeilenindex
            zeilenindex += 1
         }
         let bereichwahl = Int(swiftArray[row]["bereichwahl"]!)
         
         knopf.selectItem(at: bereichwahl!)
         return result

      }

      else if  tableColumn?.identifier == "scale" // PopUpButton
      {
         let result = tableView.make(withIdentifier:(tableColumn?.identifier)!, owner: self) as! NSTableCellView
         //print("scale")
         return result
      }

      else if  tableColumn?.identifier == "temperatur" // TextField
      {
         let result = tableView.make(withIdentifier:(tableColumn?.identifier)!, owner: self) as! NSTableCellView
         let element = result.subviews[0]
         //         print("check element A0: \(element)")
         let feld = element as! NSTextField
         let wertstring = swiftArray[row][(tableColumn?.identifier)!]
         feld.stringValue = wertstring!
         //print("temperatur")
         
         
         return result
      }

      else if  tableColumn?.identifier == "batterie" // TextField
      {
         let result = tableView.make(withIdentifier:(tableColumn?.identifier)!, owner: self) as! NSTableCellView
         let element = result.subviews[0]
         //         print("check element A0: \(element)")
         let feld = element as! NSTextField
         let wertstring = swiftArray[row][(tableColumn?.identifier)!]
         feld.stringValue = wertstring!
         //print("batterie")
         return result
      }

      else
      {
         
         let result = tableView.make(withIdentifier:(tableColumn?.identifier)!, owner: self) as! NSTableCellView
         
         result.textField?.stringValue = swiftArray[row][(tableColumn?.identifier)!]!// as! String
         return result
         
      }
   }}


extension DataViewController 
{
   
   // MARK: - Preferences
   // https://www.raywenderlich.com/151748/macos-development-beginners-part-3
   func setupPrefs() 
   {
      //updateDisplay(for: prefs.selectedTime)
      
      let notificationName = Notification.Name(rawValue: "PrefsChanged")
      NotificationCenter.default.addObserver(forName: notificationName,
                                             object: nil, queue: nil) {
                                                (notification) in
                                                self.updateFromPrefs()
      }
   }
   
   func updateFromPrefs() 
   {
   //   self.eggTimer.duration = self.prefs.selectedTime
    //  self.resetButtonClicked(self)
   }
   
}
