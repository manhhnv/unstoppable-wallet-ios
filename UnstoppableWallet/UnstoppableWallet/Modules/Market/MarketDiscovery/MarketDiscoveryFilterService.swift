import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketDiscoveryFilterService {
    private let marketKit: MarketKit.Kit
    private let favoritesManager: FavoritesManager

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let successRelay = PublishRelay<FavoriteState>()

    init(marketKit: MarketKit.Kit, favoritesManager: FavoritesManager) {
        self.marketKit = marketKit
        self.favoritesManager = favoritesManager
    }

    private func coinUid(index: Int) -> String? {
        guard case .searchResults(let fullCoins) = state, index < fullCoins.count else {
            return nil
        }

        return fullCoins[index].coin.uid
    }

}

extension MarketDiscoveryFilterService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var successObservable: Observable<FavoriteState> {
        successRelay.asObservable()
    }

    func set(filter: String) {
        if filter.isEmpty {
            state = .idle
        } else {
            do {
                state = .searchResults(fullCoins: try marketKit.fullCoins(filter: filter))
            } catch {
                state = .searchResults(fullCoins: [])
            }
        }
    }

    func isFavorite(index: Int) -> Bool {
        guard let coinUid = coinUid(index: index) else {
            return false
        }

        return favoritesManager.isFavorite(coinUid: coinUid)
    }

    func favorite(index: Int) {
        guard let coinUid = coinUid(index: index) else {
            successRelay.accept(.fail)
            return
        }

        favoritesManager.add(coinUid: coinUid)
        successRelay.accept(.favorited)
    }

    func unfavorite(index: Int) {
        guard let coinUid = coinUid(index: index) else {
            successRelay.accept(.fail)
            return
        }

        favoritesManager.remove(coinUid: coinUid)
        successRelay.accept(.unfavorited)
    }

}

extension MarketDiscoveryFilterService {

    enum State {
        case idle
        case searchResults(fullCoins: [FullCoin])
    }

    enum FavoriteState {
        case favorited
        case unfavorited
        case fail
    }

}
