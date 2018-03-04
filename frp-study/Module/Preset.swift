import Foundation
import RxSwift
import RxCocoa

/*
 0は指定金額が入力されていないことを意味する
 指定金額に近づいたら給油の速度を落とし始める
 指定金額に達したら給油を止める
 給油の速度を落とす前であれば、ユーザーはいつでも指定金額を変更できる。給油の速度が遅くなった自転で、キーパッドがロックされる
 */

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
