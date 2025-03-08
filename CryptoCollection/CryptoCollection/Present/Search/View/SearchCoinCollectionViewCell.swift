//
//  CoinCollectionViewCell.swift
//  CryptoCollection
//
//  Created by 김태형 on 3/8/25.
//

import UIKit
import Kingfisher
import SnapKit
import RealmSwift
import RxSwift

final class SearchCoinCollectionViewCell: BaseCollectionViewCell, ReuseIdentifiable {
    private var disposeBag = DisposeBag()
    private let image = CircleImage(frame: .zero)
    private let symbol = UILabel()
    private let name = UILabel()
    private let rank = rankLabel()
    let favorite = UIButton()

    override func configureHierarchy() {
        [image, symbol, name, rank, favorite].forEach { contentView.addSubview($0) }
    }

    override func configureLayout() {
        image.snp.makeConstraints { make in
            make.leading.equalTo(contentView.safeAreaLayoutGuide).inset(24)
            make.size.equalTo(36)
            make.centerY.equalTo(contentView.safeAreaLayoutGuide)
        }
        symbol.snp.makeConstraints { make in
            make.leading.equalTo(image.snp.trailing).offset(20)
            make.centerY.equalTo(contentView.safeAreaLayoutGuide).offset(-8)
        }
        name.snp.makeConstraints { make in
            make.leading.equalTo(symbol)
            make.centerY.equalTo(contentView.safeAreaLayoutGuide).offset(8)
        }
        rank.snp.makeConstraints { make in
            make.leading.equalTo(symbol.snp.trailing).offset(8)
            make.centerY.equalTo(symbol)
        }
        favorite.snp.makeConstraints { make in
            make.trailing.equalTo(contentView.safeAreaLayoutGuide).inset(24)
            make.size.equalTo(20)
            make.centerY.equalTo(contentView.safeAreaLayoutGuide)
        }
    }

    override func configureView() {
        symbol.font = .boldSystemFont(ofSize: 14)
        name.font = .systemFont(ofSize: 12)
        name.textColor = UIColor.customGray
        favorite.setImage(UIImage(systemName: "star"), for: .normal)
        favorite.tintColor = UIColor.customBlack
    }

    // 중첩 구독 방지
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
}


// MARK: - configure cell
extension SearchCoinCollectionViewCell {
    func configureCell(with item: CoinData) {
        image.kf.setImage(with: URL(string: item.thumb))
        symbol.text = item.symbol
        name.text = item.name
        if let rankInt = item.market_cap_rank { rank.text = "#\(rankInt)" }
    }
}
