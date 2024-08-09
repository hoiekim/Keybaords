//
//  CommonKeys.swift
//  Keyboard
//
//  Created by Hoie Kim on 8/6/24.
//

import UIKit

typealias OnTapUtilKey = (UtilKey, UITextDocumentProxy, KeyInputContext) -> Void

class UtilKey: Key {
    let id: String
    var title: String
    let span: Int
    var _onTap: OnTapUtilKey

    init(
        id: String,
        title: String,
        span: Int = 1,
        onTap: @escaping OnTapUtilKey
    ) {
        self.id = id
        self.title = title
        self.span = span
        self._onTap = onTap
    }

    func onTap(document: UITextDocumentProxy, context: KeyInputContext) {
        self._onTap(self, document, context)
    }
}

private func trimSpacesBefore(document: UITextDocumentProxy) {
    while document.documentContextBeforeInput?.last == " " {
        document.deleteBackward()
    }
}

let backSpace = UtilKey(
    id: "backSpace",
    title: "⌫",
    onTap: { _, document, context in
        if context.isCapsLocked {
            // Delete backward to the beginning of the line
            let beforeText = document.documentContextBeforeInput
            let lastLetter = beforeText?.last
            if lastLetter == "\n" { return document.deleteBackward()  }
            guard let lastLine = beforeText?.split(separator: "\n").last else { return }
            for _ in 0 ..< lastLine.count {
                document.deleteBackward()
            }
        } else if context.isShifted {
            // Delete backward to one word before
            guard let beforeText = document.documentContextBeforeInput else { return }
            if beforeText.last == "\n" { return document.deleteBackward() }
            trimSpacesBefore(document: document)
            guard let beforeText = document.documentContextBeforeInput else { return }
            if beforeText.last == "\n" { return }
            let lineStart = beforeText.split(separator: "\n").last?.count
            let wordStart = beforeText.split(separator: " ").last?.count
            let deleteCount = minOfCoalesced(lineStart, wordStart) ?? beforeText.count
            for _ in 0 ..< deleteCount {
                document.deleteBackward()
            }
            trimSpacesBefore(document: document)
        } else {
            // Delte backword to one character
            document.deleteBackward()
        }
    }
)

let TITLE_SHIFT_DEFAULT = "⇧"
let TITLE_SHIFT_DEPERRESED = "⇪"
let TITLE_SHIFT_LOCKED = "⏏︎"

let shift = UtilKey(
    id: "shift",
    title: TITLE_SHIFT_DEFAULT,
    onTap: { key, _, context in
        if context.isDoubleTapped {
            context.isCapsLocked = true
            key.title = TITLE_SHIFT_LOCKED
        } else {
            if context.isCapsLocked {
                context.isCapsLocked = false
                context.isShifted = false
                key.title = TITLE_SHIFT_DEFAULT
            } else if context.isShifted {
                context.isShifted = false
                key.title = TITLE_SHIFT_DEFAULT
            } else {
                context.isShifted = true
                key.title = TITLE_SHIFT_DEPERRESED
            }
        }
    }
)

let space = SingleKey(title: " ", span: 2)

let enter = UtilKey(
    id: "enter",
    title: "⏎",
    onTap: { _, document, _ in
        document.insertText("\n")
    }
)

let changeKeySet = UtilKey(
    id: "changeKeySet",
    title: "☆",
    onTap: { _, _, context in
        if context.keySet[0][0].id == dash.id {
            context.keySet = englishKeySet
        } else {
            context.keySet = symbolKeySet
        }
    }
)
