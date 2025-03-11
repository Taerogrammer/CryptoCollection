//
//  DetailViewController.swift
//  CryptoCollection
//
//  Created by 김태형 on 3/8/25.
//

import UIKit
import Kingfisher
import RxCocoa
import RxDataSources
import RxSwift
import SnapKit
import Toast

import RealmSwift

struct DetailSection {
    let title: String
    var items: [Item]
}

struct DetailInformation: Equatable {
    let title: String
    let money: String
    let date: String
}

extension DetailSection: SectionModelType {
    typealias Item = DetailInformation

    init(original: DetailSection, items: [DetailInformation]) {
        self = original
        self.items = items
    }
}

final class DetailViewController: BaseViewController {
    private let viewModel: DetailViewModel
    private var disposeBag = DisposeBag()
    private let titleView = DetailTitleView()
    private let barButton = UIBarButtonItem(
        image: UIImage(systemName: "arrow.left"),
        style: .plain,
        target: nil,
        action: nil)
    private let favoriteButton = UIBarButtonItem()
    private let scrollView = UIScrollView()
    private let containerView = BaseView()
    private let chartView = DetailChartView()
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createCompositionalLayout())
    private var blueStyle = ToastStyle()
    private var redStyle = ToastStyle()
    private var grayStyle = ToastStyle()

    private var dataSource: RxCollectionViewSectionedReloadDataSource<DetailSection>!

    private let realm = try! Realm()

    init(viewModel: DetailViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(chartView)
        containerView.addSubview(collectionView)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        containerView.snp.makeConstraints { make in
            make.width.equalTo(scrollView.snp.width)
            make.verticalEdges.equalTo(scrollView)
        }
        chartView.snp.makeConstraints { make in
            make.top.width.equalTo(containerView)
            make.height.equalTo(400)
        }
        collectionView.snp.makeConstraints { make in
            make.width.equalTo(containerView)
            make.top.equalTo(chartView.snp.bottom).offset(8)
            make.height.equalTo(480)
            make.bottom.equalTo(containerView).inset(20)
        }
    }

    override func configureView() {
        collectionView.register(DetailCollectionViewCell.self, forCellWithReuseIdentifier: DetailCollectionViewCell.identifier)
        collectionView.register(
            DetailCollectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DetailCollectionHeaderView.identifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        collectionView.isScrollEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        configureDataSource()

        blueStyle.messageColor = UIColor.customBlue
        redStyle.messageColor = UIColor.customRed
        grayStyle.messageColor = UIColor.customBlack
    }

    override func configureNavigation() {
        navigationItem.leftBarButtonItem = barButton
        navigationItem.rightBarButtonItem = favoriteButton
    }

    override func bind() {
        disposeBag = DisposeBag()
        let input = DetailViewModel.Input(
            barButtonTapped: barButton.rx.tap,
            favoriteButtonTapped: favoriteButton.rx.tap)
        let output = viewModel.transform(input: input)

        output.action
            .bind(with: self) { owner, action in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)

        output.data
            .bind(with: self) { owner, response in
                owner.titleView.image.kf.setImage(with: URL(string: response.image))
                owner.titleView.id.text = response.symbol.uppercased()
                owner.navigationItem.titleView = owner.titleView
                owner.chartView.moneyLabel.text = response.current_price_description
                owner.chartView.updateRateLabel(with: response.price_change_percentage_24h_description)
                owner.chartView.updateDateLabel.text = response.last_updated_description
                owner.chartView.configureChartHostingView(with: response.sparkline_in_7d.price)
            }
            .disposed(by: disposeBag)

        output.data
            .bind(with: self) { owner, response in
                owner.updateFavoriteButton(id: response.id)
            }
            .disposed(by: disposeBag)

        output.detailData
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        output.favoriteButtonResult
            .bind(with: self) { owner, action in
                switch action {
                case .popViewController:
                    break
                case .itemAdded:
                    owner.view.makeToast(
                        "즐겨찾기에 추가되었습니다",
                        duration: 2.0,
                        position: .top,
                        style: owner.blueStyle)
                    owner.favoriteButton.image = UIImage(systemName: "star.fill")
                case .itemDeleted:
                    owner.view.makeToast(
                        "즐겨찾기에서 제거되었습니다",
                        duration: 2.0,
                        position: .top,
                        style: owner.redStyle)
                    owner.favoriteButton.image = UIImage(systemName: "star")
                case .itemError:
                    owner.view.makeToast(
                        "다시 한 번 시도해주세요.",
                        duration: 2.0,
                        position: .bottom,
                        style: owner.grayStyle)
                }
            }
            .disposed(by: disposeBag)

        output.error
            .bind(with: self) { owner, error in
                let vc = AlertViewController()
                vc.alertView.messageLabel.text = error.description
                vc.modalPresentationStyle = .overFullScreen
                vc.alertView.retryButton.rx.tap
                    .bind(with: owner) { owner, _ in
                        owner.bind()
                        vc.dismiss(animated: true)
                    }
                    .disposed(by: owner.disposeBag)
                owner.present(vc, animated: true)
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - configure view
extension DetailViewController {
    private func updateFavoriteButton(id: String) {
        let isLiked = realm.objects(FavoriteCoin.self).filter("id == %@", id).first != nil
        favoriteButton.image = UIImage(systemName: isLiked ? "star.fill" : "star")
    }
}

// MARK: - collection view
extension DetailViewController {
    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

            switch sectionIndex {
            case 0: // 종목정보
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute((UIScreen.main.bounds.width - 32) / 2), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [header]

                return section
            case 1: // 투자지표
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(UIScreen.main.bounds.width - 32), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [header]

                return section
            default:
                return nil
            }
        }

        return layout
    }
}

// MARK: - Data Source
extension DetailViewController {
    private func configureDataSource() {
        dataSource = RxCollectionViewSectionedReloadDataSource<DetailSection>(
            configureCell: { dataSource, collectionView, indexPath, item in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailCollectionViewCell.identifier, for: indexPath) as! DetailCollectionViewCell

                cell.title.text = item.title
                cell.money.text = item.money
                cell.date.text = item.date

                return cell
            },
            configureSupplementaryView: { [weak self] dataSource, collectionView, kind, indexPath in
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: DetailCollectionHeaderView.identifier,
                    for: indexPath) as! DetailCollectionHeaderView
                header.configureTitle(with: dataSource[indexPath.section].title)

                header.moreButton.rx.tap
                    .bind { [weak self] _ in
                        self?.view.makeToast(
                            "준비 중입니다",
                            duration: 2.0,
                            position: .bottom)
                    }
                    .disposed(by: self?.disposeBag ?? DisposeBag())

                return header
            }
        )
    }
}
