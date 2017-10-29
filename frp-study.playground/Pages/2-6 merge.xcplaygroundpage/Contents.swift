//: [Previous](@previous)

import Foundation
import RxSwift
import RxCocoa
import RxTest

let disposeBag = DisposeBag()

class ClearText {
    static func run() {
        let clearButtonClicked: Observable<Void> = .just(())
        let clearIt: Observable<String> = clearButtonClicked.map { _ in "" }
        let text = BehaviorSubject(value: "Hello")
        text.subscribe(onNext: { print("text: \($0)")} ).disposed(by: disposeBag)
        clearIt.bind(to: text).disposed(by: disposeBag)
    }
}

ClearText.run()

class GameChat {
    static func run() {
        let thanksClicked: Observable<Void> = .just(())
        let onegaiClicked: Observable<Void> = .just(())
        let onegai = onegaiClicked.map { _ in "Onegai Simasu" }
        let thanks = thanksClicked.map { _ in "Thank you" }
        let canned = Observable<String>.merge([onegai, thanks])
        canned.subscribe(onNext: { print("text: \($0)") }).disposed(by: disposeBag)
    }
}

GameChat.run()

class DrawingExample {
    enum ShapeID {
        case triangle
        case hexagon
    }
    
    static func run() {
        let scheduler = TestScheduler(initialClock: 0)
        let clicked: Observable<ShapeID> = scheduler.createHotObservable([
            next(0, ShapeID.triangle),
            next(1, ShapeID.hexagon)
            ]).asObservable()
        
        let triangleSelected: Observable<Bool> = clicked.map { $0 == .triangle }
        let hexagonSelected: Observable<Bool> = clicked.map { $0 == .hexagon }
        let changes = Observable<String>.merge(
            triangleSelected.map { $0 ? "triangle selected" : "triangle de-selected" },
            hexagonSelected.map { $0 ? "hexagon selected" : "hexagon de-selected" }
        )
        changes.subscribe(onNext: { print("text: \($0)") }).disposed(by: disposeBag)
        scheduler.start()
    }
}

DrawingExample.run()
