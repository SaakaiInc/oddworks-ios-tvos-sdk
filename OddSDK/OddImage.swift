//
//  OddImage.swift
//  OddSDK
//
//  Created by Patrick McConnell on 6/16/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import UIKit

public struct OddImage {
  /// The URL to the image. Required
  public var url: String
  /// the optional mimeType of the image. Required
  public var mimeType: String?
  
  /// An optional value for the width of the image
  public var width: Int?
  
  /// An optional value for the height of the image
  public var height: Int?
  
  /// An label for the image
  public var label: String
  
  public static func imageFromJson(_ json: jsonObject) -> OddImage? {
    guard let url       = json["url"] as? String,
      let label     = json["label"] as? String  else {
        return nil
    }
    
    let mimeType  = json["mimeType"] as? String
    let width     = json["width"] as? Int
    let height    = json["height"] as? Int
    
    
    return OddImage(url: url, mimeType: mimeType, width: width, height: height, label: label)
  }
}
