//
//  exp.swift
//  DataLogger
//
//  Created by Ruedi Heimlicher on 25.07.2017.
//  Copyright © 2017 Ruedi Heimlicher. All rights reserved.
//

import Foundation

let textA = "asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh  asdfgh    \n"
let textB = "asdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \tasdfgh  \n"

let paragraphStyle = NSMutableParagraphStyle()
let tabInterval:CGFloat = 20.0
let tabs:NSMutableArray = NSMutableArray.init()

for cnt in 0..<24 
{    // Add 24 tab stops, at desired intervals...
   tabs.add(NSTextTab(textAlignment: .left, location: (CGFloat(cnt) * tabInterval), options: [:]))
   
   paragraphStyle.tabStops.append(NSTextTab(textAlignment: .left, location: (CGFloat(cnt) * tabInterval), options: [:]))
}

let attrtext = NSMutableAttributedString(string: textB)
let textRange = NSMakeRange(0, textB.characters.count)
attrtext.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: textRange)
// load the text
downloadDataFeld.textStorage?.append(attrtext)
