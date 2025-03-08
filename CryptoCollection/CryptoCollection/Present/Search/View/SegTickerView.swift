//
//  SegTickerView.swift
//  CryptoCollection
//
//  Created by 김태형 on 3/8/25.
//

import UIKit
import SnapKit

final class SegTickerView: BaseView {
    private let label = UILabel()

    override func configureHierarchy() {
        addSubview(label)
    }

    override func configureLayout() {
        label.snp.makeConstraints { make in
            make.center.equalTo(safeAreaLayoutGuide)
        }
    }
    override func configureView() {
        label.text = "거래소 항목은 준비중입니다."
    }
}
