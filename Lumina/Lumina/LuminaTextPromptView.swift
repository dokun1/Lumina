//
//  LuminaTextPromptView.swift
//  Lumina
//
//  Created by David Okun IBM on 5/7/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit

final class LuminaTextPromptView: UIView {
    
    private var textLabel = UILabel()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.textLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: frame.width, height: frame.height)))
        self.textLabel.backgroundColor = UIColor.clear
        self.textLabel.textColor = UIColor.white
        self.textLabel.textAlignment = .center
        self.textLabel.font = UIFont.systemFont(ofSize: 18)
        self.textLabel.numberOfLines = 4
        self.addSubview(textLabel)
        self.backgroundColor = UIColor.blue
        self.alpha = 0.65
        self.layer.cornerRadius = 5.0
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1.0
    }
    
    public func updateText(to text:String) {
        self.textLabel.text = text
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
