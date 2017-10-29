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
        let red = UIButton(frame: CGRect(x: 10, y: 10, width: 84, height: 44))
        red.setTitle("red", for: .normal)
        red.setTitleColor(.black, for: .normal)
        let green = UIButton(frame: CGRect(x: 94, y: 10, width: 84, height: 44))
        green.setTitle("green", for: .normal)
        green.setTitleColor(.black, for: .normal)
        let label = UILabel(frame: CGRect(x: 10, y: 54, width: 44, height: 44))
        label.textColor = .black
        
        view.addSubview(red)
        view.addSubview(green)
        view.addSubview(label)
        
        let color = BehaviorRelay<String>(value: "")
        Observable
            .merge(
                red.rx.tap.map { _ in "red" },
                green.rx.tap.map { _ in "green" }
            )
            .bind(onNext: color.accept)
            .disposed(by: disposeBag)
        
        color.bind(to: label.rx.text).disposed(by: disposeBag)
    }
}

PlaygroundPage.current.liveView = ViewController(nibName: nil, bundle: nil)

//: [Next](@next)
