//
//  UIImageExtension.swift
//  SmartTracker
//
//  Created by Théo Damaville on 05/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    /**
     Crop : crop an UIImage
     
     - parameter rect: A Rectangle that represent the area to crop
     
     - returns: The cropped image
     */
    func crop(_ rect: CGRect) -> UIImage? {
        let rectangle = CGRect(x: rect.origin.x * self.scale,
            y: rect.origin.y*self.scale,
            width: rect.size.width*self.scale,
            height: rect.size.height*self.scale);
        
        let imageRef = self.cgImage?.cropping(to: rectangle);
        
        if let image = imageRef {
            let result = UIImage(cgImage: image, scale: self.scale, orientation: self.imageOrientation)
            return result;
        }
        else {
            return nil
        }
    }
    
    /**
     toBase64: convenience method to concert an image to a base64 String
     
     - returns: The base64 representation of the image
     */
    func toBase64 () -> String? {
        return UIImageJPEGRepresentation(self, 0.25)?.base64EncodedString(options: Data.Base64EncodingOptions.endLineWithLineFeed)
    }
}
