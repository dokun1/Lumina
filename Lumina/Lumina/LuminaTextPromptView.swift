//
//  LuminaTextPromptView.swift
//  Lumina
//
//  Created by David Okun on 5/7/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit

final class LuminaTextPromptView: UIView {

    private var textLabel = UILabel()
    static private let animationDuration = 0.3

    init() {
        super.init(frame: CGRect.zero)
        self.textLabel = UILabel()
        self.textLabel.backgroundColor = UIColor.clear
        self.textLabel.textColor = UIColor.white
        self.textLabel.textAlignment = .center
        self.textLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        self.textLabel.numberOfLines = 3
        self.textLabel.minimumScaleFactor = 10/UIFont.labelFontSize
        self.textLabel.adjustsFontSizeToFitWidth = true
        self.textLabel.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.textLabel.layer.shadowOpacity = 1
        self.textLabel.layer.shadowRadius = 6
        self.addSubview(textLabel)
        self.backgroundColor = UIColor.clear
        self.alpha = 0.0
        self.layer.cornerRadius = 5.0
    }

    func updateText(to text: String) {
        DispatchQueue.main.async {
            if text.isEmpty {
                self.hide(andErase: true)
            } else {
                self.textLabel.text = text
                self.makeAppear()
            }
        }
    }

    func hide(andErase: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: LuminaTextPromptView.animationDuration, animations: {
                self.alpha = 0.0
            }, completion: { _ in
                if andErase {
                    self.textLabel.text = ""
                }
            })
        }
    }

    private func makeAppear() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: LuminaTextPromptView.animationDuration) {
                self.alpha = 1
            }
        }
    }

    override func layoutSubviews() {
        self.frame.size = CGSize(width: UIScreen.main.bounds.maxX - 110, height: 80)
        self.textLabel.frame = CGRect(origin: CGPoint(x: 5, y: 5), size: CGSize(width: frame.width - 10, height: frame.height - 10))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
