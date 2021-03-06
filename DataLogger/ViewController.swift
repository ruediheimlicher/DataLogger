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

// ADC
//let  ADC0LO      =      16
//let  ADC0HI      =      17
// ADC 2
//let  ADC1LO      =       18
//let  ADC1HI      =       19

// neue defines
//Datenpaket USB:
//PACKET_SIZE 32 // Bytes

// teensy
//ADC

let DEVICE = 0

let CHANNEL = 2

let BATT   = 2


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

let MMCLO = 16
let MMCHI = 17


// Task
let WRITE_MMC_TEST  =   0xF1

// Bytes fuer Sicherungsort der Daten auf SD

let MESSUNG_START   =   0xC0 // Start der Messreihe
let MESSUNG_STOP   =   0xC1 // Start der Messreihe


let SAVE_SD_RUN = 0x02 // Bit 1
let SAVE_SD_STOP = 0x04 // Bit 2

let SAVE_SD_BYTE          =     1 //

let ABSCHNITT_BYTE   =     2 // Abschnitt auf SD

let BLOCKOFFSETLO_BYTE    =     3 // Block auf SD fuer Sicherung
let BLOCKOFFSETHI_BYTE    =     4

let BLOCK_ANZAHL_BYTE   = 9 // Anzahl zu lesende Blocks
let DOWNLOADBLOCKNUMMER_BYTE   =   10 // aktuelle nummer des downloadblocks
let PACKETCOUNT_BYTE = 8

let TAKT_LO_BYTE = 14
let TAKT_HI_BYTE = 15

let DATACOUNT_LO    =   12 // Messung, laufende Nummer
let DATACOUNT_HI    =   13

let STARTMINUTELO_BYTE = 5
let STARTMINUTEHI_BYTE = 6

let DATA_START_BYTE   = 16    // erstes byte fuer Data auf USB

let HEADER_SIZE = 16

let LOGGER_START     =     0xA0
let LOGGER_CONT      =     0xA1
let LOGGER_NEXT      =     0xA2 // next block

let LOGGER_STOP      =     0xAF

let LOGGER_SETTING    =  0xB0 // Setzen der Settings fuer die Messungen
let MESSUNG_DATA    =  0xB1 // Setzen der Settings fuer die Messungen

let USB_STOP    = 0xAA

let TEENSYVREF:Float = 249.0 // Korrektur von Vref des Teensy: nomineller Wert ist 256 2.56V

class DataViewController: NSViewController, NSWindowDelegate, AVAudioPlayerDelegate,NSMenuDelegate
{
   
   // Variablen
   var usbstatus: __uint8_t = 0
   
   var usb_read_cont = false; // kontinuierlich lesen
   var usb_write_cont = false; // kontinuierlich schreiben
   
   // Logger lesen
   var startblock:UInt16 = 1 // Byte 1,2: block 1 ist formatierung
   var blockcount:UInt16 = 0 // Byte 3, 4: counter beim Lesen von mehreren Bloecken
   
   var downloadblocknummer:UInt16 = 0 // Byte 3, 4: counter beim Lesen von mehreren Bloecken
   
   
   var packetcount :UInt8 = 0 // byte 5: counter fuer pakete beim Lesen eines Blocks 10 * 48 + 32
   
   var loggerDataArray:[[UInt8]] = [[]]
   var DiagrammDataArray:[[Float]] = [[]]
   
   var MessungStartzeit = 0
   
   var teensycode:UInt8 = 0
   
   var spistatus:UInt8 = 0;
   var DiagrammFeld:CGRect = CGRect.zero
   
   var taskArray :[[String:Any]] = [[String:Any]]()
   var anzahlChannels = 0
   var anzahlStoreChannels = 1
   var swiftArray = [[String:AnyObject]]()
   
   var testArray = [[String:AnyObject]]()
   
   var teensy = usb_teensy()
   
   var   adcfloatarray:[Float] = []
   
   //https://stackoverflow.com/questions/31736079/swift-associative-array-with-multiple-keysvalues
   struct dataelement
   {
      var channel:Int
      var data:Float
   }
   var datazeile = [Float](repeating:0.0, count:10)
   
   
   var analogfloatarray:[Float] = Array(Array(repeating:0.0,count:10))
   
   var devicefloatarray:[[Float]] = Array(repeating:Array(repeating:0.0,count:10),count:6)
   
   
   
   // Diagramm
   @IBOutlet  var datagraph: DataPlot!
   @IBOutlet  var dataScroller: NSScrollView!
   @IBOutlet  var dataAbszisse: Abszisse!
   
   
   @IBOutlet  var save_SD_check: NSButton!
   @IBOutlet  var Start_Messung: NSButton!
   
   @IBOutlet  var manufactorer: NSTextField!
   @IBOutlet  var Counter: NSTextField!
   
   @IBOutlet  var Start: NSButton!
   
   @IBOutlet  var MessungStartzeitFeld: NSTextField!
   
   @IBOutlet  var USB_OK: NSTextField!
   
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
   
   @IBOutlet  var TaskTab: NSTabView!
   
   @IBOutlet  var write_sd_startblock: NSTextField!
   @IBOutlet  var write_sd_anzahl: NSTextField!
   @IBOutlet  var read_sd_startblock: NSTextField!
   @IBOutlet  var read_sd_anzahl: NSTextField!
   
   @IBOutlet  var messungcounter: NSTextField!
   @IBOutlet  var blockcounter: NSTextField!
   //@IBOutlet  var read_sd_anzahl: NSTextField!
   
   @IBOutlet  var downloadDataFeld: NSTextView!
   
   
   @IBOutlet  var data2: NSTextField!
   @IBOutlet  var data3: NSTextField!
   
   
   @IBOutlet  var H_Feld: NSTextField!
   
   @IBOutlet  var L_Feld: NSTextField!
   
   @IBOutlet  var spannungsanzeige: NSSlider!
   @IBOutlet  var extspannungFeld: NSTextField!
   
   @IBOutlet  var spL: NSTextField!
   @IBOutlet  var spH: NSTextField!
   
   @IBOutlet  var extstrom: NSTextField!
   @IBOutlet  var Teensy_Status: NSButton!
   
   
   @IBOutlet  var extspannungStepper: NSStepper!
   
   
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
   
   
   @IBOutlet  var DSLO_Feld: NSTextField!
   @IBOutlet  var DSHI_Feld: NSTextField!
   @IBOutlet  var DSTempFeld: NSTextField!
   
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
   @IBOutlet  var bit0_check: NSButton!
   @IBOutlet  var bit1_check: NSButton!
   @IBOutlet  var bit2_check: NSButton!
   @IBOutlet  var bit3_check: NSButton!
   @IBOutlet  var bit4_check: NSButton!
   @IBOutlet  var bit5_check: NSButton!
   @IBOutlet  var bit6_check: NSButton!
   @IBOutlet  var bit7_check: NSButton!
   
   // mmc
   @IBOutlet  var mmcLOFeld: NSTextField!
   @IBOutlet  var mmcHIFeld: NSTextField!
   @IBOutlet  var mmcDataFeld: NSTextField!
   
   // Task
   @IBOutlet  var Task_0: NSPopUpButton!
   @IBOutlet  var Task_1: NSPopUpButton!
   @IBOutlet  var Task_2: NSPopUpButton!
   @IBOutlet  var Task_3: NSPopUpButton!
   
   @IBOutlet  var Task_0_Check: NSButton!
   @IBOutlet  var Task_1_Check: NSButton!
   @IBOutlet  var Task_2_Check: NSButton!
   @IBOutlet  var Task_3_Check: NSButton!
   
   
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
         
         
         print ("datapfad: \(datapfad)")
         
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
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "gsw-CH")
      
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      let sekunde = calendar.component(.second, from: date)
      formatter.dateFormat = "hh:mm:ss"
      let zeitString = formatter.string(from: date)
      return zeitString
   }
   
   func datumprefix()->String
   {
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "gsw-CH")
      
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
   
   func MessungDataString(data:[[Float]])-> String
   {
      var datastring:String = ""
      var datastringarray:[String] = []
      //      print("setMessungData: \(data)")
      
      for index in 0..<data.count
      {
         let tempzeilenarray:[Float] = data[index]
         if (tempzeilenarray.count > 0)
         {
            
            let tempzeilenstring = tempzeilenarray.map{String($0)}.joined(separator: "\t")
            datastringarray.append(tempzeilenstring)
            datastring = datastring +  "\n" + tempzeilenstring
         }
      }
      let prefix = datumprefix()
      let dataname = prefix + "_messungdump.txt"
      
      //      writeData(name: dataname,data:datastring)
      
      
      return datastring
   }
   

   @IBAction func myPopUpButtonWasSelected(sender:AnyObject)
   {
      
      print("myPopUpButtonWasSelected")
      // if let menuItem = sender as? NSMenuItem, mindex = find(allTheThings, menuItem.title) {
      //     sendThatIndexIntoTheWorld(mindex)
      //  }
   }
   
   
   //MARK: - viewDidLoad
   override func viewDidLoad()
   {
      super.viewDidLoad()
      
      // Notific einrichten
      //      NotificationCenter.default.addObserver(self, selector: #selector(DataViewController.USBfertigAktion(_:)), name: NSNotification.Name(rawValue: "NSWindowWillCloseNotification"), object: nil)
      
      // http://dev.iachieved.it/iachievedit/notifications-and-userinfo-with-swift-3-0/
      
      let nc = NotificationCenter.default //
      
      nc.addObserver(forName:Notification.Name(rawValue:"NSWindowWillCloseNotification"),// Name im Aufruf in usb.swift
         object:nil, queue:nil,
         using:USBfertigAktion)
      
      
      nc.addObserver(forName:Notification.Name(rawValue:"newdata"),// Name im Aufruf in usb.swift
         object:nil, queue:nil,
         using:newLoggerDataAktion)
      
      
      USB_OK.textColor = NSColor.red
      USB_OK.stringValue = "?";
      
      //MARK: -   TaskListe
      
       TaskListe.delegate = self
       TaskListe.dataSource = self
       TaskListe.target = self
      
      IntervallPop.selectItem(at:0)
      
      var tempDic = [String:AnyObject]()
      
      tempDic["on"] = 1  as AnyObject?

      tempDic["device"] = "Temperatur"  as AnyObject?
      tempDic["description"] = "Temperatur messen"  as AnyObject?
      tempDic["bereich"] = "T < 100°C"  as AnyObject?
      tempDic["A0"] = 0  as AnyObject?
      tempDic["A1"] = 1  as AnyObject?

      swiftArray.append(tempDic)

      tempDic["on"] = 0  as AnyObject?
      tempDic["device"] = "ADC 12Bit"  as AnyObject?
      tempDic["description"] = "Spannung messen"  as AnyObject?
      tempDic["bereich"] = "0-8V"  as AnyObject?
      tempDic["A0"] = 1  as AnyObject?
      tempDic["A1"] = 1  as AnyObject?
      swiftArray.append(tempDic)

  
      //MARK: -   datagraph
      var data = datadiagramm.init(nibName: "Datadiagramm", bundle: nil)
      self.datagraph.wantsLayer = true
      
      //self.datagraph.layer?.backgroundColor = CGColor.black
      self.datagraph.setDatafarbe(farbe:NSColor.red, index:0)
      
      let abszissebgfarbe:NSColor  = NSColor(red: (0.0), green: (0.0), blue: (0.0), alpha: 0.0)
      
      self.dataAbszisse.backgroundColor_n(color:abszissebgfarbe)
      self.dataAbszisse.setDiagrammFeldHeight(h: self.datagraph.DiagrammFeldHeight())
      
      
      var tasklist:[String] = ["Temperatur","ADC12Bit","Aux"]
      
      var kanaldic:[String:Any] = [:]
      
      
      Task_0.removeAllItems()
      Task_0.addItems(withTitles: tasklist)
      Task_0.action = #selector(reportWahlPop(_:))
      Task_0.target = self
      
      
      Task_1.removeAllItems()
      Task_1.addItems(withTitles: tasklist)
      Task_1.action = #selector(reportWahlPop(_:))
      
      Task_1.selectItem(at: 1)
      Task_1.target = self
      Task_2.removeAllItems()
      Task_2.addItems(withTitles: tasklist)
      Task_2.action = #selector(reportWahlPop(_:))
      Task_2.selectItem(at: 2)
      Task_2.target = self
      Task_3.removeAllItems()
      Task_3.addItems(withTitles: tasklist)
      Task_3.action = #selector(reportWahlPop(_:))
      Task_3.target = self
      Task_3.selectItem(at: 3)
      kanaldic["taskwahl"] = 0
      kanaldic["taskcheck"] = 0
      for _ in 0..<8
      {
         taskArray.append(kanaldic)
      }
      taskArray[0]["taskcheck"] = 1 // Ein kanal ist immer aktiviert
      
      taskArray[1]["taskcheck"] = 1 //
      
//      taskArray[2]["taskcheck"] = 1 //
      
//      taskArray[4]["taskcheck"] = 1 // 
      
      anzahlChannels = countChannels() // Anzahl aktivierte kanaele
      Channels_Feld.intValue  = Int32(anzahlChannels)
      
      adcfloatarray = [Float] ( repeating: 0.0, count: 8 )
      // var tempwerte = [Float] ( repeating: 0.0, count: 9 )
      
      
      
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
      //print("newLoggerDataAktion code: \(code) \(codestring)")
      for  index in 16..<38
      {
         
         //print("\(teensy.last_read_byteArray[index])", terminator: "\t")
      }
      //print("\n")
      
      
      switch (code)
      {
         // ****************************************************************************
         //MARK: LOGGER_SETTINGS
      // ****************************************************************************
      case LOGGER_SETTING:
         print("LOGGER_SETTINGS:")
         print("Nr: \(teensy.last_read_byteArray[DATACOUNT_LO]) \(teensy.last_read_byteArray[DATACOUNT_HI]) ")
         
         // ****************************************************************************
         //MARK: LOGGER_START
      // ****************************************************************************
      case LOGGER_START: // Antwort auf LOGGER_START, Block geladen, Header des Blocks lesen
         
         print("\n*** newLoggerDataAktion logger start: \(code) startblock: \(startblock)")
         
         // ladefehler
         let readerr: UInt8 = teensy.last_read_byteArray[1] // eventueller fehler ist im Byte 1
         
         if (readerr == 0)
         {
            //print("newLoggerDataAktion LOGGER_START: OK")
            print("newLoggerDataAktion LOGGER_START  readerr: \(readerr)*\nraw data:\n\(teensy.last_read_byteArray)\n")
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
         //print("newLoggerDataAktion logger cont: \(code)")
         let packetcount: UInt8 = teensy.last_read_byteArray[PACKETCOUNT_BYTE]
         //print("\nnewLoggerDataAktion LOGGER_CONT: \(code)\n teensy.last_read_byteArray: \(teensy.last_read_byteArray)")
         
         // gelesene Daten
         
         if (teensy.last_read_byteArray.count > 1)
         {
            print("\nnewLoggerDataAktion LOGGER_CONT: \(code)\n teensy.last_read_byteArray: \(teensy.last_read_byteArray)")
            
            // http://stackoverflow.com/questions/25581324/swift-how-can-string-join-work-custom-types
            var temparray = teensy.last_read_byteArray[DATA_START_BYTE...(BUFFER_SIZE-1)] // Teilarray mit Daten
            let anz = temparray.count
            
            print("\nnewLoggerDataAktion LOGGER_CONT: \(code)\n temparray: \(temparray)")
            
            var index = 0
            // hi und lo zusammenfuegen, neu speichern in newzeilenarray
            var newzeilenarray:[UInt16]! = []
            while (index < temparray.count / 2) // index in temparray ist gleich wie im originalarray
            {
               
               let a:UInt16 = UInt16(teensy.read_byteArray[DATA_START_BYTE + 2 * index])
               let b:UInt16 = UInt16(teensy.read_byteArray[DATA_START_BYTE + 2 * index + 1])
               
               var tempwert:UInt16 = a | (b << 8)
               // tempwert = a + b * 0xff
               //print("*\(a) \(b) \(tempwert)")
               newzeilenarray.append(tempwert)
               index = index + 1
               if ((index > 0) && (index%8 == 0)) // neue zeile im String nach 16 Daten (8 werte)
               {
                  //   print ("\nindex: \(index) newzeilenarray: \n\(newzeilenarray)")
                  let tempstring = newzeilenarray.map{String($0)}.joined(separator: "\t")
                  print ("index: \(index)\t\(tempstring)")
                  inputDataFeld.string = inputDataFeld.string! + "\n" + tempstring
                  newzeilenarray.removeAll(keepingCapacity: true)
               }
               
               // hi und lo zusammenfuehren
               //         index += 1
            }
            //          print ("\nnewzeilenarray: \n\(newzeilenarray)")
            // http://useyourloaf.com/blog/swift-guide-to-map-filter-reduce/
            
            //            let tempstring = newzeilenarray.map{String($0)}.joined(separator: "\t")
            
            
            //var tempstring = teensy.last_read_byteArray.map{Strng($0)}.joined(separator: ",")
            
            // http://stackoverflow.com/questions/36076014/uint8-array-to-strings-in-swift
            //    let stringArray = teensy.last_read_byteArray.map( { "\($0)" })
            //     print(stringArray)
            // let tempstring = String(bytes: teensy.last_read_byteArray, encoding: String.Encoding.utf8)
            
            //           inputDataFeld.string = inputDataFeld.string! + "\n" + tempstring
         }
         
         //print("LOGGER_CONT teensy.last_read_byteArray packetcount: \(packetcount)\n\(teensy.last_read_byteArray)\nend\n")
         
         
         // print("\(teensy.last_read_byteArray)")
         loggerDataArray.append(teensy.last_read_byteArray);
         
         if (packetcount < 10) // 480 bytes pro block
         {
            // Anfrage fuer naechstes Paket schicken
            //packetcount =   packetcount + 1
            cont_log_USB(paketcnt: (packetcount))
         }
         else
         {
            downloadblocknummer = downloadblocknummer + 1
            print("LOGGER_CONT startblock: \(startblock) downloadblocknummer: \(downloadblocknummer)")
            if (downloadblocknummer < blockcount) // noch weitere Blocks laden
            {
               //startblock -= 1
               
               print("LOGGER_CONT next downloadblocknummer: \(downloadblocknummer)")
               next_log_USB(downloadblocknummer: UInt16(downloadblocknummer))
               
            }
            else
            {
               // download beenden
               print("LOGGER_CONT write")
               
               teensy.read_OK = false
               teensy.write_byteArray[0] = UInt8(LOGGER_STOP)
               usb_read_cont = false
               cont_read_check.state = 0;
               let prefix = datumprefix()
               let dataname = prefix + "_loggerdump.txt"
               
               writeData(name: dataname,data:inputDataFeld.string!)
               
               print("\n")
               var senderfolg = teensy.start_write_USB()
               print("LOGGER_CONT senderfolg: \(senderfolg)")
            }
            
         }
         
         // ****************************************************************************
         //MARK: LOGGER_NEXT
         // ****************************************************************************
         
      case LOGGER_NEXT:
         print("\nLOGGER_NEXT") // analog LOGGER_START, Antwort vom Logger auf LOGGER_NEXT: next block ist geladen
         
         if (packetcount < 10) // 480 bytes pro block
         {
            
            // Anfrage fuer naechstes Paket schicken
            //packetcount =   packetcount + 1
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
               teensy.write_byteArray[0] = UInt8(LOGGER_STOP)
               usb_read_cont = false
               cont_read_check.state = 0;
               let prefix = datumprefix()
               let dataname = prefix + "_loggerdump.txt"
               
               writeData(name: dataname,data:inputDataFeld.string!)
               
               print("\n")
               var senderfolg = teensy.start_write_USB()
               print("LOGGER_NEXT senderfolg: \(senderfolg)")
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
         let dataname = prefix + "_loggerdump.txt"
         
         writeData(name: dataname,data:inputDataFeld.string!)
         
         print("\n")
         var senderfolg = teensy.start_write_USB()
         
         
         print("\nnewLoggerDataAktion LOGGER_Stop loggerDataArray:")
         // print ("loggerDataArray:\n\(loggerDataArray)")
         
         
         // ****************************************************************************
      // ****************************************************************************
      case WRITE_MMC_TEST:
         print("code ist WRITE_MMC_TEST")
         
         // ****************************************************************************
         // MARK: USB_STOP
         // ****************************************************************************
         
      case USB_STOP:
         print("code ist USB_STOP")
         
         // ****************************************************************************
         // MARK: MESSUNG_START
      // ****************************************************************************
      case MESSUNG_START:
         print("code ist MESSUNG_START")
         print("teensy.read_byteArray")
         print("\n\(teensy.read_byteArray)")
         blockcounter.intValue = 0
         
         // ****************************************************************************
         // MARK: MESSUNG_DATA
      // ****************************************************************************
      case MESSUNG_DATA: // wird gesetzt, wenn vom Teensy im Timertakt Daten gesendet werden
         //print("code ist MESSUNG_DATA")
         //        print("teensy.read_byteArray")
         //        print("\(teensy.last_read_byteArray)")
         let counterLO = Int32(teensy.read_byteArray[DATACOUNT_LO])
         let counterHI = Int32(teensy.read_byteArray[DATACOUNT_HI])
         
         let counter = (counterLO & 0x00FF) | ((counterHI & 0xFF00)>>8)
         //print("counter:\t\(counter)")
         Counter.intValue = counter
         
         messungcounter.intValue = counter
         
         
         
         let blockposition = (UInt32(teensy.read_byteArray[BLOCKOFFSETLO_BYTE]) & 0x00FF) | ((UInt32(teensy.read_byteArray[BLOCKOFFSETHI_BYTE])  & 0xFF00)>>8)
         
         blockcounter.intValue = Int32(blockposition)
         
         //print("ADC0LO: \(teensy.read_byteArray[ADC0LO]) ADC0HI: \(teensy.read_byteArray[ADC0HI])");
         
         // Device nummer lesen
         
         var tasknummer = Int32((teensy.read_byteArray[DEVICE + DATA_START_BYTE]))
         var channelnummer = Int32((teensy.read_byteArray[CHANNEL + DATA_START_BYTE]))
         
         print ("\ntasknummer: \(tasknummer)\tchannelnummer: \(channelnummer)")
         tasknummer &= 0x0F
         //print ("\ntasknummer B: \(tasknummer)")
         
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
         switch (tasknummer)
         {
         case 0:
            
            print ("switch keine tasknummer: \(tasknummer)")
            
         case 1:
            //print ("")
            print ("switch tasknummer: \(tasknummer)")
            //print("teensy.read_byteArray")
            
            for index in 16...33
            {
               
               print("\(teensy.last_read_byteArray[index])\t", terminator: "")
            }
            print ("")
            
            
            let analog0lo:Int32 =  Int32(teensy.read_byteArray[ANALOG0 + DATA_START_BYTE])
            let analog0hi:Int32 =  Int32(teensy.read_byteArray[ANALOG0+1 + DATA_START_BYTE])
            let analog0 = analog0lo | (analog0hi<<8)
            //print ("analog0lo: \(analog0lo) analog0hi: \(analog0hi)  analog0: \(analog0)");
            analog0float = Float(analog0) // * TEENSYVREF / 1024   // Kalibrierung teensy2: VREF ist 2.49 anstatt 2.56
            print ("task 1 analog0float: \(analog0float)");
            
            
            adcfloatarray[0]  = analog0float
            adcfloatarray[0]  = 0.0
            
            
            let analog1lo:Int32 =  Int32(teensy.read_byteArray[ANALOG1 + DATA_START_BYTE])
            let analog1hi:Int32 =  Int32(teensy.read_byteArray[ANALOG1+1 + DATA_START_BYTE])
            let analog1 = analog1lo | (analog1hi<<8)
            analog1float = Float(analog1) // * TEENSYVREF / 1024   // Kalibrierung teensy2: VREF ist 2.49 anstatt 2.56
            print ("task 1 analog1float: \(analog1float)");
            
            analog1float = floorf(fabs(analog1float)*2.f) / 2.f
            //print ("analog1float floor: \(analog1float)");
            adcfloatarray[1]  = analog1float
            //adcfloatarray[1]  = 0.0
            
            var adc1anzeige = Float(roundit(Double(analog1float), toNearest: 0.5))
            
//            ADC1Feld.stringValue = NSString(format:"%.01f", analog0float) as String
            
            // PT1000
            let analog2lo:Int32 =  Int32(teensy.read_byteArray[ANALOG2 + DATA_START_BYTE])
            let analog2hi:Int32 =  Int32(teensy.read_byteArray[ANALOG2+1 + DATA_START_BYTE])
            let analog2 = analog2lo | (analog2hi<<8)
            analog2float = Float(analog2)
            adcfloatarray[2]  = analog2float
            
            print("task 1 analog2float: \(analog2float) )");
            
            /*
             analog2float = analog2float * 2.56 / 1023
             print("analog2float B: \(analog2float) )");
             analog2float *= 20 // Anzeigewert anpassen
             
             print("analog2float C: \(analog2float) )");
             */
            
            let batteriespannung = Int32(teensy.read_byteArray[BATT + DATA_START_BYTE])
            batteriefloat = Float(batteriespannung)
            
            
            
            
            break
            
         case 2:
            //print ("")
            
            print ("switch tasknummer: \(tasknummer)")
            //print("task 2 teensy.read_byteArray")
            
            for index in 16...33
            {
               print("\(teensy.last_read_byteArray[index])\t", terminator: "")
            }
            print ("")
            
            let analog0lo:Int32 =  Int32(teensy.read_byteArray[ANALOG0 + DATA_START_BYTE])
            let analog0hi:Int32 =  Int32(teensy.read_byteArray[ANALOG0+1 + DATA_START_BYTE])
            let analog0 = analog0lo | (analog0hi<<8)
            //print ("analog0lo: \(analog0lo) analog0hi: \(analog0hi)  analog0: \(analog0)");
            analog0float = Float(analog0) // * TEENSYVREF / 1024   // Kalibrierung teensy2: VREF ist 2.49 anstatt 2.56
            print ("task 2 analog0float: \(analog0float)");
            
            adcfloatarray[4]  = analog0float/4
            
            let analog1lo:Int32 =  Int32(teensy.read_byteArray[ANALOG1 + DATA_START_BYTE])
            let analog1hi:Int32 =  Int32(teensy.read_byteArray[ANALOG1+1 + DATA_START_BYTE])
            let analog1 = analog1lo | (analog1hi<<8)
            analog1float = Float(analog1) // * TEENSYVREF / 1024   // Kalibrierung teensy2: VREF ist 2.49 anstatt 2.56
            print ("task 2 analog1float: \(analog1float)");
            
            analog1float = floorf(fabs(analog1float)*2.f) / 2.f
            //print ("analog1float floor: \(analog1float)");
            //           adcfloatarray[1]  = analog1float
            
            var adc1anzeige = Float(roundit(Double(analog1float), toNearest: 0.5))
            
//            ADC1Feld.stringValue = NSString(format:"%.01f", analog0float) as String
            
            
            let analog2lo:Int32 =  Int32(teensy.read_byteArray[ANALOG2 + DATA_START_BYTE])
            let analog2hi:Int32 =  Int32(teensy.read_byteArray[ANALOG2+1 + DATA_START_BYTE])
            let analog2 = analog2lo | (analog2hi<<8)
            analog2float = Float(analog2)
            //            adcfloatarray[2]  = analog2float
            
            print("task 2 analog2float: \(analog2float)");
            
            let analog3lo:Int32 =  Int32(teensy.read_byteArray[ANALOG3 + DATA_START_BYTE])
            let analog3hi:Int32 =  Int32(teensy.read_byteArray[ANALOG3+1 + DATA_START_BYTE])
            let analog3 = analog3lo | (analog3hi<<8)
            analog3float = Float(analog3)
            //            adcfloatarray[3]  = analog3float
            
            print("task 2 analog3float: \(analog3float) )");
            
            /*
             analog2float = analog2float * 2.56 / 1023
             print("analog2float B: \(analog2float) )");
             analog2float *= 20 // Anzeigewert anpassen
             
             print("analog2float C: \(analog2float) )");
             */
            
            let batteriespannung = Int32(teensy.read_byteArray[BATT + DATA_START_BYTE])
            batteriefloat = Float(batteriespannung)
            
            
         default:
            print ("")
            print ("---------------------")
            print ("")
            break
         }
         
         //        let analog0lo:Int32 =  Int32(teensy.read_byteArray[ANALOG0 + DATA_START_BYTE])
         //        let analog0hi:Int32 =  Int32(teensy.read_byteArray[ANALOG0+1 + DATA_START_BYTE])
         
         
         //     let analog0 = analog0lo | (analog0hi<<8)
         
         
         
         // print ("ADC0LO: \(ADC0LO) ADC0HI: \(ADC0HI)  adc0: \(adc0)");
         
         //print ("analog0: \(analog0)");
         //         ADC0LO_Feld.intValue = analog0lo
         //         ADC0HI_Feld.intValue = analog0hi
         
         
         // Temperatur
         
         
         //var  analog0float:Float = Float(analog0) // * TEENSYVREF / 1024   // Kalibrierung teensy2: VREF ist 2.49 anstatt 2.56
         //print ("analog0float: \(analog0float)");
         
         // let a0lo = String(format:"%2X", teensy.read_byteArray[ADC0LO + DATA_START_BYTE])
         //  let a0hi = String(format:"%2X", teensy.read_byteArray[ADC0HI + DATA_START_BYTE])
         
         
         //print("adc0lo: \(a0lo)) adc0hi: \(a0hi) adc0: \(adc0) adc0float: \(adc0float)");
         
         
         //adc0float = floorf(adc0float * Float(2.0)) / 2.0
         
         // analog0float = floorf(fabs(analog0float)*2.f) / 2.f
         
         //print ("analog0float 2: \(analog0float)");
         //var adc0anzeige = Float(roundit(Double(adc0float), toNearest: 0.5))
         
         
         //        adc0float /= 10.0
         
         // adcfloatarray[0]  = analog0float
         
         
         
         //adcfloatarray[0] = adc0anzeige
         
         //print("ADC1LO: \(teensy.read_byteArray[ADC1LO]) ADC1HI: \(teensy.read_byteArray[ADC1HI])");
         
         
         //        ADC1LO_Feld.intValue = Int32(teensy.read_byteArray[ANALOG1 + DATA_START_BYTE])
         //        ADC1HI_Feld.intValue = Int32(teensy.read_byteArray[ANALOG1+1 + DATA_START_BYTE])
         
         
         
         
         // print("counter: \(counter) adc2: \(adc2)");
         
         // print ("ADC02LO: \(ADC02LO) ADC02HI: \(ADC02HI)  adc2: \(adc2)");
         
         // print ("adc0: \(adc0)");
         
         // var  analog1float:Float = Float(analog1) // * TEENSYVREF / 1024   // Kalibrierung teensy2: VREF ist 2.49 anstatt 2.56
         //print ("adc1float: \(adc1float)");
         
         /*
          wert bei 20°: 190
          Diff zu 190 anzeigen, Offset 30
          */
         //        adc1float = (adc1float)/4.0
         
         // PT10000
         //adc1float -= 100
         //        var adc1anzeige = Float(roundit(Double(analog1float), toNearest: 0.5))
         
         
         //        analog1float = floorf(fabs(analog1float)*2.f) / 2.f
         
         // http://www.globalnerdy.com/2016/01/26/better-to-be-roughly-right-than-precisely-wrong-rounding-numbers-with-swift/
         
         
         //print("adc1: \t\(adc1) \t adc1float: \t\(adc1float) \t adc1anzeige: \t\(adc1anzeige) ");
         
         //        adcfloatarray[1] =  analog1float
         //       print("adc1float: \(analog1float) )");
         
         //
         //analog1float = analog1anzeige
         
         
         
         /*
          let analog2lo:Int32 =  Int32(teensy.read_byteArray[ANALOG2 + DATA_START_BYTE])
          let analog2hi:Int32 =  Int32(teensy.read_byteArray[ANALOG2+1 + DATA_START_BYTE])
          let analog2 = analog2lo | (analog2hi<<8)
          analog2float = Float(analog2)
          
          analog2float = analog2float * 2.56 / 1023
          
          analog2float *= 20 // Anzeigewert anpassen
          
          let tempbatteriespannung = Int32(teensy.read_byteArray[BATT + DATA_START_BYTE])
          analog2float = Float(tempbatteriespannung)
          
          print("analog2float: \(analog2float) )");
          
          adcfloatarray[2] =  analog2float
          
          //
          //print("adc1float: \(adc1float) )");
          */
         
         let NR_LO = Int32(teensy.read_byteArray[DATACOUNT_LO + DATA_START_BYTE])
         let NR_HI = Int32(teensy.read_byteArray[DATACOUNT_HI + DATA_START_BYTE])
         
         let messungnummer = NR_LO | (NR_HI<<8)
         
         let nrstring = String(messungnummer )
         _ = NumberFormatter()
         
         //print("messungnummer: \(messungnummer) adcfloat: \(adcfloat) String: \(adcfloat)");
         //        ADC1Feld.stringValue = NSString(format:"%.01f", analog0float) as String
         
         //loggerDataArray.append([UInt8(ADC0LO)]);
         var tempinputDataFeldstring = String(tagsekunde()-MessungStartzeit) + "\t" //+  ADC1Feld.stringValue
         
         
         //   let ADC1LO:Int32 =  Int32(teensy.read_byteArray[ADCLO+2])
         //   let ADC1HI:Int32 =  Int32(teensy.read_byteArray[ADCHI+2])
         //    let adc1 = ADC1LO | (ADC1HI<<8)
         let tempzeit = tagsekunde()
         let tempzeitfloat = Float(tempzeit)
         
         
         let diff = tempzeit - MessungStartzeit
         //print("MessungStartzeit: \(MessungStartzeit) tempzeitfloat: \(tempzeitfloat)  diff: \(diff)")
         
         
         let data0zeile:[Float] = [Float(tempzeit),Float(analog0float),Float(analog1float),Float(analog2float)]
         
         
         
         //   print ("datazeile \(data0zeile)\n")
         // datenzeile fuer Diagramm
         
         var tempwerte = [Float] ( repeating: 0.0, count: 9 )     // eine Zeile mit messung-zeit und 8 floats
         tempwerte[0] = Float(tempzeit) // Abszisse
         var kanalindex = 1    // index 0 ist abszisse (zeit)                                   // Index des zu speichernden Kanals
         
         // taskarray: array der 8 kanaele; aktivierte sind 1
         for storeindex in 0..<8
         {
            //print("storeindex: \(storeindex) taskArray: \(taskArray[storeindex])")
            if ((taskArray[storeindex]["taskcheck"] as! Int) > 0)    // der Kanal ist aktiviert
            {
               //print("kanalindex: \(kanalindex)")
               // wert des Kanal fortlaufend in tempwerte einsetzen:
               tempwerte[kanalindex] = Float(adcfloatarray[storeindex])
               
               //tempinputDataFeldstring = tempinputDataFeldstring + "\t" + ADC1Feld.stringValue
               
               // Zeile im Textfeld als string aufbauen
               tempinputDataFeldstring = tempinputDataFeldstring + "\t" + (NSString(format:"%.01f", adcfloatarray[storeindex]) as String)
               
               //    var devicefloatarray:[[Float]] = Array(repeating:Array(repeating:0.0,count:10),count:6)
               
               devicefloatarray[Int(tasknummer)] = tempwerte
               
               kanalindex = kanalindex + 1 // weiterschalten
            }
         }
         
         
         
         
         // Zeile in inputDataFeld laden
         inputDataFeld.string = inputDataFeld.string! + String(messungnummer) + "\t" +  tempinputDataFeldstring + "\n"
         
         
         
         
         //tempwerte[1] = Float(analog0float)
         //tempwerte[2] = Float(analog1float)
         
         //tempwerte[3] = Float(adcfloat + 10)
         
         //print("tempwerte: \(tempwerte)")
         DiagrammDataArray.append(tempwerte)
         
         //print("DiagrammDataArray: \(DiagrammDataArray)")
         
         // Daten einsetzen in graph
         self.datagraph.setWerteArray(werteArray:tempwerte)
         
         let PlatzRechts:Float = 20.0
         
         // breite des sichtbaren Bereichs
         let contentwidth = Float(self.dataScroller.contentView.bounds.size.width)
         
         // let lastdata = self.datagraph.DatenArray.last
         let lastxold = Float((self.datagraph.DatenArray.last?[0])!)
         let lastx = Float((self.datagraph.DatenDicArray.last?["x"])!)
         
         let maxx = NSMaxX((self.dataScroller.documentView?.frame)!)
         let maxwidth = NSWidth((self.dataScroller.documentView?.bounds)!)
         
         let currentScrollPosition = self.dataScroller.contentView.bounds.origin.x
         
         
         let newscrollorigin = NSMakePoint(currentScrollPosition - CGFloat(lastx),0.0)
         
         
         //// restore the scroll location
         // [[theScrollView documentView] scrollPoint:currentScrollPosition];
         
         //      self.dataScroller.documentView?.scroll(newscrollorigin)
         
         // http://stackoverflow.com/questions/9820669/i-dont-fully-understand-scrollrecttovisible-when-im-using-contentinset
         // https://developer.apple.com/reference/appkit/nsview/1483811-scrollrecttovisible?language=objc
         
         // http://stackoverflow.com/questions/35939381/programmatically-scroll-nsscrollview-to-the-right
         
         var scrollDelta = 10.0
         var rect:CGRect  = self.dataScroller.bounds;
         var scrollToRect:CGRect  = rect.offsetBy(dx: CGFloat(scrollDelta), dy: 0);
         
         //         self.dataScroller.documentView?.scrollToVisible(scrollToRect)
         
         
         //let lastx_n = Float((self.datagraph.DatenDicArray.last?["x"])!)
         // documentView: The view the scroll view scrolls within its content view
         
         // Nullpunkt des documentview
         let  docviewx = Float((self.dataScroller.documentView?.frame.origin.x)!)
         
         
         let aktuelledocpos = lastx + docviewx
         let grenze = (contentwidth / 10 * 8 ) + PlatzRechts
         
         //print(" docviewx:  \(docviewx)  aktuelledocpos: \(aktuelledocpos) grenze: \(grenze)")
         
         // print("\nmaxx: \(maxx) maxwidth: \(maxwidth) \tcurrentScrollPosition: \(currentScrollPosition)")
         if (counter == 0)
         {
            //            print("$$\tdocviewx:  \tlastx: \tdiff: \tcurrentScrollPosition:")
         }
         //         print("$$$\(counter)\t\(docviewx)\t\(lastx) \t\(docviewx)\t\(lastx + docviewx)\t\(currentScrollPosition)")
         
         
         if (((lastx) + docviewx ) > grenze) // docviewx ist negativ, wenn gegen links gescrollt wurde
         {
            let delta = contentwidth / 10 * 8
            
            print("lastdata zu gross \(lastx) delta:  \(delta)")
            self.dataScroller.documentView?.frame.origin.x -=   CGFloat(delta)
            self.dataScroller.contentView.needsDisplay = true
         }
         
         if (lastx > Float((self.dataScroller.documentView?.frame.size.width)! * 0.9))
         {
            // self.dataScroller.documentView?.frame.size.width += 1000
         }
         
         let batteriespannung = Int32(teensy.read_byteArray[BATT])
         //       print("batteriespannung: \(batteriespannung)")
         // end data
         
         // ****************************************************************************
         // ****************************************************************************
         
      default: break
         //print("code ist 0")
         
      } // switch code
      //return;
      
      var data = NSData(bytes: teensy.last_read_byteArray, length: 64)
      //print("data: \(data)")
      
      // let inputDataFeldstring = teensy.last_read_byteArray as NSArray
      
      let b1: Int32 = Int32(teensy.last_read_byteArray[1])
      let b2: Int32 = Int32(teensy.last_read_byteArray[2])
      
      //print("b1: \(b1)\tb2: \(b2)\n");
      
//      H_Feld.intValue = b2
//      H_Feld.stringValue = NSString(format:"%2X", b1) as String
      
      // H_Feld.stringValue = NSString(format:"%d", a2)
      
//      L_Feld.intValue = b1
//      L_Feld.stringValue = NSString(format:"%2X", b1) as String
      // L_Feld.stringValue = NSString(format:"%d", a1)
      
      let rotA:Int32 = (b1 | (b2<<8))
      
      spannungsanzeige.intValue = Int32(rotA )
      
      // DS18S20
      
      let DSLOW:Int16 = Int16(teensy.last_read_byteArray[DSLO])
      let DSHIGH:Int16 = Int16(teensy.last_read_byteArray[DSHI])
      
      if (DSLOW > 0)
      {
         let temperatur = DSLOW | (DSHIGH<<8)
         
         //print("DSLOW: \(DSLOW)\tSDHIGH: \(DSHIGH) temperatur: \(temperatur)\n");
         
//         DSLO_Feld.intValue = Int32(DSLOW)
//         DSHI_Feld.intValue = Int32(DSHIGH)
         
         let  temperaturfloat:Float = Float(temperatur)/10.0
         _ = NumberFormatter()
         
         let t:NSString = NSString(format:"%.01f", temperaturfloat) as String as String as NSString
         //print("temperaturfloat: \(temperaturfloat) String: \(t)");
         DSTempFeld.stringValue = NSString(format:"%.01f°C", temperaturfloat) as String
         //DSTempFeld.floatValue = temperaturfloat
      }
      
      // mmc
      let mmcLO:Int32 = Int32(teensy.last_read_byteArray[MMCLO])
      let mmcHI:Int32 = Int32(teensy.last_read_byteArray[MMCHI])
      let mmcData  = mmcLO | (mmcHI << 8)
      mmcLOFeld.intValue = mmcLO
      mmcHIFeld.intValue = mmcHI
      mmcDataFeld.intValue = mmcData
      teensy.new_Data = false
   }
   
   //MARK: -   Logger
   @IBAction func report_start_download_logger_USB(_ sender: AnyObject)
   {
      
      print("report_start_download_logger_USB");
      Stop_Logger.isEnabled = true
      zeit_Feld.stringValue = zeitstring()
      // tagmin_Feld.integerValue = tagminute
      tagsec_Feld.integerValue = tagsekunde()
      cont_read_check.state = 1
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
      
      teensy.write_byteArray[0] = UInt8(LOGGER_START)
      startblock = UInt16(read_sd_startblock.integerValue)
      
      // index erster Block
      
      // old
      //      teensy.write_byteArray[1] = UInt8(startblock & 0x00FF)
      //      teensy.write_byteArray[2] = UInt8((startblock & 0xFF00)>>8)
      
      teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // byte 3
      teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
      
      blockcount = UInt16(read_sd_anzahl.integerValue) // Anzahl zu lesende blocks
      teensy.write_byteArray[BLOCK_ANZAHL_BYTE] = UInt8(blockcount & 0x00FF) // byte 9
      
      downloadblocknummer = 0
      teensy.write_byteArray[DOWNLOADBLOCKNUMMER_BYTE] = UInt8(downloadblocknummer & 0x00FF)
      
      packetcount=0
      
      teensy.write_byteArray[PACKETCOUNT_BYTE] = packetcount // beginn bei Paket 0
      
      // cont write aktivieren
      cont_write_check.state = 1
      //print("\nreport start download: teensy.last_read_byteArray: \(teensy.last_read_byteArray)")
      
      var senderfolg = teensy.start_write_USB()
      //inputDataFeld.string = inputDataFeld.string! + "\nBlock: " + String(startblock) + "\n"
      inputDataFeld.string = "Block: " + String(startblock) + "\n"
      
   }
   
   //MARK: cont log
   func cont_log_USB(paketcnt: UInt8)
   {
      
      //print("cont_log_USB packetcount: \(paketcnt)");
      teensy.write_byteArray[0] = UInt8(LOGGER_CONT) // code
      teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF)
      teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
      
      teensy.write_byteArray[PACKETCOUNT_BYTE] = paketcnt // beginn bei Paket next
      
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
      
      var formatter = NumberFormatter()
      var tempspannung:Double  = extspannungFeld.doubleValue * 100
      if (tempspannung > 3000)
      {
         tempspannung = 3000
         
         
      }
      
      let tempPos = ServoASlider.intValue
      
      //      extspannungFeld.doubleValue = ((tempspannung/100)+1)%12
      //var tempintspannung = UInt16(tempspannung)
      //NSString(format:"%2X", a2)
      //spL.stringValue = NSString(format:"%02X", (tempintspannung & 0x00FF)) as String
      //spH.stringValue = NSString(format:"%02X", ((tempintspannung & 0xFF00)>>8)) as String
      print("tempPos: \(tempPos)");// L: \(spL.stringValue)\ttempintspannung H: \(spH.stringValue) ")
      //teensy.write_byteArray[0] = 0x01
      print("write_byteArray 0: \(teensy.write_byteArray[0])")
      teensy.write_byteArray[10] = UInt8(tempPos & (0x00FF))
      teensy.write_byteArray[11] = UInt8((tempPos & (0xFF00))>>8)
      print("write_byteArray 10: \(teensy.write_byteArray[10])\t 11: \(teensy.write_byteArray[11])")
      var senderfolg = teensy.start_write_USB()
      teensy.write_byteArray[0] = 0x00 // bit 0 zuruecksetzen
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
   
   
   func USBfertigAktion(notification:Notification) -> Void
   {
      //NSLog("USBfertigAktion will schliessen \(notification)")
      //& http://stackoverflow.com/questions/30027780/swift-accessing-appdelegate-window-from-viewcontroller
 //     let appDelegate = NSApplication.shared().delegate as? AppDelegate

      // https://stackoverflow.com/questions/43426391/how-do-you-reference-the-views-window-in-swift-3-x-using-storyboards-cocoa
      let hauptfenster:NSWindow = NSApplication.shared().mainWindow!
      let objektfenster :NSWindow = notification.object as! NSWindow
      if (hauptfenster == objektfenster)
      {
         print("hauptfenster")
         
         stop_read_USB(self)
         stop_write_USB(self)
         
         
         //teensycode &= ~(1<<7)
         //teensy.write_byteArray[15] = teensycode
         
         teensy.write_byteArray[0] = UInt8(USB_STOP)
         
         //         teensy.write_byteArray[1] = UInt8(data0.intValue)
         
         let senderfolg = teensy.start_write_USB()
         if (senderfolg > 0)
         {
            print("USBfertigAktion teensy schliessen OK")
         }
         else
         {
            print("USBfertigAktion teensy schliessen nicht OK")
            
            //return
         }
         NSApplication.shared().terminate(self)
         return
         
      }
      else
      {
         print("dialogfenster")
         return;
      }
   }
   
   @IBAction func check_USB(_ sender: NSButton)
   {
      let erfolg = UInt8(teensy.USBOpen())
      usbstatus = erfolg
      print("USBOpen erfolg: \(erfolg) usbstatus: \(usbstatus)")
      
      
      if (rawhid_status()==1)
      {
         // NSBeep()
         print("status 1")
         USB_OK.textColor = NSColor.green
         USB_OK.stringValue = "OK";
         manufactorer.stringValue = "Manufactorer: " + teensy.manufactorer()!
         
         Teensy_Status.isEnabled = true;
         start_read_USB_Knopf?.isEnabled = true;
         stop_read_USB_Knopf?.isEnabled = true;
         start_write_USB_Knopf?.isEnabled = true;
         stop_write_USB_Knopf?.isEnabled = true;
         NSSound(named: "Glass")?.play()
         
      }
      else
         
      {
         print("status 0")
         USB_OK.textColor = NSColor.red
         USB_OK.stringValue = "X";
         Teensy_Status?.isEnabled = false;
         start_read_USB_Knopf?.isEnabled = false;
         stop_read_USB_Knopf?.isEnabled = false;
         start_write_USB_Knopf?.isEnabled = false;
         stop_write_USB_Knopf?.isEnabled = false;
      }
      print("antwort: \(teensy.status())")
      
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
      USB_OK.stringValue = "?"
   }
   
   /*
   //MARK: - DeviceCollectionView
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
      teensy.write_byteArray[ABSCHNITT_BYTE] = 0
      
      // Zeitkompression setzen
      //let selectedKomp = ZeitkompressionPop.indexOfSelectedItem
      let kompressionwertwert = ZeitkompressionPop.intValue
      
      let kompvorgabe = ["zeitkompression":Float(kompressionwertwert)]
      datagraph.setVorgaben(vorgaben:kompvorgabe)
      
      //Angabe zum  Startblock lesen. default ist 0
      startblock = UInt16(write_sd_startblock.integerValue)
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
      }
   }
   
   @IBAction func reportCheckbox(sender:NSButton)
   {
      print("reportCheckbox \(sender.state) tag: \(sender.tag)")
      let knopftag = Int(sender.tag)
      let zeile = knopftag%1000
      print("reportCheckbox zeile: \(zeile)")
      
      let knopfstatus = (swiftArray[zeile]["check"]!).integerValue
      if (knopfstatus == 1)
      {
         swiftArray[zeile]["check"] = 0 as AnyObject
      }
      else{
         swiftArray[zeile]["check"] = 1 as AnyObject
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
      
      let knopfstatus = (swiftArray[zeile]["A0"]!).integerValue
      if (knopfstatus == 1)
      {
         swiftArray[zeile][key] = 0 as AnyObject
      }
      else{
         swiftArray[zeile][key] = 1 as AnyObject
      }
      
      print("tableViewData nach Kanalwahl:\n\(String(describing: swiftArray[zeile]["A0"]))")

   
   
   }
   
   @IBAction func reportWahlPop(_ sender: AnyObject)
   {
      print("reportWahlPop sender tag: \(sender.tag) ")
      let index = (sender.tag / 10) - 10
      let zeile = (sender as! NSPopUpButton).indexOfSelectedItem
      print("reportWahlPop sender zeile: \(zeile) ")
      
      taskArray[index]["taskwahl"] = zeile
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
   
   
   @IBAction func reportChannelPop(_ sender: AnyObject)
   {
      //print("reportChannelPop sender tag: \(sender.tag!) ")
      let index = (sender.tag / 10) - 10
      let zeile = (sender as! NSPopUpButton).indexOfSelectedItem
      let channeltag = ((sender as! NSPopUpButton).selectedItem?.tag)! - 400
      anzahlStoreChannels = channeltag
      print("reportChannelPop sender zeile: \(zeile) tag: \(channeltag)")
   }
   
   @IBAction func reportTaskCheck(_ sender: NSButton)
   {
      print("reportTaskCheck  sender tag: \(sender.tag) state: \(sender.state)")
      let index = (sender.tag / 10) - 20
      taskArray[index]["taskcheck"] = sender.state
      print("reportTaskCheck  taskArray: \n\(taskArray)")
      anzahlChannels = countChannels()
      Channels_Feld.intValue  = Int32(anzahlChannels)
      /*
       let zeile = TaskListe.selectedRow
       var zelle = swiftArray[TaskListe.selectedRow] //as! [String:AnyObject]
       print("reportTaskCheck zeile: \(zeile) zelle: \(zelle) task: \(zelle["task"])")
       
       // let check = zelle["task"] as! Int
       // if (check == 0)
       
       if (swiftArray[TaskListe.selectedRow]["task"] as! Int == 1)
       {
       swiftArray[TaskListe.selectedRow]["task"] = 0  as AnyObject?
       }
       else
       {
       //zelle["task"] = 0 as AnyObject?
       swiftArray[TaskListe.selectedRow]["task"] = 1  as AnyObject?
       }
       */
   }
   
   func countChannels() ->Int
   {
      var anzahl = 0
      for zeile in taskArray
      {
         let status = zeile["taskcheck"] as! Int
         if ((zeile["taskcheck"] as! Int) == 1)
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
      print("start_messung sender: \(sender.state)") // gibt neuen State an
      if (Channels_Feld.intValue == 0)
      {
         print("kein Kanal")
         return
      }
      if (sender.state == 1)
      {
         //print("start_messung start ")
         
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
         print("reportTaskIntervall wahl: \(wahl) index: \(index)")
         
         let integerwahl:UInt16? = UInt16(wahl)
         print("report_start_messung integerwahl: \(integerwahl!)")
         // Taktintervall in array einsetzen
         teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(integerwahl! & 0x00FF)
         teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((integerwahl! & 0xFF00)>>8)
         
         
         
         
         MessungStartzeitFeld.integerValue = tagsekunde()
         MessungStartzeit = tagsekunde()
         
         // code setzen
         teensy.write_byteArray[0] = UInt8(MESSUNG_START)
         
         // Sichern auf SD
         teensy.write_byteArray[1] = UInt8(SAVE_SD_RUN)
         
         // Abschnitt auf SD
         teensy.write_byteArray[ABSCHNITT_BYTE] = 0
         
         //Angabe zum  Startblock aktualisieren
         startblock = UInt16(write_sd_startblock.integerValue)
         
         teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
         teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
         
         //print("block lo: \(teensy.write_byteArray[BLOCKOFFSETLO_BYTE]) hi: \(teensy.write_byteArray[BLOCKOFFSETHI_BYTE])")
         
         
         let zeit = tagsekunde()
         print("start_messung startblock: \(startblock)  zeit: \(zeit)")
         
         let startminute = tagminute()
         teensy.write_byteArray[STARTMINUTELO_BYTE] = UInt8(startminute & 0x00FF)
         teensy.write_byteArray[STARTMINUTEHI_BYTE] = UInt8((startminute & 0xFF00)>>8)
         //        print("\nreport start messungT: teensy.last_read_byteArray: \(teensy.last_read_byteArray)")
         print("\nreport start messungT: teensy.write_byteArray: \(teensy.write_byteArray)")
         
         delayWithSeconds(1)
         {
            
            self.Counter.intValue = 0
            
            self.datagraph.initGraphArray()
            self.datagraph.setStartsekunde(startsekunde:self.tagsekunde())
            self.datagraph.setMaxY(maxY: 150)
            self.datagraph.setDisplayRect()
            
            self.usb_read_cont = (self.cont_read_check.state == 1) // cont_Read wird bei aktiviertem check eingeschaltet
            
            self.teensy.write_byteArray[0] = UInt8(MESSUNG_START)
            //Do something
            
            let readerr = self.teensy.start_read_USB(true)
            if (readerr == 0)
            {
               print("Fehler in report_start_messung")
            }
         }
         DiagrammDataArray.removeAll()
         inputDataFeld.string = "Messung tagsekunde: \(zeit)\n"
         
      }
      else
      {
         print("start_messung stop")
         teensy.write_byteArray[0] = UInt8(MESSUNG_STOP)
         teensy.write_byteArray[1] = UInt8(SAVE_SD_STOP)
         
         teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
         teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
         
         teensy.read_OK = false
         usb_read_cont = false
         cont_read_check.state = 0;
         
         //print("DiagrammDataArray: \(DiagrammDataArray)")
         
         var messungstring:String = MessungDataString(data:DiagrammDataArray)
         
         let prefix = datumprefix()
         let intervall = IntervallPop.integerValue
         //let startblock = write_sd_startblock.integerValue
         
         var kopfstring = prefix + "\n" + "startzeit\t\(MessungStartzeit)\tintervall\t\(intervall)\tstartblock\t\(startblock)\nKanäle: \t\(anzahlChannels)"
         
         messungstring = kopfstring + messungstring
         
         let dataname = prefix + "_messungdump.txt"
         
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
      }
      
      var senderfolg = teensy.start_write_USB()
      if (senderfolg > 0)
      {
         NSSound(named: "Glass")?.play()
      }
      
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
      print("report_start_read_USB")
      //myUSBController.startRead(1)
      
      usb_read_cont = (cont_read_check.state == 1) // cont_Read wird bei aktiviertem check eingeschaltet
      teensy.write_byteArray[0] = 0
      
      let readerr = teensy.start_read_USB(usb_read_cont)
      
      if (readerr == 0)
      {
         print("Fehler in start_read_usb")
      }
      
      let DSLOW:Int32 = Int32(teensy.read_byteArray[DSLO])
      let DSHIGH:Int32 = Int32(teensy.read_byteArray[DSHI])
      
      if (DSLOW > 0)
      {
         let temperatur = DSLOW | (DSHIGH<<8)
         
         print("DSLOW: \(DSLOW)\tSDHIGH: \(DSHIGH)\n");
         DSLO_Feld.intValue = DSLOW
         DSHI_Feld.intValue = DSHIGH
         let  temperaturfloat:Float = Float(temperatur)/10.0
         _ = NumberFormatter()
         
         let t:NSString = NSString(format:"%.01f", temperaturfloat) as String as String as NSString
         //print("temperaturfloat: \(temperaturfloat) String: \(t)");
         DSTempFeld.stringValue = NSString(format:"%.01f°C", temperaturfloat) as String
         //DSTempFeld.floatValue = temperaturfloat
      }
      self.datagraph.initGraphArray()
      self.datagraph.setStartsekunde(startsekunde:tagsekunde())
      self.datagraph.setMaxY(maxY: 180)
      self.datagraph.setDisplayRect()
      
      
      let analog0lo:Int32 =  Int32(teensy.read_byteArray[ANALOG0])
      let analog0hi:Int32 =  Int32(teensy.read_byteArray[ANALOG0+1])
      ADC0LO_Feld.intValue = analog0lo
      ADC0HI_Feld.intValue = analog0hi
      
      let analog0 = analog0lo | (analog0hi<<8)
      let  analog0float:Float = Float(analog0)/0xFFFF*5.0
      _ = NumberFormatter()
      
      //print("adcfloat: \(adcfloat) String: \(adcfloat)");
//      ADC1Feld.stringValue = NSString(format:"%.02f", analog0float) as String
      
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
               let loggerdataDicArray = datagraph.diagrammDataDicFromLoggerData(loggerdata: datastring)
               let loggerDataArray = datagraph.diagrammDataArrayFromLoggerData(loggerdata: datastring)
               
               print("reportOpenData loggerdataArray\n\(loggerDataArray)\n")
               self.datagraph.initGraphArray()
               //self.datagraph.setStartsekunde(startsekunde:self.tagsekunde())
               self.datagraph.setMaxY(maxY: 150)
               //     self.datagraph.setDisplayRect()
               
               var index = 0
               for zeile in loggerDataArray
               {
                  datagraph.setWerteArray(werteArray: zeile)
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
         self.swiftArray[row][ident!] = object
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
      else if (listeident == "testliste")
      {
         return self.testArray.count
      }
      return 0
   }
   
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
            return zeile["description"]
         }
         else if tableColumn!.identifier == "wahl"
         {
            print("taskArray objectValueForTableColumn wahl: \(zeile["wahl"])")
            
            let wahlzelle = tableColumn?.dataCell(forRow: row) as? NSPopUpButtonCell
            
            return zeile["wahl"]
            
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

extension DataViewController:NSTableViewDataSource, NSTableViewDelegate
{
   func numberOfRows(in tableView: NSTableView) -> Int {
      return swiftArray.count
   }
   
   
   func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
   {
      
      let ident = tableColumn?.identifier
//      print ("viewFor row: \(row) ident: \(ident)")
      if tableColumn?.identifier == "imageIcon"
      {
         let result = tableView.make(withIdentifier: "imageIcon", owner: self) as! NSTableCellView
         result.imageView?.image = NSImage(named:swiftArray[row]["imageIcon"]! as! String)
         return result
      }
      else if tableColumn?.identifier == "jobTitle"
      {
         let result:NSPopUpButton = tableView.make(withIdentifier: "jobTitle", owner: self) as! NSPopUpButton
         result.selectItem(withTitle: swiftArray[row]["jobTitle"] as! String)
         return result
      }
      else if  tableColumn?.identifier == "on"
      {
         let result = tableView.make(withIdentifier:(tableColumn?.identifier)!, owner: self) as! NSTableCellView
         let wert = swiftArray[row][(tableColumn?.identifier)!]
         //print("check value: \(wert)")
         let sub = result.subviews
         
         //var checkbox:NSButton = result.objectValue as! NSButton
         let element = result.subviews[0]
//         print("check element on: \(element)")
         let knopf = element as! NSButton
         knopf.tag = 1000 + row
         let status = Int(knopf.state)
         let sollstatus = (swiftArray[row][(tableColumn?.identifier)!]! )
         let soll = sollstatus.integerValue
         //knopf.state = 0
         knopf.state = soll!
 //        print("check tag: \(knopf.tag) status: \(status)")
         return result
         
      }
 
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

         
      else
      {
         let result = tableView.make(withIdentifier:(tableColumn?.identifier)!, owner: self) as! NSTableCellView
         
         result.textField?.stringValue = swiftArray[row][(tableColumn?.identifier)!]! as! String
         return result
         
      }
   }}
