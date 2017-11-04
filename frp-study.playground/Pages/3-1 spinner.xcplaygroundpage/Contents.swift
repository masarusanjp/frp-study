//: [Previous](@previous)

import UIKit
import RxSwift
import RxCocoa
import XCPlayground
import PlaygroundSupport

class ViewController: UIViewController {
    
    class SpinnerView: UIView {

        private let disposeBag = DisposeBag()
        let value: Observable<Int>
        override init(frame: CGRect) {

            let plusButton = UIButton(type: .roundedRect)
            let minusButton = UIButton(type: .roundedRect)
            let textField = UITextField()
            
            value = textField.rx
                .observe(String.self, "text")
                .map { Int($0 ?? "0") ?? 0 }
                .startWith(0)
            
            super.init(frame: frame)

            addSubview(textField)
            addSubview(plusButton)
            addSubview(minusButton)
            
            plusButton.setTitle("+", for: .normal)
            plusButton.setTitleColor(.black, for: .normal)
            minusButton.setTitle("-", for: .normal)
            minusButton.setTitleColor(.black, for: .normal)
            
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            textField.topAnchor.constraint(equalTo: topAnchor).isActive = true
            textField.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            textField.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5).isActive = true
            
            plusButton.translatesAutoresizingMaskIntoConstraints = false
            plusButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
            plusButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
            plusButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            plusButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5)
            
            minusButton.translatesAutoresizingMaskIntoConstraints = false
            minusButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
            minusButton.topAnchor.constraint(equalTo: plusButton.bottomAnchor).isActive = true
            minusButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            minusButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            let valueLoop = BehaviorRelay<Int>(value: 0)
            let delta = Observable
                .merge(
                    plusButton.rx.tap.map { _ in 1 },
                    minusButton.rx.tap.map { _ in -1 }
            )
            delta
                .withLatestFrom(value) { ($0, $1) }
                .map { $0 + $1 }
                .bind(onNext: valueLoop.accept)
                .disposed(by: disposeBag)
            
            valueLoop
                .map { String($0) }
                .bind(to: textField.rx.text)
                .disposed(by: disposeBag)
        }
        
        required init(coder: NSCoder) {
            fatalError()
        }

        override var intrinsicContentSize: CGSize {
            return CGSize(width: max(bounds.width, 88), height: max(bounds.height, 44))
        }
    }
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        let spinnerView = SpinnerView(frame: CGRect(x: 0, y: 0, width: 88, height: 44))
        view.addSubview(spinnerView)
        spinnerView.value.subscribe(onNext: { debugPrint($0)}).disposed(by: disposeBag)
    }
}

PlaygroundPage.current.liveView = ViewController(nibName: nil, bundle: nil)


//: [Next](@next)
