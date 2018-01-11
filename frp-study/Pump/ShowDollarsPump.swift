import Foundation
import RxSwift
import RxCocoa

class ShowDollarsPump: Pump {
    func create(inputs: Inputs, disposeBag: DisposeBag) -> Outputs {
        let lc = LifeCycle(nozzle1: inputs.nozzle1,
                           nozzle2: inputs.nozzle2,
                           nozzle3: inputs.nozzle3)
        let fill = Fill(sClearAccumulator: lc.start.map { _ in },
                        sFuelPulses: inputs.fuelPulses,
                        calibration: inputs.calibration,
                        price1: inputs.price1,
                        price2: inputs.price2,
                        price3: inputs.price3,
                        sStart: lc.start,
                        disposeBag: disposeBag)
        let delivery = lc.fillActive.map { fuel -> Delivery in
            switch fuel {
            case .some(.one):
                return .fast1
            case .some(.two):
                return .fast2
            case .some(.three):
                return .fast3
            case .none:
                return .off
            }
            }
            .asDriver(onErrorDriveWith: .empty())

        let deliveryCell = BehaviorRelay<Delivery>(value: .off)
        delivery.drive(deliveryCell).disposed(by: disposeBag)

        let saleCostLCD = BehaviorRelay<String>(value: "")
        fill.dollersDelivered.map { Formatters.formatSaleCost(cost: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(saleCostLCD).disposed(by: disposeBag)

        let saleQuantityLCD = BehaviorRelay<String>(value: "")
        fill.litersDelivered.map { Formatters.formatSaleQuantity(quantity: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(saleQuantityLCD).disposed(by: disposeBag)


        let priceLCD1 = ShowDollarsPump.priceLCD(fillActive: lc.fillActive,
                                                 fillPrice: fill.price,
                                                 fuel: .one,
                                                 inputs: inputs,
                                                 disposeBag: disposeBag)
        let priceLCD2 = ShowDollarsPump.priceLCD(fillActive: lc.fillActive,
                                                 fillPrice: fill.price,
                                                 fuel: .two,
                                                 inputs: inputs,
                                                 disposeBag: disposeBag)
        let priceLCD3 = ShowDollarsPump.priceLCD(fillActive: lc.fillActive,
                                                 fillPrice: fill.price,
                                                 fuel: .three,
                                                 inputs: inputs,
                                                 disposeBag: disposeBag)

        return Outputs(delivery: deliveryCell,
                       saleCostLCD: saleCostLCD,
                       saleQuantityLCD: saleQuantityLCD,
                       priceLCD1: priceLCD1,
                       priceLCD2: priceLCD2,
                       priceLCD3: priceLCD3
        )
    }

    static func priceLCD(fillActive: BehaviorRelay<Fuel?>,
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
}
