//
//  PompView.swift
//  frp-study
//
//  Created by Ichikawa Masaru on 2017/11/11.
//  Copyright © 2017年 masaichi. All rights reserved.
//

import UIKit

public class PompView: UIView {
    @IBOutlet public var numberButtons: [UIButton] = []
    @IBOutlet public var clearButton: UIButton!
    @IBOutlet public var presetLabel: UILabel!
    @IBOutlet public var litersLabel: UILabel!
    @IBOutlet public var dollarsLabel: UILabel!
    @IBOutlet public var fuelLabels: [UILabel] = []
    @IBOutlet public var nozzleButtons: [UIButton] = []
    @IBOutlet public var fuelLabel: UILabel!
    @IBOutlet public var priceLabel: UILabel!
    @IBOutlet public var dollarsDeliveredLabel: UILabel!
    @IBOutlet public var litersDeliveredLabel: UILabel!
    @IBOutlet public var saleOKButton: UIButton!
    @IBOutlet public var saleCompleteView: UIView!

    public static func make() -> PompView {
        let bundle = Bundle(for: PompView.self)
        return bundle.loadNibNamed("PompView", owner: nil, options: [:])![0] as! PompView
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        numberButtons = numberButtons.sorted { $0.tag < $1.tag }
        fuelLabels = fuelLabels.sorted { $0.tag < $1.tag }
        nozzleButtons = nozzleButtons.sorted { $0.tag < $1.tag }
    }
    @IBAction func swapSelected(_ button: UIButton) {
        button.isSelected = !button.isSelected
    }
}
