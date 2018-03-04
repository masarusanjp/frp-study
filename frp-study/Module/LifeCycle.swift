import Foundation
import RxSwift
import RxCocoa

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
