//
//  DetailViewModel.swift
//  CryptoCollection
//
//  Created by 김태형 on 3/8/25.
//

import RealmSwift
import RxCocoa
import RxSwift

final class DetailViewModel: ViewModel {
    private let disposeBag = DisposeBag()
    private let id: Observable<String>
    private let realm = try! Realm()

    enum SettingAction {
        case popViewController
        case itemAdded
        case itemDeleted
        case itemError
    }

    struct Input {
        let barButtonTapped: ControlEvent<Void>
        let favoriteButtonTapped: ControlEvent<Void>
        
    }

    struct Output {
        let action: PublishRelay<SettingAction>
        let data: Observable<CoingeckoCoinResponse>
        let detailData: PublishRelay<[DetailSection]>
        let favoriteButtonResult: PublishRelay<SettingAction>
    }

    init(id: String) {
        self.id = Observable.just(id)
    }

    func transform(input: Input) -> Output {
        let action = PublishRelay<SettingAction>()
        let result = PublishRelay<CoingeckoCoinResponse>()
        let detailResult = PublishRelay<[DetailSection]>()
        let favoriteButtonResult = PublishRelay<SettingAction>()

        input.barButtonTapped
            .bind(with: self) { owner, _ in
                action.accept(SettingAction.popViewController)
            }
            .disposed(by: disposeBag)

        id
            .flatMapLatest { id -> Single<[CoingeckoCoinResponse]> in
                return NetworkManager.shared.getItem(
                    api: CoingeckoRouter.getCoinInformation(ids: id),
                    type: [CoingeckoCoinResponse].self)
            }
            .bind(with: self) { owner, data in
                guard let data = data.first else {
                    print("no Data")
                    return
                }
                result.accept(data)
            }
            .disposed(by: disposeBag)

        result
            .bind(with: self) { owner, response in
                detailResult.accept([
                    DetailSection(title: "종목정보", items: [
                        DetailInformation(title: "24시간 고가", money: response.high_24h_description, date: ""),
                        DetailInformation(title: "24시간 저가", money: response.low_24h_description, date: ""),
                        DetailInformation(title: "역대 최고가", money: response.ath_description, date: response.ath_date_description),
                        DetailInformation(title: "역대 최소가", money: response.atl_description, date: response.atl_date_description)
                    ]),
                    DetailSection(title: "투자지표", items: [
                        DetailInformation(title: "시가총액", money: response.market_cap_description, date: ""),
                        DetailInformation(title: "완전 희석 가치(FDV)", money: response.fully_diluted_valuation_description, date: ""),
                        DetailInformation(title: "총 거래량", money: response.total_volume_description, date: "")
                    ])
                ])
            }
            .disposed(by: disposeBag)

        //TODO: 레포지토리 패턴으로 변경
//        input.favoriteButtonTapped
//            .bind(with: self) { owner, _ in
//                let realm = owner.realm
//
//                owner.coinData
//                    .bind(with: self) { owner, data in
//                        if let deletedItem = realm.objects(FavoriteCoin.self)
//                            .filter("id == %@", data.id)
//                            .first {
//                            do {
//                                // Realm Delete
//                                try realm.write {
//                                    realm.delete(deletedItem)
//                                    favoriteButtonResult.accept(.itemDeleted)
//                                }
//                            } catch {
//                                favoriteButtonResult.accept(.itemError)
//                            }
//                        } else {
//                            do {
//                                try realm.write {
//                                    let favoriteData = FavoriteCoin(
//                                        id: data.id,
//                                        name: data.name,
//                                        symbol: data.symbol,
//                                        market_cap_rank: data.market_cap_rank,
//                                        thumb: data.thumb)
//                                    realm.add(favoriteData)
//                                    favoriteButtonResult.accept(.itemAdded)
//                                }
//                            } catch {
//                                favoriteButtonResult.accept(.itemError)
//                            }
//                        }
//                    }
//                    .disposed(by: owner.disposeBag)
//            }
//            .disposed(by: disposeBag)

        return Output(
            action: action,
            data: result.asObservable(),
            detailData: detailResult,
            favoriteButtonResult: favoriteButtonResult)
    }
}
