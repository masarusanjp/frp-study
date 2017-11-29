//: [Previous](@previous)

import UIKit
import RxSwift
import RxCocoa
import XCPlayground
import PlaygroundSupport
import FrpStudyHelper

protocol Pump {
    
}

enum UpDown {
    case up
    case down
}

enum Key: Int {
    case zero, one, two, three, four, five, six, seven, eight, nine
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
enum Delivery {
    case off, slow1, fast1, slow2, fast2, slow3, fast3
}

protocol Sale {
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
}



class ViewController: UIViewController {
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
        
        func converToUpDownSignal(_ button: UIButton) -> Signal<UpDown> {
            return button.rx
                .observe(Bool.self, "isSelected")
                .map { $0 ? UpDown.up : UpDown.down }
                .asSignal(onErrorSignalWith: .empty())
        }
        let nozzle1: Signal<UpDown> = converToUpDownSignal(v.nozzleButtons[0])
        let nozzle2: Signal<UpDown> = converToUpDownSignal(v.nozzleButtons[1])
        let nozzle3: Signal<UpDown> = converToUpDownSignal(v.nozzleButtons[2])
        let keyPad: Signal<Key> = Signal<Key>.merge(v.numberButtons.map { btn in btn.rx.tap.map { Key(rawValue: btn.tag)! }.asSignal(onErrorSignalWith: .empty()) })
        let fuelPulses: Signal<Int> = .empty()
        let calibration = BehaviorRelay<Double>(value: 1.0)
        let price1 = BehaviorRelay<Double>(value: 1.0)
        let price2 = BehaviorRelay<Double>(value: 2.0)
        let price3 = BehaviorRelay<Double>(value: 3.0)
        let clearSale: Signal<Int> = .empty()
        
        let inputs = Inputs(nozzle1: nozzle1, nozzle2: nozzle2, nozzle3: nozzle3, keyPad: keyPad, fuelPulses: fuelPulses, calibration: calibration, price1: price1, price2: price2, price3: price3, clearSale: clearSale)
        
    }
}

PlaygroundPage.current.liveView = ViewController(nibName: nil, bundle: nil)

//: [Next](@next)
