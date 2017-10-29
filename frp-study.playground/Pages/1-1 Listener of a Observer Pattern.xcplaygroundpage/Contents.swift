//: Playground - noun: a place where people can play

import UIKit
import RxSwift

/*:
 # Listner of a Observer pattern
*/

protocol ListBoxListener: class {
    func itemSelected(at index: Int)
}

class ListBox {
    private var listeners: [ListBoxListener] = []
    
    func addListener(_ listener: ListBoxListener) {
        listeners.append(listener)
    }
    func removeListener(_ listener: ListBoxListener) {
        let optionalIndex = listeners.index { $0 === listener }
        guard let index = optionalIndex else {
            return
        }
        listeners.remove(at: index)
    }
    func notifyItemSelected(at index: Int) {
        listeners.forEach { $0.itemSelected(at: index) }
    }
}

class Subject: ListBoxListener {
    let name: String
    init(name: String) {
        self.name = name
    }
    func itemSelected(at index: Int) {
        print("\(name): \(index)")
    }
}
let listBox = ListBox()
listBox.addListener(Subject(name: "subject"))
listBox.notifyItemSelected(at: 0)
