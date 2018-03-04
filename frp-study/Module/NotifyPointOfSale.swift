import Foundation
import RxSwift
import RxCocoa

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

