import Foundation
import RxSwift
import RxCocoa

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
        litersDelivered = AccumulatePulsesPump.accumulate(sClearAccumulator: sClearAccumulator,
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
        let sPrice1 = sStart.asObservable().withLatestFrom(price1) { $0 == .one ? $1 : 0 }.asSignal(onErrorJustReturn: 0)
        let sPrice2 = sStart.asObservable().withLatestFrom(price2) { $0 == .two ? $1 : 0 }.asSignal(onErrorJustReturn: 0)
        let sPrice3 = sStart.asObservable().withLatestFrom(price3) { $0 == .three ? $1 : 0 }.asSignal(onErrorJustReturn: 0)
        let capturedPrice = BehaviorRelay<Double>(value: 0)
        Signal<Double>.merge([sPrice1, sPrice2, sPrice3])
            .emit(onNext: capturedPrice.accept)
            .disposed(by: disposeBag)
        return capturedPrice
    }
}
