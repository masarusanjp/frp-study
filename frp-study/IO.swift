import Foundation
import RxSwift
import RxCocoa

enum UpDown {
    case up
    case down
}

enum Key: Int {
    case zero, one, two, three, four, five, six, seven, eight, nine
}


enum Delivery: String {
    case off, slow1, fast1, slow2, fast2, slow3, fast3
}

protocol Sale {
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
