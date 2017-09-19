//
//  LuminaMetadataBorderView.swift
//  Lumina
//
//  Created by David Okun on 5/11/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit

final class LuminaMetadataBorderView: UIView {
    
    private var corners: [CGPoint]?
    private var outline = CAShapeLayer()
    public var boundsFace = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderColor = UIColor.blue.cgColor
        self.layer.borderWidth = 2.0
    }
    
    init(frame: CGRect, corners: [CGPoint]) {
        super.init(frame: frame)
        outline.strokeColor = UIColor.red.withAlphaComponent(0.8).cgColor
        outline.lineWidth = 2.0
        outline.fillColor = UIColor.clear.cgColor
        outline.path = drawPathFrom(corners).cgPath
        self.layer.addSublayer(outline)
    }
    
    init() {
        super.init(frame: CGRect.zero)
    }
    
    private func drawPathFrom(_ points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        guard let firstPoint = points.first else {
            return path
        }
        path.move(to: firstPoint)
        for (index, point) in points.enumerated() {
            if index == 0 {
                continue
            }
            path.addLine(to: point)
        }
        path.addLine(to: firstPoint)
        return path
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
