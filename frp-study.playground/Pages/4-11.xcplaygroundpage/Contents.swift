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
    let delivery: Driver<Delivery>
    let presetLCD: Driver<String>
    let saleCostLCD: Driver<String>
    let saleQuantityLCD: Driver<String>
    let priceLCD1: Driver<String>
    let priceLCD2: Driver<String>
    let priceLCD3: Driver<String>
    let beep: Signal<Void>
    let saleComplete: Signal<Sale>
    
    init(delivery: Driver<Delivery> = .empty(),
         presetLCD: Driver<String> = .empty(),
         saleCostLCD: Driver<String> = .empty(),
         saleQuantityLCD: Driver<String> = .empty(),
         priceLCD1: Driver<String> = .empty(),
         priceLCD2: Driver<String> = .empty(),
         priceLCD3: Driver<String> = .empty(),
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
class Preset {
    let delivery: Driver<Delivery>
    let keypadActive: Driver<Bool>
    
    enum Speed {
        case fast
        case slow
        case stopped
    }
    
    init(presetDollars: BehaviorRelay<Int>,
         fill: Fill,
         fuelFlowing: BehaviorRelay<Fuel?>,
         fillActive: Driver<Bool>) {
        // 給油速度を計算
        
        let speedStream: Driver<Speed> = Driver.combineLatest(
            presetDollars.asDriver(),
            fill.price.asDriver(),
            fill.dollersDelivered.asDriver(),
            fill.litersDelivered.asDriver()) { (presetDollars, price, dollersDelivered, litersDelivered) -> Speed in
                if presetDollars == 0 {
                    return .fast
                }
                if dollersDelivered >= Double(presetDollars) {
                    return .stopped
                }
                
                let slowLiters = Double(presetDollars) / price - 0.1
                if litersDelivered >= slowLiters {
                    return .slow
                }
                return .fast
        }
        
        delivery = Driver.combineLatest(
            fuelFlowing.asDriver(),
            speedStream) { fuelFlowing, speed -> Delivery in
                switch speed {
                case .fast:
                    switch fuelFlowing {
                    case .some(.one):
                        return .fast1
                    case .some(.two):
                        return .fast2
                    case .some(.three):
                        return .fast3
                    case .none:
                        return .off
                    }
                case .slow:
                    switch fuelFlowing {
                    case .some(.one):
                        return .slow1
                    case .some(.two):
                        return .slow2
                    case .some(.three):
                        return .slow3
                    case .none:
                        return .off
                    }
                case .stopped:
                    return .off
                }
        }
        
        keypadActive = Driver.combineLatest(
            fuelFlowing.asDriver(),
            speedStream) { fuelFlowing, speed in
                return fuelFlowing == nil || speed == .fast
        }
    }
}

class Fill {
    let price: BehaviorRelay<Double>
    let dollersDelivered: BehaviorRelay<Double>
    let litersDelivered: BehaviorRelay<Double>
    
    init(sClearAccumulator: Signal<Void>,
         sFuelPulses: Signal<Int>,
         calibration: BehaviorRelay<Double>,
         price1: BehaviorRelay<Double>,
         price2: BehaviorRelay<Double>,
         price3: BehaviorRelay<Double>,
         sStart: Signal<Fuel>,
         disposeBag: DisposeBag) {
        price = Fill.capturePrice(sStart: sStart,
                                  price1: price1,
                                  price2: price2,
                                  price3: price3,
                                  disposeBag: disposeBag)
        litersDelivered = accumulate(sClearAccumulator: sClearAccumulator,
                                     sPulses: sFuelPulses,
                                     calibration: calibration,
                                     disposeBag: disposeBag)
        let dollersDelivered = BehaviorRelay<Double>(value: 0)
        Observable<Double>.combineLatest(litersDelivered, price) { $0 * $1 }
            .asSignal(onErrorJustReturn: 0)
            .emit(onNext: dollersDelivered.accept)
            .disposed(by: disposeBag)
        self.dollersDelivered = dollersDelivered
    }
    
    static func capturePrice(sStart: Signal<Fuel>,
                             price1: BehaviorRelay<Double>,
                             price2: BehaviorRelay<Double>,
                             price3: BehaviorRelay<Double>,
                             disposeBag: DisposeBag) -> BehaviorRelay<Double> {
        let sPrice1 = sStart.asObservable().withLatestFrom(price1) { $0 == .one ? $1 : nil }.asSignal(onErrorJustReturn: nil)
        let sPrice2 = sStart.asObservable().withLatestFrom(price2) { $0 == .two ? $1 : nil }.asSignal(onErrorJustReturn: nil)
        let sPrice3 = sStart.asObservable().withLatestFrom(price3) { $0 == .three ? $1 : nil }.asSignal(onErrorJustReturn: nil)
        let capturedPrice = BehaviorRelay<Double>(value: 0)
        Signal<Double?>.merge([sPrice1, sPrice2, sPrice3]).filter { $0 != nil }.map { $0! }
            .emit(onNext: capturedPrice.accept)
            .disposed(by: disposeBag)
        return capturedPrice
    }
}

class LifeCycle {
    enum End {
        case end
    }
    let start: Signal<Fuel>
    let end: Signal<End>
    let fillActive: BehaviorRelay<Fuel?>
    
    static func whenLifted(for nozzle: Signal<UpDown>, fuel: Fuel) -> Signal<Fuel> {
        return nozzle.filter { $0 == .up }.map { _ in fuel }
    }
    
    static func whenSetDown(for nozzle: Signal<UpDown>, fuel: Fuel, fillActive: BehaviorRelay<Fuel?>) -> Signal<End> {
        return nozzle.asObservable()
            .withLatestFrom(fillActive.asObservable()) { upDown, fillActive in
                return upDown == .down && fillActive == fuel ? End.end : nil
            }
            .flatMap { value -> Observable<End> in
                if let value = value {
                    return .just(value)
                } else {
                    return .empty()
                }
            }
            .asSignal(onErrorSignalWith: .empty())
    }
    init(nozzle1: Signal<UpDown>, nozzle2: Signal<UpDown>, nozzle3: Signal<UpDown>, disposeBag: DisposeBag) {
        let liftNozzle = Signal<Fuel>.merge(
            LifeCycle.whenLifted(for: nozzle1, fuel: Fuel.one),
            LifeCycle.whenLifted(for: nozzle2, fuel: Fuel.two),
            LifeCycle.whenLifted(for: nozzle3, fuel: Fuel.three)
        )
        let fillActive = BehaviorRelay<Fuel?>(value: nil)
        let start = liftNozzle.asObservable()
            .withLatestFrom(fillActive.asObservable()) { ($0, $1) }
            .filter { $0.1 == nil }
            .map { $0.0 }
            .asSignal(onErrorSignalWith: .empty())
        
        let end = Signal<End>.merge(
            LifeCycle.whenSetDown(for: nozzle1, fuel: Fuel.one, fillActive: fillActive),
            LifeCycle.whenSetDown(for: nozzle2, fuel: Fuel.two, fillActive: fillActive),
            LifeCycle.whenSetDown(for: nozzle3, fuel: Fuel.three, fillActive: fillActive)
        )
        Signal<Fuel?>
            .merge(
                start.map { fuel in Optional<Fuel>.some(fuel) },
                end.map { _ in Optional<Fuel>.none }
            )
            .emit(onNext: fillActive.accept)
            .disposed(by: disposeBag)
        
        self.start = start
        self.end = end
        self.fillActive = fillActive
    }
}

enum Phase {
    case idol, filling, pos
}

class NotifyPointOfSale {
    let sStart: Signal<Fuel>
    let fillActive: BehaviorRelay<Fuel?> = BehaviorRelay(value: nil)
    let fuelFlowing: BehaviorRelay<Fuel?> = BehaviorRelay(value: nil)
    let sEnd: Signal<LifeCycle.End>
    let sBeep: Signal<Void>
    let sSaleComplete: Signal<Sale>
    
    init(lc: LifeCycle, sClearSale: Signal<Void>, fi: Fill, disposeBag: DisposeBag) {
        let phase = BehaviorRelay<Phase>(value: .idol)
        
        sStart = lc.start.asObservable()
            .debug()
            .withLatestFrom(phase) { ($0, $1) }
            .filter { $0.1 == .idol }
            .map { $0.0 }
            .asSignal(onErrorSignalWith: .empty())
        
        sEnd = lc.end.asObservable()
            .withLatestFrom(phase) { ($0, $1) }
            .filter { $0.1 == .filling }
            .map { $0.0 }
            .asSignal(onErrorSignalWith: .empty())
        
        sStart.asObservable().debug().subscribe(onNext: { end in
            phase.accept(.filling)
        })
            .disposed(by: disposeBag)
        sEnd.asObservable().debug().subscribe(onNext: { end in
            phase.accept(.pos)
        })
            .disposed(by: disposeBag)
        sClearSale.asObservable().debug().subscribe(onNext: { end in
            phase.accept(.idol)
        })
            .disposed(by: disposeBag)
        Signal<Fuel?>
            .merge(
                sStart.map { fuel in Optional<Fuel>.some(fuel) },
                sEnd.map { _ in Optional<Fuel>.none }
            )
            .debug()
            .emit(onNext: fuelFlowing.accept)
            .disposed(by: disposeBag)
        
        Signal<Fuel?>
            .merge(
                sStart.map { fuel in Optional<Fuel>.some(fuel) },
                sClearSale.map { _ in Optional<Fuel>.none }
            )
            .debug()
            .emit(onNext: fillActive.accept)
            .disposed(by: disposeBag)
        
        sBeep = sClearSale
        
        //        sSaleComplete = sEnd.asObservable().withLatestFrom(
        //            Observable<Sale?>.combineLatest(fuelFlowing, fi.price, fi.dollersDelivered, fi.litersDelivered) { f, p, d, l in
        //                if let f = f {
        //                    return Sale(fuel: f , price: p, cost: d, quantity: l)
        //                } else {
        //                    return nil
        //                }
        //            }
        //        )
        //            .flatMap { value -> Observable<Sale> in
        //                if let value = value {
        //                    return .just(value)
        //                } else {
        //                    return .empty()
        //                }
        //            }
        //            .asSignal(onErrorSignalWith: .empty())
        
        sSaleComplete = sEnd.asObservable().withLatestFrom(
            Observable<Sale>.combineLatest(fuelFlowing, fi.price, fi.dollersDelivered, fi.litersDelivered) { f, p, d, l in
                return Sale(fuel: f ?? .one, price: p, cost: d, quantity: l) // TODO: fix
            }
            )
            .asSignal(onErrorSignalWith: .empty())
        
        sSaleComplete.asObservable().subscribe(onNext: { sale in
            print(sale.fuel, sale.price, sale.cost, sale.quantity)
        })
            .disposed(by: disposeBag)
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

func accumulate(sClearAccumulator: Signal<Void>,
                sPulses: Signal<Int>,
                calibration: BehaviorRelay<Double>,
                disposeBag: DisposeBag) -> BehaviorRelay<Double> {
    let total = BehaviorRelay<Double>(value: 0)
    Signal<Double>.combineLatest(
        Signal<Double>.merge(
            sClearAccumulator.map { _ in 0 },
            sPulses.map { Double($0) }.withLatestFrom(total.asSignal(onErrorJustReturn: 0)) { $0 + $1 }
        ),
        calibration.asSignal(onErrorJustReturn: 0)) { $0 * $1 }
        .emit(onNext: total.accept)
        .disposed(by: disposeBag)
    return total
}

func makePriceLCD(fillActive: BehaviorRelay<Fuel?>,
              fillPrice: BehaviorRelay<Double>,
              fuel: Fuel,
              inputs: Inputs,
              disposeBag: DisposeBag) -> BehaviorRelay<String> {
    let idlePrice: BehaviorRelay<Double>
    switch fuel {
    case .one: idlePrice = inputs.price1
    case .two: idlePrice = inputs.price2
    case .three: idlePrice = inputs.price3
    }
    let priceLCD = BehaviorRelay<String>(value: "")
    Observable.combineLatest(fillActive, fillPrice, idlePrice) { oFuelSelected, fillPrice_, idlePrice_ -> String in
        if let oFuelSelected = oFuelSelected {
            return oFuelSelected == fuel ? Formatters.formatPrice(price: fillPrice_) : ""
        } else {
            return Formatters.formatPrice(price: idlePrice_)
        }
        }
        .asSignal(onErrorJustReturn: "")
        .emit(onNext: priceLCD.accept)
        .disposed(by: disposeBag)
    return priceLCD
}

struct Formatters {
    static func formatSaleQuantity(quantity: Double) -> String {
        return String(format: "%.2f", quantity)
    }
    
    static func formatSaleCost(cost: Double) -> String {
        return String(format: "%.2f", cost)
    }
    
    static func formatPrice(price: Double) -> String {
        return String(format: "%.2f", price)
    }
}

class PresetAmountPump: Pump {
    func create(inputs: Inputs, disposeBag: DisposeBag) -> Outputs {
        let start = PublishRelay<Fuel>()
        let fill = Fill(sClearAccumulator: inputs.clearSale.map { _ in },
                        sFuelPulses: inputs.fuelPulses,
                        calibration: inputs.calibration,
                        price1: inputs.price1,
                        price2: inputs.price2,
                        price3: inputs.price3,
                        sStart: start.asSignal(),
                        disposeBag: disposeBag)
        let notifyPointOfSale = NotifyPointOfSale(lc: LifeCycle(nozzle1: inputs.nozzle1,
                                                                nozzle2: inputs.nozzle2,
                                                                nozzle3: inputs.nozzle3,
                                                                disposeBag: disposeBag),
                                                  sClearSale: inputs.clearSale.map { _ in },
                                                  fi: fill,
                                                  disposeBag: disposeBag)
        let keypadActive = BehaviorRelay<Bool>(value: false)
        let keypad = Keypad(keypad: inputs.keyPad, clear: .never(), disposeBag: disposeBag)
        let preset = Preset(
            presetDollars: keypad.value,
            fill: fill,
            fuelFlowing: notifyPointOfSale.fuelFlowing,
            fillActive: notifyPointOfSale.fillActive.map { $0 != nil }.asDriver(onErrorDriveWith: .empty())
        )
        preset.keypadActive.drive(keypadActive).disposed(by: disposeBag)
        
        func priceLCD(_ fillActive: BehaviorRelay<Fuel?>,
                      _ fillPrice: BehaviorRelay<Double>,
                      _ fuel: Fuel) -> Driver<String> {
            return makePriceLCD(fillActive: fillActive, fillPrice: fillPrice, fuel: fuel, inputs: inputs, disposeBag: disposeBag).asDriver()
        }
        
        return Outputs(
            delivery: preset.delivery.asDriver(),
            presetLCD: keypad.value.asDriver().map { Formatters.formatSaleCost(cost: Double($0)) },
            saleCostLCD: fill.dollersDelivered.asDriver().map { Formatters.formatSaleCost(cost: $0)},
            saleQuantityLCD: fill.litersDelivered.asDriver().map { Formatters.formatSaleQuantity(quantity: $0)},
            priceLCD1: priceLCD(notifyPointOfSale.fillActive, fill.price, .one),
            priceLCD2: priceLCD(notifyPointOfSale.fillActive, fill.price, .two),
            priceLCD3: priceLCD(notifyPointOfSale.fillActive, fill.price, .three),
            beep: Signal<Void>.merge(notifyPointOfSale.sBeep, keypad.beep),
            saleComplete: notifyPointOfSale.sSaleComplete)
    }
}

class PresetAmountPumpViewController: UIViewController {
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
        
        let outputs = PresetAmountPump().create(inputs: inputs, disposeBag: disposeBag)

        outputs.saleCostLCD
            .debug()
            .drive(v.dollarsLabel.rx.text)
            .disposed(by: disposeBag)
        outputs.saleQuantityLCD
            .drive(v.litersLabel.rx.text)
            .disposed(by: disposeBag)
        outputs.presetLCD
            .drive(v.presetLabel.rx.text)
            .disposed(by: disposeBag)
        outputs.priceLCD1
            .drive(v.fuelLabels[0].rx.text)
            .disposed(by: disposeBag)
        outputs.priceLCD2
            .drive(v.fuelLabels[1].rx.text)
            .disposed(by: disposeBag)
        outputs.priceLCD3
            .drive(v.fuelLabels[2].rx.text)
            .disposed(by: disposeBag)
        
        outputs.saleComplete
            .map { $0.fuel.description }
            .emit(to: v.fuelLabel.rx.text)
            .disposed(by: disposeBag)
        outputs.saleComplete
            .map { $0.price.description }
            .emit(to: v.priceLabel.rx.text)
            .disposed(by: disposeBag)
        outputs.saleComplete
            .map { $0.cost.description }
            .emit(to: v.dollarsDeliveredLabel.rx.text)
            .disposed(by: disposeBag)
        outputs.saleComplete
            .map { $0.quantity.description }
            .emit(to: v.litersDeliveredLabel.rx.text)
            .disposed(by: disposeBag)
        outputs.saleComplete
            .map { _ -> Bool in false }
            .emit(to: v.saleCompleteView.rx.isHidden)
            .disposed(by: disposeBag)

        clearSale
            .startWith(0)
            .map { _ -> Bool in true}
            .emit(to: v.saleCompleteView.rx.isHidden)
            .disposed(by: disposeBag)
        let delivery = BehaviorRelay<Delivery>(value: .off)
        outputs.delivery.drive(delivery).disposed(by: disposeBag)
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            switch delivery.value {
            case .off:
                break
            default:
                fuelPulsesRelay.accept(20)
            }
        }
    }
}

PlaygroundPage.current.liveView = PresetAmountPumpViewController(nibName: nil, bundle: nil)

//: [Next](@next)
