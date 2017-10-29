//: [Previous](@previous)

import UIKit
import RxSwift
import RxCocoa
import XCPlayground
import PlaygroundSupport

class ViewController: UIViewController {
    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        let plus = UIButton(frame: CGRect(x: 10, y: 10, width: 44, height: 44))
        plus.setTitle("+", for: .normal)
        plus.setTitleColor(.black, for: .normal)
        let minus = UIButton(frame: CGRect(x: 54, y: 10, width: 44, height: 44))
        minus.setTitle("-", for: .normal)
        minus.setTitleColor(.black, for: .normal)
        let label = UILabel(frame: CGRect(x: 10, y: 54, width: 44, height: 44))
        label.textColor = .black
        
        view.addSubview(plus)
        view.addSubview(minus)
        view.addSubview(label)
        
        let value = BehaviorRelay<Int>(value: 0)
        let delta = Observable
            .merge(
                plus.rx.tap.map { _ in 1 },
                minus.rx.tap.map { _ in -1 }
            )
        delta
            .withLatestFrom(value) { ($0, $1) }
            .map { $0 + $1 }
            .bind(onNext: value.accept)
            .disposed(by: disposeBag)
    
        value.map { String($0) }.bind(to: label.rx.text).disposed(by: disposeBag)
        
        // scan版
        /*
        delta
            .scan(0) { $0 + $1 }
            .startWith(0)
            .map { String($0) }
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
         */
    }
}

PlaygroundPage.current.liveView = ViewController(nibName: nil, bundle: nil)

//: [Next](@next)
