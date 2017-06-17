//
//  abszisse.swift
//  DataLogger
//
//  Created by Ruedi Heimlicher on 17.06.2017.
//  Copyright © 2017 Ruedi Heimlicher. All rights reserved.
//

import Foundation
import AVFoundation
import Darwin
import AppKit
import Cocoa


class Abszisse: NSView
{
   var diagrammfeld:CGRect = CGRect.zero
   
   fileprivate struct   Geom
   {
      // Abstand von bounds
      static let randunten: CGFloat = 15.0
      static let randlinks: CGFloat = 0.0
      static let randoben: CGFloat = 10.0
      static let randrechts: CGFloat = 10.0
      // Abstand vom Feldrand
      static let offsetx: CGFloat = 0.0 // Offset des Nullpunkts
      static let offsety: CGFloat = 15.0
      static let freey: CGFloat = 20.0 // Freier Raum oben
      static let freex: CGFloat = 15.0 // Freier Raum rechts
      
   }
   
   
   fileprivate struct AbszisseVorgaben
   {
      static let legendebreite: CGFloat = 10.0
      static var exponent: Int = 1 // Zehnerpotenz fuer label
      static var MajorTeileY: Int = 8                           // Teile der Hauptskala
      static var MinorTeileY: Int = 2                             // Teile der Subskala
      static var MaxY: CGFloat = 160.0                            // Obere Grenze der Anzeige, muss zu MajorTeileY passen
      static var MinY: CGFloat = 0.0                              // Untere Grenze der Anzeige
      static var MaxX: CGFloat = 1000                             // Obere Grenze der Abszisse
      
      static var ZeitKompression: CGFloat = 1.0
      static var Startsekunde: Int = 0
      static let NullpunktY: CGFloat = 0.0
      static let NullpunktX: CGFloat = 0.0
      static let DiagrammEcke: CGPoint = CGPoint(x:15, y:10)// Ecke des Diagramms im View
      static let DiagrammeckeY: CGFloat = 0.0 //
      static let StartwertX: CGFloat = 0.0 // Abszisse des ersten Wertew
      
      static let rastervertikal = 2 // Sprung innerhalb MajorTeileY + MinorTeileY
      
   }
   
   
   required init(coder aDecoder: NSCoder)
   {
      //Swift.print("abszisse init coder")
      super.init(coder: aDecoder)!
      diagrammfeld = AbszisseRect(rect:self.bounds)
      //diagrammfeld = PlotRect()
   }
   
   func PlotRect() -> CGRect
   {
      Swift.print("abszisse PlotRect bounds: \(bounds)")
      let breite = bounds.size.width // -  Geom.randlinks - Geom.randrechts
      let hoehe = bounds.size.height - Geom.randoben - Geom.randunten
      let rect = CGRect(x:0 ,
                        y: Geom.randunten ,
                        width: breite, height: hoehe)
      Swift.print("abszisse PlotRect rect: \(rect)")
      return rect
   }
   
   func abszisse(rect: CGRect)->CGPath
   {
      let path = CGMutablePath()
      
      let abszissex = rect.origin.x + rect.size.width - AbszisseVorgaben.legendebreite
      let bigmark = CGFloat(6)
      let submark = CGFloat(3)
      
      path.move(to: CGPoint(x:  abszissex, y: rect.origin.y ))
      //path.move(to: rect.origin)
      // linie nach oben
      path.addLine(to: CGPoint(x:  abszissex, y: rect.origin.y + rect.size.height))
      
      // wieder nach unten
      path.move(to: CGPoint(x:  abszissex, y: rect.origin.y ))
      //marken setzen
      let markdistanz = rect.size.height / (CGFloat(AbszisseVorgaben.MajorTeileY ) )
      let subdistanz = CGFloat(markdistanz) / CGFloat(AbszisseVorgaben.MinorTeileY)
      var posy = rect.origin.y
      let deznummer = NSDecimalNumber(decimal:pow(10,AbszisseVorgaben.exponent)).intValue
      
      for pos in 0...(AbszisseVorgaben.MajorTeileY - 1)
      {
         path.addLine(to: CGPoint(x:abszissex - bigmark, y: posy))
         
         if (( pos % AbszisseVorgaben.rastervertikal ) == 0)
         {
            // Wert
            let p = path.currentPoint
            let zehnerpotenz = pow(10,AbszisseVorgaben.exponent)
            let wert = pos * deznummer
            let tempWertString = String(format: "%d",  wert)
            //Swift.print("p: \(p) tempWertString: \(tempWertString)")
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .right
            let attrs = [NSFontAttributeName: NSFont(name: "HelveticaNeue-Thin", size: 8)!, NSParagraphStyleAttributeName: paragraphStyle]
            
            tempWertString.draw(with: CGRect(x: p.x - 42 , y: p.y - 5, width: 40, height: 14), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
         }
         
         var subposy = posy // aktuelle Position
         for _ in 1..<(AbszisseVorgaben.MinorTeileY)
         {
            subposy = subposy + subdistanz
            path.move(to: CGPoint(x:  abszissex, y: subposy ))
            path.addLine(to: CGPoint(x:abszissex - submark,y: subposy))
            
         }
         
         posy = posy + markdistanz
         //posy = rect.origin.y + CGFloat(pos) * markdistanz
         path.move(to: CGPoint(x:  abszissex, y: posy))
         
      }
      path.addLine(to: CGPoint(x:abszissex - bigmark, y: posy))
      // Wert
      
      let p = path.currentPoint
      let wert = AbszisseVorgaben.MajorTeileY * deznummer
      let tempWertString = String(format: "%d",  wert)
      //Swift.print("p: \(p) tempWertString: \(tempWertString)")
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .right
      let attrs = [NSFontAttributeName: NSFont(name: "HelveticaNeue-Thin", size: 8)!, NSParagraphStyleAttributeName: paragraphStyle]
      
      tempWertString.draw(with: CGRect(x: p.x - 42 , y: p.y - 5, width: 40, height: 14), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
      
      
      return path
   }
   func backgroundColor_n(color: NSColor)
   {
      wantsLayer = true
      layer?.backgroundColor = color.cgColor
   }
   
   
}

extension Abszisse
{
   func DiagrammFeld() -> CGRect
   {
      return diagrammfeld
   }
   
   func DiagrammFeldHeight()->CGFloat
   {
      //Swift.print("")
      return diagrammfeld.size.height
   }
   
   func setDiagrammFeldHeight(h:CGFloat)
   {
      
      diagrammfeld.size.height = h
   }
   
   open func setVorgaben(vorgaben:[String:Float])
   {
      /*
       static var MajorTeileY: Int = 16                           // Teile der Hauptskala
       static var MinorTeileY: Int = 2                             // Teile der Subskala
       static var MaxY: CGFloat = 160.0                            // Obere Grenze der Anzeige
       static var MinY: CGFloat = 0.0                              // Untere Grenze der Anzeige
       static var MaxX: CGFloat = 1000                             // Obere Grenze der Abszisse
       
       static var ZeitKompression: CGFloat = 1.0
       static var Startsekunde: Int = 0
       static let NullpunktY: CGFloat = 0.0
       static let NullpunktX: CGFloat = 0.0
       static let DiagrammEcke: CGPoint = CGPoint(x:15, y:10)// Ecke des Diagramms im View
       static let DiagrammeckeY: CGFloat = 0.0 //
       static let StartwertX: CGFloat = 0.0 // Abszisse des ersten Wertew
       // static let StartwertY: CGFloat = 0.0
       
       // Achsen
       static let rastervertikal = 2 // Sprung innerhalb MajorTeileY + MinorTeileY
       
       
       static let majorrasterhorizontal = 50 // Sprung innerhalb Zeitachse
       static let minorrasterhorizontal = 10
       
       */
      if (vorgaben["zeitkompression"] != nil)
      {
         AbszisseVorgaben.ZeitKompression = CGFloat(vorgaben["zeitkompression"]!)
      }
      if (vorgaben["MajorTeileY"] != nil)
      {
         AbszisseVorgaben.MajorTeileY = Int((vorgaben["MajorTeileY"])!)
      }
      
      if (vorgaben["MinorTeileY"] != nil)
      {
         AbszisseVorgaben.MinorTeileY = Int((vorgaben["MinorTeileY"])!)
      }
      
      if (vorgaben["MaxY"] != nil)
      {
         AbszisseVorgaben.MaxY = CGFloat((vorgaben["MaxY"])!)
      }
      
      if (vorgaben["MaxY"] != nil)
      {
         AbszisseVorgaben.MinY = CGFloat((vorgaben["MinY"])!)
      }
      
      if (vorgaben["MaxX"] != nil)
      {
         AbszisseVorgaben.MaxX = CGFloat((vorgaben["MaxX"])!)
      }
      
      
      needsDisplay = true
   }
   
   
   open func setMaxX(maxX:Int)
   {
      AbszisseVorgaben.MaxX = CGFloat(maxX)
   }
   
   open func setMaxY(maxY:Int)
   {
      AbszisseVorgaben.MaxY = CGFloat(maxY)
   }
   
   
   func AbszisseRect(rect: CGRect) -> CGRect
   {
      /*
       let diagrammrect = CGRect.init(x: rect.origin.x +  rect.size.width  , y: rect.origin.y + Geom.offsety + Geom.randunten, width: rect.size.width  , height: rect.size.height - Geom.offsety - Geom.freey)
       return diagrammrect
       */
      
      let diagrammrect = CGRect.init(x: rect.origin.x +  rect.size.width  , y: rect.origin.y + Geom.offsety  + Geom.offsety, width: rect.size.width - Geom.offsetx - Geom.freex  - Geom.randrechts  -  Geom.randlinks, height: rect.size.height - Geom.offsety - Geom.freey  - Geom.randoben - Geom.randunten)
      
      return diagrammrect
      
      
      
      /*
       // DATA_INTERFACE 5
       let diagrammrect = CGRect.init(x: rect.origin.x + Geom.offsetx, y: rect.origin.y + Geom.offsety  + Geom.offsety, width: rect.size.width - Geom.offsetx - Geom.freex  - Geom.randrechts  -  Geom.randlinks, height: rect.size.height - Geom.offsety - Geom.freey  - Geom.randoben - Geom.randunten)
       return diagrammrect
       */
      
   }
   
   
   
   
   func AbszisseFeld() -> CGRect
   {
      return diagrammfeld
   }
   
   func drawAbszisseInContext(context: CGContext?)
   {
      context!.setLineWidth(0.6)
      //let diagrammRect = PlotRect()
      let randfarbe =  CGColor.init(red:1.0,green: 0.0, blue: 0.0,alpha:1.0)
      let feldfarbe = CGColor.init(red:0.8,green: 0.8, blue: 0.0,alpha:1.0)
      let linienfarbe = CGColor.init(red:0.0,green: 0.0, blue: 1.0,alpha:1.0)
      
      drawAbszisseRect(rect: diagrammfeld, inContext: context,
                       borderColor: randfarbe,
                       fillColor: feldfarbe)
      
      self.setNeedsDisplay(self.frame)
   }
   
   
   
   func drawAbszisseRect(rect: CGRect, inContext context: CGContext?,
                         borderColor: CGColor, fillColor: CGColor)
   {
      /*
       Diagramm im Plotrect zeichnen
       */
      var path = CGMutablePath()
      
      //path.addRect(rect)
      
      // Feld fuer das Diagramm
      //  let diagrammrect = CGRect.init(x: rect.origin.x + Geom.offsetx, y: rect.origin.y + Geom.offsety, width: rect.size.width - Geom.offsetx - Geom.freex , height: rect.size.height - Geom.offsety - Geom.freey)
      // diagrammfeld = DiagrammRect(rect: PlotRect())
      
      //let diagrammrect = DiagrammRect(rect: PlotRect())
      
      let x = rect.origin.x
      let y = rect.origin.y
      let a = rect.origin.x + rect.size.width
      let b = rect.origin.y + rect.size.height
      /*
       path.move(to: CGPoint(x:  diagrammfeld.origin.x, y: diagrammfeld.origin.y ))
       path.addLine(to: NSMakePoint(diagrammfeld.origin.x + diagrammfeld.size.width, diagrammfeld.origin.y )) // > rechts
       path.addLine(to: NSMakePoint(diagrammfeld.origin.x + diagrammfeld.size.width, diagrammfeld.origin.y + diagrammfeld.size.height)) // > oben
       path.addLine(to: NSMakePoint(diagrammfeld.origin.x , diagrammfeld.origin.y + diagrammfeld.size.height)) // > links
       path.addLine(to: NSMakePoint(diagrammfeld.origin.x , diagrammfeld.origin.y))
       //    path.addLine(to: NSMakePoint(diagrammrect.origin.x + diagrammrect.size.width, diagrammrect.origin.y + diagrammrect.size.height))
       path.closeSubpath()
       
       context?.setLineWidth(1.5)
       context?.setFillColor(fillColor)
       context?.setStrokeColor(borderColor)
       */
      // 4
      //     context?.addPath(path)
      // context?.drawPath(using: .fillStroke)
      //let achsenpath = achsen(rect:diagrammfeld)
      //context?.addPath(achsenpath)
      let abszissebreite = CGFloat(10.0)
      var abszisserect = diagrammfeld
      abszisserect.size.width = abszissebreite
      abszisserect.origin.x -= 1
      let abszissefarbe = CGColor.init(red:0.0,green:0.5, blue: 0.5,alpha:1.0)
      
      
      let abszissepath = abszisse(rect:abszisserect)
      // let abszissepath = abszisse(rect:rect,linienfarbe:borderColor)
      context?.setLineWidth(1.0)
      context?.addPath(abszissepath)
      context?.setStrokeColor(abszissefarbe)
      //context?.setFillColor(CGColor.init(red:0x00,green: 0xFF, blue: 0xFF,alpha:1.0))
      context?.drawPath(using: .stroke)
      
      
      
      //context?.drawPath(using: .stroke)
      //Swift.print("GraphArray drawPath end")
   }
   
   override func draw(_ dirtyRect: NSRect)
   {
      super.draw(dirtyRect)
      let context = NSGraphicsContext.current()?.cgContext
      
      
      //    NSColor.white.setFill()
      //    NSRectFill(bounds)
      drawAbszisseInContext(context:context)
      
      
      
   }
   
   
   
}
