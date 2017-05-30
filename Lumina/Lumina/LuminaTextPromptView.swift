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
    static private let animationDuration = 0.3
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.textLabel = UILabel(frame: CGRect(origin: CGPoint(x: 5, y: 5), size: CGSize(width: frame.width - 10, height: frame.height - 10)))
        self.textLabel.backgroundColor = UIColor.clear
        self.textLabel.textColor = UIColor.white
        self.textLabel.textAlignment = .center
        self.textLabel.font = UIFont.systemFont(ofSize: 20)
        self.textLabel.numberOfLines = 3
        self.textLabel.minimumScaleFactor = 10/UIFont.labelFontSize
        self.textLabel.adjustsFontSizeToFitWidth = true
        self.addSubview(textLabel)
        self.backgroundColor = UIColor.blue
        self.alpha = 0.0
        self.layer.cornerRadius = 5.0
    }
    
    public func updateText(to text:String) {
        self.textLabel.text = text
        if self.alpha < 0.1 {
            self.makeAppear()
        }
    }
    
    public func hide(andErase: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: LuminaTextPromptView.animationDuration, animations: {
                self.alpha = 0.0
            }) { complete in
                if andErase {
                    self.textLabel.text = ""
                }
            }
        }
    }
    
    private func makeAppear() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: LuminaTextPromptView.animationDuration) {
                self.alpha = 0.65
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
