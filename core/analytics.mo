import Error "mo:base/Error";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import T "../types/dip721_types";

actor class DRC721(_name : Text, _symbol : Text) {
    private stable var tokenPk : Nat = 0;
    private stable var floorPrice: Nat = 0;
    private stable var totalVolume: Nat = 0;
    private stable var ceilingPrice: Nat = 0;

    private stable var tokenCurrentPriceEntries : [(T.TokenId, Nat)] = [];
    private stable var tokenHistoricalPriceEntries : [(T.TokenId, [(Int, Nat)])] = [];
    private stable var tokenAuctionPriceEntries : [(T.TokenId, Nat)] = [];
    private stable var tokenAuctionWinEntries : [(T.TokenId, Nat)] = [];
    private stable var tokenHistoricalHolderEntries: [(T.TokenId, [Principal])] = [];

    private let tokenCurrentPrices : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenCurrentPriceEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenHistoricalPrices : HashMap.HashMap<T.TokenId, [(Int, Nat)]> = HashMap.fromIter<T.TokenId, [(Int, Nat)]>(tokenHistoricalPriceEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenAuctionPrices : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenAuctionPriceEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenAuctionWins : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenAuctionWinEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenHistoricalHolders : HashMap.HashMap<T.TokenId, [Principal]> = HashMap.fromIter<T.TokenId, [Principal]>(tokenHistoricalHolderEntries.vals(), 10, Nat.equal, Hash.hash);
    

    system func preupgrade() {
        tokenCurrentPriceEntries := Iter.toArray(tokenCurrentPrices.entries());
        tokenHistoricalPriceEntries := Iter.toArray(tokenHistoricalPrices.entries());
        tokenAuctionPriceEntries := Iter.toArray(tokenAuctionPrices.entries());
        tokenAuctionWinEntries := Iter.toArray(tokenAuctionWins.entries());
        tokenHistoricalHolderEntries := Iter.toArray(tokenHistoricalHolders.entries());
    };

    system func postupgrade() {
        tokenCurrentPriceEntries := [];
        tokenHistoricalPriceEntries := [];
        tokenAuctionPriceEntries := [];
        tokenAuctionWinEntries := [];
        tokenHistoricalHolderEntries := [];
    };
    
};