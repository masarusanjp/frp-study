import Foundation
import RxSwift
import RxCocoa

class Keypad {
    let value: BehaviorRelay<Int>
    let beep: Signal<Void>
    
    convenience init(keypad: Signal<Key>, clear: Signal<Int>, active: BehaviorRelay<Bool>, disposeBag: DisposeBag) {
        let filteredKeypad = keypad
            .withLatestFrom(active.asSignal(onErrorSignalWith: .empty())) { ($0, $1) }
            .filter { return $1 == false }
            .map { $0.0 }
        self.init(keypad: filteredKeypad, clear: clear, disposeBag: disposeBag)
    }
    
    init(keypad: Signal<Key>, clear: Signal<Int>, disposeBag: DisposeBag) {
        let value = BehaviorRelay<Int>(value: 0)
        self.value = value
        let keyUpdated: Signal<Int> = keypad
            .withLatestFrom(value.asSignal(onErrorSignalWith: .empty())) { ($0, $1) }
            .flatMap { (key, value) -> Signal<Int> in
                if key == .clear {
                    return .just(0)
                } else {
                    let x10: Int = value * 10
                    if x10 >= 1000 {
                        return .empty()
                    } else {
                        return .just(x10 + key.rawValue)
                    }
                }
        }
        keyUpdated
            .asDriver(onErrorDriveWith: .empty())
            .drive(value)
            .disposed(by: disposeBag)
        beep = keyUpdated.map { _ in }
    }
}

