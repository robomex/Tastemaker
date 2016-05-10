//
//  TriangleView.swift
//  Tastemaker
//
//  Created by Tony Morales on 5/7/16.
//  Copyright © 2016 Tony Morales. All rights reserved.
//

import Foundation
import UIKit

class TriangleView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func drawRect(rect: CGRect) {
        let ctx: CGContextRef = UIGraphicsGetCurrentContext()!
        
        CGContextBeginPath(ctx)
        CGContextMoveToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect))
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect))
        CGContextAddLineToPoint(ctx, (CGRectGetMaxX(rect)/2.0), CGRectGetMinY(rect))
        CGContextClosePath(ctx)
        
        CGContextSetRGBFillColor(ctx, 0.29, 0.29, 0.29, 1.0)
        CGContextFillPath(ctx)
    }
}