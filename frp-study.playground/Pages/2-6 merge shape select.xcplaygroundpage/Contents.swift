//: [Previous](@previous)

import Foundation
import UIKit
import RxSwift
import RxCocoa
import XCPlayground
import PlaygroundSupport

var str = "Hello, playground"

class Frp2_6MergeViewController: UIViewController {
    let triangle = UILabel()
    let hexagon = UILabel()
    let disposeBag = DisposeBag()
    enum ShapeID {
        case triangle
        case hexagon
    }
    enum Change {
        case selected([ShapeID])
        case deSelected([ShapeID])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view: UIView! = self.view
        let triangle = self.triangle
        let hexagon = self.hexagon
        
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        triangle.frame = CGRect(x: 10, y: 10, width: 120, height: 44)
        triangle.text = "triangle"
        triangle.layer.borderWidth = 1.0
        hexagon.frame = CGRect(x: 140, y: 10, width: 120, height: 44)
        hexagon.layer.borderWidth = 1.0
        hexagon.text = "hexagon"
        view.addSubview(triangle)
        view.addSubview(hexagon)
        
        let gestureRecognizer = UITapGestureRecognizer()
        view.addGestureRecognizer(gestureRecognizer)

        let tappedOrigin = gestureRecognizer.rx.event
            .map { $0.location(in: view) }
        
        let selectedShapes = BehaviorSubject<Set<ShapeID>>(value: Set<ShapeID>())
        let selected = tappedOrigin
            .map { point -> [ShapeID] in
                if triangle.frame.contains(point) {
                    return [ShapeID.triangle]
                }
                if hexagon.frame.contains(point) {
                    return [ShapeID.hexagon]
                }
                return []
            }
            .filter { !$0.isEmpty }
        let deSelected = tappedOrigin
            .map { point -> [ShapeID] in
                var result: [ShapeID] = []
                if !triangle.frame.contains(point) {
                    result.append(ShapeID.triangle)
                }
                if !hexagon.frame.contains(point) {
                    result.append(ShapeID.hexagon)
                }
                return result
            }
            .withLatestFrom(selectedShapes) { ($0, $1) }
            .map { shapes, selectedShapes in shapes.filter { selectedShapes.contains($0) } }
            .filter { !$0.isEmpty }
        let changes = Observable.merge(deSelected.map { Change.deSelected($0) },
                                       selected.map { Change.selected($0) })
        
        changes
            .debug()
            .scan(Set<ShapeID>()) { set, change -> Set<ShapeID> in
                var result = set
                switch change {
                case let .selected(shapes):
                    shapes.forEach { result.insert($0) }
                case let .deSelected(shapes):
                    shapes.forEach { result.remove($0) }
                }
                return result
            }
            .bind(to: selectedShapes)
            .disposed(by: disposeBag)
        let triangleColor = selectedShapes.map { $0.contains(ShapeID.triangle) ? UIColor.green : UIColor.white }
        let hexagonColor = selectedShapes.map { $0.contains(ShapeID.hexagon) ? UIColor.green : UIColor.white }
        triangleColor
            .subscribe(onNext: {
                triangle.backgroundColor = $0
            })
            .disposed(by: disposeBag)
        hexagonColor
            .subscribe(onNext: {
                hexagon.backgroundColor = $0
            })
            .disposed(by: disposeBag)

    }
}

PlaygroundPage.current.liveView = Frp2_6MergeViewController(nibName: nil, bundle: nil)

//: [Next](@next)
