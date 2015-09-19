//
//  GOVenueCellView.swift
//  GrandOpens
//
//  Created by Tony Morales on 9/19/15.
//  Copyright (c) 2015 Tony Morales. All rights reserved.
//

import Foundation
import UIKit

struct GOVenueCellButtons: OptionSetType {
    let rawValue: Int
    init(rawValue: Int) {self.rawValue = rawValue}
    
    static let None = GOVenueCellButtons(rawValue: 1 << 0)
    static let Like = GOVenueCellButtons(rawValue: 1 << 1)
    
    static let Default: GOVenueCellButtons = [Like]
}