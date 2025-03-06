//
//  CoingeckoTrending.swift
//  CryptoCollection
//
//  Created by 김태형 on 3/6/25.
//

import Foundation

struct CoingeckoTrendingResponse: Decodable {
    let coins: [Item]
    let nfts: [Nft]
}

struct Item: Decodable {
    let item: Coin
}

struct Coin: Decodable {
    let id: String
    let symbol: String
    let name: String
    let thumb: String
    let score: Int
    let data: PriceChangePercentage
}

struct PriceChangePercentage: Decodable {
    let price_change_percentage_24h: KrwChangePercentage
}

struct KrwChangePercentage: Decodable {
    let krw: Double
}

struct Nft: Decodable {
    let id: String
    let name: String
    let thumb: String
    let data: NftData
}

struct NftData: Decodable {
    let floor_price: String
    let floor_price_in_usd_24h_percentage_change: String
}
