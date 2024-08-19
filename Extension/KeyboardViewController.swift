//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Hoie Kim on 8/3/24.
//

import UIKit

class KeyboardViewController: UIInputViewController {
    let keyInputContext = KeyInputContext(
        isShifted: false,
        isCapsLocked: false,
        isDoubleTap: false,
        isShiftedDoubleTapped: false,
        keySet: englishKeySet
    )
    
    let buttonSpacing: CGFloat = 5

    @IBOutlet var nextKeyboardButton: UIButton!
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        adjustButtonSizes()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNextKeyboardButton()
        mountButtons()
    }
    
    override func viewWillLayoutSubviews() {
        nextKeyboardButton.isHidden = !needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }

    private func adjustButtonSizes() {
        let keySet = keyInputContext.keySet
        let maxNumberOfSpans = keySet.map { $0.reduce(0) { $0 + $1.span } }.max()!
        for (_, rowView) in buttonsView.arrangedSubviews.enumerated() {
            guard let rowStackView = rowView as? UIStackView else { continue }
            for (_, subView) in rowStackView.arrangedSubviews.enumerated() {
                guard let button = subView as? UIKeyButton else { continue }
                let key = button.key!
                let keyWidth = calculateKeyWidth(
                    span: key.span,
                    spanTotal: maxNumberOfSpans,
                    containerSize: view.bounds.width,
                    spacing: buttonSpacing
                )
                button.widthAnchor.constraint(equalToConstant: keyWidth).isActive = true
            }
        }
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
        var textColor: UIColor
        let proxy = textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        nextKeyboardButton.setTitleColor(textColor, for: [])
    }
    
    private func setupNextKeyboardButton() {
        nextKeyboardButton = UIButton(type: .system)
        
        nextKeyboardButton.setTitle(
            NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"),
            for: []
        )
        nextKeyboardButton.sizeToFit()
        nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        
        nextKeyboardButton.addTarget(
            self,
            action: #selector(handleInputModeList(from:with:)),
            for: .allTouchEvents
        )
        
        view.addSubview(nextKeyboardButton)
        
        nextKeyboardButton
            .leftAnchor
            .constraint(equalTo: view.leftAnchor)
            .isActive = true
        nextKeyboardButton
            .bottomAnchor
            .constraint(equalTo: view.bottomAnchor)
            .isActive = true
    }
    
    var buttonsView = UIStackView()
    
    private func mountButtons() {
        buttonsView.removeFromSuperview()
        buttonsView = UIStackView()
        buttonsView.axis = .vertical
        buttonsView.distribution = .fillEqually
        buttonsView.spacing = 5
        buttonsView.translatesAutoresizingMaskIntoConstraints = false

        for row in keyInputContext.keySet {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.spacing = buttonSpacing
            rowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            for key in row {
                let button = createButton(withKey: key)
                rowStackView.addArrangedSubview(button)
            }
            
            let minimumRowHeight: CGFloat = 45.0
            let constraint = rowStackView
                .heightAnchor
                .constraint(greaterThanOrEqualToConstant: minimumRowHeight)
            constraint.isActive = true
            
            buttonsView.addArrangedSubview(rowStackView)
        }
        
        view.addSubview(buttonsView)
        NSLayoutConstraint.activate([
            buttonsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            buttonsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            buttonsView.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
            buttonsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5)
        ])
    }
    
    private func createButton(withKey key: Key) -> UIButton {
        let button = UIKeyButton(type: .custom)
        button.key = key
        let title = key.getTitle(keyInputContext)
        let titleSuperscript = key.getTitleSuperscript(keyInputContext)
        let image = key.getImage(keyInputContext)
        let backgroundColor = key.getBackgroundColor(keyInputContext)
        
        if image != nil {
            let uiImageConfig = UIImage.SymbolConfiguration(scale: .medium)
            let uiImage = UIImage(
                systemName: image!,
                withConfiguration: uiImageConfig
            )
            button.setImage(uiImage, for: .normal)
            button.tintColor = .white
        }
        
        if title != nil {
            button.setTitle(title, for: .normal)
        }
        
        if titleSuperscript != nil {
            button.setTitleSuperscript(titleSuperscript!)
        }
        
        button.backgroundColor = backgroundColor ?? UIColor.darkGray
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(keyTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    private func updateButtonImages() {
        for (_, rowView) in buttonsView.arrangedSubviews.enumerated() {
            guard let rowStackView = rowView as? UIStackView else { continue }
            for (_, subView) in rowStackView.arrangedSubviews.enumerated() {
                guard let button = subView as? UIKeyButton else { continue }
                button.updateImage(keyInputContext)
            }
        }
    }
    
    @objc func keyTapped(sender: UIKeyButton) {
        let key = sender.key!
        handleDoubleTap(key: key)
        key.onTap(document: textDocumentProxy, context: keyInputContext)
        UIImpactFeedbackGenerator().impactOccurred()
        
        let isShiftKey = key.id == shift.id
        let isCapsLocked = keyInputContext.isCapsLocked
        
        var shouldUpdateButtonImages = key.updateButtonImagesOnTap
        if !isCapsLocked && !isShiftKey {
            keyInputContext.isShifted = false
            shouldUpdateButtonImages = true
        }
        
        if key.remountOnTap {
            mountButtons()
            adjustButtonSizes()
        } else if shouldUpdateButtonImages {
            updateButtonImages()
        }
    }
    
    private var firstTappedKey: Key?
    private var isFirstTappedKeyShifted: Bool = false
    private var doubleTapTimer: Timer?
    
    func handleDoubleTap(key: Key) {
        if firstTappedKey?.id == key.id {
            keyInputContext.isDoubleTapped = true
            keyInputContext.isShiftedDoubleTapped = isFirstTappedKeyShifted
            doubleTapTimer?.invalidate()
        } else {
            isFirstTappedKeyShifted = keyInputContext.isShifted
            firstTappedKey = key
            keyInputContext.isDoubleTapped = false
            keyInputContext.isShiftedDoubleTapped = false
        }
        doubleTapTimer = Timer.scheduledTimer(
            timeInterval: 0.3,
            target: self,
            selector: #selector(resetDoubleTap),
            userInfo: nil,
            repeats: false
        )
    }

    @objc private func resetDoubleTap() {
        firstTappedKey = nil
        keyInputContext.isDoubleTapped = false
    }
}
