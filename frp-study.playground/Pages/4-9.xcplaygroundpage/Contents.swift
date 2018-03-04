//: [Previous](@previous)

import UIKit
import RxSwift
import RxCocoa
import XCPlayground
import PlaygroundSupport
import FrpStudyHelper


protocol Pump {
    func create(inputs: Inputs, disposeBag: DisposeBag) -> Outputs
}

enum UpDown {
    case up
    case down
}

enum Key: Int {
    case zero = 0, one, two, three, four, five, six, seven, eight, nine
    case clear = -1
}

enum Delivery: String {
    case off, slow1, fast1, slow2, fast2, slow3, fast3
}

class Sale {
    let fuel: Fuel
    let price: Double
    let cost: Double
    let quantity: Double
    
    init(fuel: Fuel, price: Double, cost: Double, quantity: Double) {
        self.fuel = fuel
        self.price = price
        self.cost = cost
        self.quantity = quantity
    }
}

enum Fuel: CustomStringConvertible {
    case one, two, three
    var description: String {
        switch self {
        case .one:
            return "1"
        case .two:
            return "2"
        case .three:
            return "3"
        }
    }
}

class Inputs {
    let nozzle1: Signal<UpDown>
    let nozzle2: Signal<UpDown>
    let nozzle3: Signal<UpDown>
    let keyPad: Signal<Key>
    let fuelPulses: Signal<Int>
    let calibration: BehaviorRelay<Double>
    let price1: BehaviorRelay<Double>
    let price2: BehaviorRelay<Double>
    let price3: BehaviorRelay<Double>
    let clearSale: Signal<Int>
    init(nozzle1: Signal<UpDown>, nozzle2: Signal<UpDown>, nozzle3: Signal<UpDown>, keyPad: Signal<Key>, fuelPulses: Signal<Int>, calibration: BehaviorRelay<Double>, price1: BehaviorRelay<Double>, price2: BehaviorRelay<Double>, price3: BehaviorRelay<Double>, clearSale: Signal<Int>) {
        self.nozzle1 = nozzle1
        self.nozzle2 = nozzle2
        self.nozzle3 = nozzle3
        self.keyPad = keyPad
        self.fuelPulses = fuelPulses
        self.calibration = calibration
        self.price1 = price1
        self.price2 = price2
        self.price3 = price3
        self.clearSale = clearSale
    }
}

class Outputs {
    let delivery: BehaviorRelay<Delivery>
    let presetLCD: BehaviorRelay<String>
    let saleCostLCD: BehaviorRelay<String>
    let saleQuantityLCD: BehaviorRelay<String>
    let priceLCD1: BehaviorRelay<String>
    let priceLCD2: BehaviorRelay<String>
    let priceLCD3: BehaviorRelay<String>
    let beep: Signal<Void>
    let saleComplete: Signal<Sale>
    
    init(delivery: BehaviorRelay<Delivery> = BehaviorRelay(value: .off),
         presetLCD: BehaviorRelay<String> = BehaviorRelay(value: ""),
         saleCostLCD: BehaviorRelay<String> = BehaviorRelay(value: ""),
         saleQuantityLCD: BehaviorRelay<String> = BehaviorRelay(value: ""),
         priceLCD1: BehaviorRelay<String> = BehaviorRelay(value: ""),
         priceLCD2: BehaviorRelay<String> = BehaviorRelay(value: ""),
         priceLCD3: BehaviorRelay<String> = BehaviorRelay(value: ""),
         beep: Signal<Void> = .empty(),
         saleComplete: Signal<Sale> = .empty()
        ) {
        self.delivery = delivery
        self.presetLCD = presetLCD
        self.saleCostLCD = saleCostLCD
        self.saleQuantityLCD = saleQuantityLCD
        self.priceLCD1 = priceLCD1
        self.priceLCD2 = priceLCD2
        self.priceLCD3 = priceLCD3
        self.beep = beep
        self.saleComplete = saleComplete
    }
}

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

class KeypadPump: Pump {
    func create(inputs: Inputs, disposeBag: DisposeBag) -> Outputs {
        let keypad = Keypad(keypad: inputs.keyPad, clear: .never(), disposeBag: disposeBag)
        let value = BehaviorRelay<String>(value: "")
        keypad.value
            .map { String($0) }
            .bind(to: value)
            .disposed(by: disposeBag)
        return Outputs(presetLCD: value)
    }
}

class KeypadPumpViewController: UIViewController {
    let disposeBag = DisposeBag()
    override func loadView() {
        super.loadView()
        let frame = self.view.frame
        let pompView = PompView.make()
        pompView.frame = frame
        view = pompView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        let v = view as! PompView
        
        func convertToUpDownSignal(_ button: UIButton) -> Signal<UpDown> {
            return button.rx
                .tap
                .map { button.isSelected }
                .map { ($0 ?? false) ? UpDown.up : UpDown.down }
                .asSignal(onErrorSignalWith: .empty())
        }
        let nozzle1: Signal<UpDown> = convertToUpDownSignal(v.nozzleButtons[0])
        let nozzle2: Signal<UpDown> = convertToUpDownSignal(v.nozzleButtons[1])
        let nozzle3: Signal<UpDown> = convertToUpDownSignal(v.nozzleButtons[2])
        var buttons = v.numberButtons.map { btn in btn.rx.tap.map { Key(rawValue: btn.tag)! }.asSignal(onErrorSignalWith: .empty()) }
        buttons.append(v.clearButton.rx.tap.map { Key.clear }.asSignal(onErrorSignalWith: .empty()))
        let keyPad: Signal<Key> = Signal<Key>.merge(buttons)
        let fuelPulsesRelay = PublishRelay<Int>()
        let fuelPulses: Signal<Int> = fuelPulsesRelay.asSignal()
        let calibration = BehaviorRelay<Double>(value: 1.0)
        let price1 = BehaviorRelay<Double>(value: 1.0)
        let price2 = BehaviorRelay<Double>(value: 2.0)
        let price3 = BehaviorRelay<Double>(value: 3.0)
        let clearSale: Signal<Int> = v.saleOKButton.rx.tap.map { 0 }.asSignal(onErrorSignalWith: .empty())
        
        let inputs = Inputs(nozzle1: nozzle1, nozzle2: nozzle2, nozzle3: nozzle3, keyPad: keyPad, fuelPulses: fuelPulses, calibration: calibration, price1: price1, price2: price2, price3: price3, clearSale: clearSale)
        
        let outputs = KeypadPump().create(inputs: inputs, disposeBag: disposeBag)
        outputs.presetLCD
            .bind(to: v.presetLabel.rx.text)
            .disposed(by: disposeBag)
    }
}


PlaygroundPage.current.liveView = KeypadPumpViewController(nibName: nil, bundle: nil)

//: [Next](@next)



