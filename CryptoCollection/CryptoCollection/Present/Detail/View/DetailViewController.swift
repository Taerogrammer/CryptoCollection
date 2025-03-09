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

struct Section {
    let name: String
    var items: [Item]
}

struct Information: Equatable {
    let title: String
    let money: String
    let date: String
}

extension Section: SectionModelType {
    typealias Item = Information

    init(original: Section, items: [Information]) {
        self = original
        self.items = items
    }
}

final class DetailViewController: BaseViewController {
    private let viewModel: DetailViewModel
    private let disposeBag = DisposeBag()
    private let titleView = DetailTitleView()
    private let barButton = UIBarButtonItem(
        image: UIImage(systemName: "arrow.left"),
        style: .plain,
        target: nil,
        action: nil)
    private let scrollView = UIScrollView()
    private let containerView = BaseView()
    private let chartView = DetailChartView()
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createCompositionalLayout())

    private var dataSource: RxCollectionViewSectionedReloadDataSource<Section>!

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
        collectionView.layer.cornerRadius = 8
        collectionView.layer.masksToBounds = true
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        collectionView.isScrollEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        configureDataSource()
        bind()
    }

    override func configureNavigation() {
        navigationItem.leftBarButtonItem = barButton
    }

    init(viewModel: DetailViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    private func bind() {
        let input = DetailViewModel.Input(
            barButtonTapped: barButton.rx.tap)
        let output = viewModel.transform(input: input)

        output.action
            .bind(with: self) { owner, action in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)

        output.data
            .withLatestFrom(output.data)
            .bind(with: self) { owner, value in
                owner.titleView.image.kf.setImage(with: URL(string: value.first!.image))
                owner.titleView.id.text = value.first?.symbol.uppercased()
                owner.navigationItem.titleView = owner.titleView
                owner.chartView.moneyLabel.text = value.first?.current_price_description
                // TODO: 메서드 구현 필요
                owner.chartView.rateLabel.text = value.first?.price_change_percentage_24h_description
                // TODO: 메서드 구현 필요
                owner.chartView.updateDateLabel.text = value.first?.last_updated_description
            }
            .disposed(by: disposeBag)

        output.detailData
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

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
        dataSource = RxCollectionViewSectionedReloadDataSource<Section>(
            configureCell: { dataSource, collectionView, indexPath, item in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailCollectionViewCell.identifier, for: indexPath) as! DetailCollectionViewCell

                cell.title.text = item.title
                cell.money.text = item.money
                cell.date.text = item.date

                return cell
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: DetailCollectionHeaderView.identifier,
                    for: indexPath) as! DetailCollectionHeaderView
                header.configureTitle(with: dataSource[indexPath.section].name)

                return header
            }
        )
    }
}
