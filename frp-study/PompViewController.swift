import UIKit
import RxSwift
import RxCocoa
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
    let disposeBag: DisposeBag
    
    init(delivery: BehaviorRelay<Delivery> = BehaviorRelay(value: .off),
         presetLCD: BehaviorRelay<String> = BehaviorRelay(value: ""),
         saleCostLCD: BehaviorRelay<String> = BehaviorRelay(value: ""),
         saleQuantityLCD: BehaviorRelay<String> = BehaviorRelay(value: ""),
         priceLCD1: BehaviorRelay<String> = BehaviorRelay(value: ""),
         priceLCD2: BehaviorRelay<String> = BehaviorRelay(value: ""),
         priceLCD3: BehaviorRelay<String> = BehaviorRelay(value: ""),
         beep: Signal<Void> = .empty(),
         saleComplete: Signal<Sale> = .empty(),
         disposeBag: DisposeBag = DisposeBag()
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
        self.disposeBag = DisposeBag()
    }
}

enum Fuel {
    case one, two, three
}

class LifeCycle {
    enum End {
        case end
    }
    let start: Signal<Fuel>
    let end: Signal<End>
    let fillActive: BehaviorRelay<Fuel?>
    let disposeBag: DisposeBag
    
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
    init(nozzle1: Signal<UpDown>, nozzle2: Signal<UpDown>, nozzle3: Signal<UpDown>) {
        let disposeBag = DisposeBag()
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
        self.disposeBag = disposeBag
        self.fillActive = fillActive
    }
}

class LifeCyclePump {
    static func make(inputs: Inputs) -> Outputs {
        let disposeBag = DisposeBag()
        let lifeCycle = LifeCycle(nozzle1: inputs.nozzle1, nozzle2: inputs.nozzle2, nozzle3: inputs.nozzle3)
        let delivery = BehaviorRelay<Delivery>(value: .off)
        lifeCycle.fillActive
            .map {
                switch $0 {
                case .some(.one):
                    return Delivery.fast1
                case .some(.two):
                    return Delivery.fast2
                case .some(.three):
                    return Delivery.fast3
                case .none:
                    return Delivery.off
                }
            }
            .bind(onNext: delivery.accept)
            .disposed(by: disposeBag)
        
        let quantityLCD = BehaviorRelay<String>(value: "")
        
        let quantityLCD: Driver<String> = lifeCycle.fillActive
            .map {
                switch $0 {
                case .some(.one):
                    return "1"
                case .some(.two):
                    return "2"
                case .some(.three):
                    return "3"
                case .none:
                    return ""
                }
            }
            .asDriver(onErrorDriveWith: .empty())
        
        return Outputs(delivery: delivery,
                       presetLCD: BehaviorRelay<String>(value: ""),
                       saleCostLCD: BehaviorRelay<String>(value: ""),
                       saleQuantityLCD: quantityLCD,
                       priceLCD1: BehaviorRelay<String>(value: ""),
                       priceLCD2: BehaviorRelay<String>(value: ""),
                       priceLCD3: BehaviorRelay<String>(value: ""),
                       beep: .empty(),
                       saleComplete: .empty())
    }

}

class PompViewController: UIViewController {
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
                .map { ($0 ?? false) ? UpDown.up : UpDown.down }
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
