import Foundation
import RxSwift
import RxCocoa

class PresetAmountPump: Pump2 {
    func create(inputs: Inputs, disposeBag: DisposeBag) -> Outputs2 {
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
            return ShowDollarsPump.priceLCD(fillActive: fillActive, fillPrice: fillPrice, fuel: fuel, inputs: inputs, disposeBag: disposeBag).asDriver()
        }
        
        return Outputs2(
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
