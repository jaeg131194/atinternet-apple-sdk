//
//  UILabelExtention.swift
//  popoup
//
//  Created by Théo Damaville on 01/03/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Used to compute the height of the Label given a text and a font
extension UILabel {
    func resizeToFit () -> CGFloat {
        let h = self.expectedheight()
        var frame = self.frame
        frame.size.height = h
        self.frame = frame
        return frame.origin.y + frame.size.height
    }
    
    func expectedheight () -> CGFloat {
        self.numberOfLines = 0
        self.lineBreakMode = .ByWordWrapping
        let max = CGSizeMake(self.frame.size.width,9999)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .ByWordWrapping
        print(self.text)
        let d = [NSFontAttributeName:self.font, NSParagraphStyleAttributeName: paragraph]
        let x = self.text!.boundingRectWithSize(max,options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: d, context: nil)
        return x.height
    }
}