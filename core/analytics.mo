import Error "mo:base/Error";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Buffer "../types/Buffer2";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import T "../types/dip721_types";
import Analytics "../types/Analytics";

actor class IVAC721(_name : Text, _symbol : Text) {
    private stable var tokenPk : Nat = 0;
    private stable var floorPrice: Nat = 0;
    private stable var marketCap: Nat = 0;
    private stable var totalVolume: Nat = 0;
    private stable var ceilingPrice: Nat = 0;

    private stable var tokenCurrentPriceEntries : [(T.TokenId, Nat)] = [];
    //Current Prices of all NFTs by Token ID
    private stable var tokenHighestSaleEntries : [(T.TokenId, Nat)] = [];
    //Highest Ever sale of each NFT by Token ID
    private stable var tokenLastSaleEntries : [(T.TokenId, Nat)] = [];
    //Record of Last Sale for Each NFT
    private stable var tokenHistoricalPriceEntries : [(T.TokenId, [(Int, ?Nat)])] = [];
    //Records for Each NFT Price as a Function of Timestamp
    private stable var tokenHistoricalSaleEntries : [(T.TokenId, [(Int, Nat)])] = [];
    //Records for Each NFT Sale as a Function of Timestamp
    private stable var tokenAuctionPriceEntries : [(T.TokenId, Nat)] = [];
    //Auction Quoted Price for Each NFT
    private stable var tokenAuctionWinEntries : [(T.TokenId, Nat)] = [];
    //Winner bids for Each NFT Auction
    private stable var tokenHistoricalHolderEntries: [(T.TokenId, [(Int, Principal)])] = [];
    //Record of All HODLers for Each NFT

    private let tokenCurrentPrices : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenCurrentPriceEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenHighestSales : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenHighestSaleEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenLastSales : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenLastSaleEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenHistoricalPrices : HashMap.HashMap<T.TokenId, [(Int, ?Nat)]> = HashMap.fromIter<T.TokenId, [(Int, ?Nat)]>(tokenHistoricalPriceEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenHistoricalSales : HashMap.HashMap<T.TokenId, [(Int, Nat)]> = HashMap.fromIter<T.TokenId, [(Int, Nat)]>(tokenHistoricalSaleEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenAuctionPrices : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenAuctionPriceEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenAuctionWins : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenAuctionWinEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenHistoricalHolders : HashMap.HashMap<T.TokenId, [(Int, Principal)]> = HashMap.fromIter<T.TokenId, [(Int, Principal)]>(tokenHistoricalHolderEntries.vals(), 10, Nat.equal, Hash.hash);
    

    public shared({caller}) func onSale(by: Principal, id: T.TokenId, price: Nat, newOwner: Principal): async Bool {
        assert _exists(id);
        assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
        let historicalHolders = Option.get(tokenHistoricalHolders.get(id), []);
        if (historicalHolders.size() == 0 or historicalHolders[historicalHolders.size() - 1].1 != by){
            return false;
        };
        let currentPrice = Option.get(tokenCurrentPrices.get(id), 0);
        if (currentPrice == 0 or currentPrice != price){
            return false;
        };

        let _res1 = tokenCurrentPrices.remove(id);
        let _res2 = tokenLastSales.replace(id, price);
        
        let historicalHolderOption = tokenHistoricalHolders.get(id);
        var hist_holders : [Principal] = [];
        switch historicalHolderOption {
            case null {
                tokenHistoricalHolders.put(id, Array.make((Time.now(), newOwner)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), newOwner)));
                let _res3 = tokenHistoricalHolders.replace(id, newArr);
            };
        };
        let historicalPriceOption = tokenHistoricalPrices.get(id);
        var hist_prices : [(Int, Nat)] = [];
        switch historicalPriceOption {
            case null {
                tokenHistoricalPrices.put(id, Array.make((Time.now(), ?price)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), ?price)));
                let _res4 = tokenHistoricalPrices.replace(id, newArr);
            };
        };
        let highestSaleOption = tokenHighestSales.get(id);
        switch highestSaleOption {
            case null {
                tokenHighestSales.put(id, price);
            };
            case (?nat) {
                if (nat < price) {
                    let _res5 = tokenLastSales.replace(id, price);
                };
            };
        };
        let historicalSaleOption = tokenHistoricalSales.get(id);
        var hist_sales : [(Int, Nat)] = [];
        switch historicalSaleOption {
            case null {
                tokenHistoricalSales.put(id, Array.make((Time.now(), price)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), price)));
                let _res4 = tokenHistoricalSales.replace(id, newArr);
            };
        };
        totalVolume += price;
        marketCap -= price;

        reviseFloor();
        reviseCeiling();
        return true;

    };

    public shared({caller}) func onTransfer(by: Principal, id: T.TokenId, newOwner: Principal): async Bool {
        assert _exists(id);
        assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
        let historicalHolders = Option.get(tokenHistoricalHolders.get(id), []);
        if (historicalHolders.size() == 0 or historicalHolders[historicalHolders.size() - 1].1 != by){
            return false;
        };

        let _res1 = tokenCurrentPrices.remove(id);
        switch _res1 {
            case null {};
            case (?nat){
                marketCap -= nat;
            };
        };

        
        let historicalHolderOption = tokenHistoricalHolders.get(id);
        var hist_holders : [Principal] = [];
        switch historicalHolderOption {
            case null {
                tokenHistoricalHolders.put(id, Array.make((Time.now(), newOwner)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), newOwner)));
                let _res2 = tokenHistoricalHolders.replace(id, newArr);
            };
        };
        let historicalPriceOption = tokenHistoricalPrices.get(id);
        var hist_prices : [(Int, Nat)] = [];
        switch historicalPriceOption {
            case null {
                tokenHistoricalPrices.put(id, Array.make((Time.now(), null)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), null)));
                let _res3 = tokenHistoricalPrices.replace(id, newArr);
            };
        };
        
        reviseFloor();
        reviseCeiling();
        
        return true;

    };

    public shared({caller}) func onRelist(by: Principal, id: T.TokenId, newPrice: Nat): async Bool {
        assert _exists(id);
        assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
        let historicalHolders = Option.get(tokenHistoricalHolders.get(id), []);
        if (historicalHolders.size() == 0 or historicalHolders[historicalHolders.size() - 1].1 != by){
            return false;
        };

        var oldPrice = Option.get(tokenCurrentPrices.get(id), 0);
        let _res1 = tokenCurrentPrices.replace(id, newPrice);
        
        
        
        let historicalPriceOption = tokenHistoricalPrices.get(id);
        var hist_prices : [(Int, Nat)] = [];
        switch historicalPriceOption {
            case null {
                tokenHistoricalPrices.put(id, Array.make((Time.now(), ?newPrice)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), ?newPrice)));
                let _res2 = tokenHistoricalPrices.replace(id, newArr);
            };
        };
        
        
        
        marketCap := marketCap + newPrice - oldPrice;
        reviseFloor();
        reviseCeiling();
        return true;
    };

    private func reviseFloor(): () {
        var tokenPrices = Iter.toArray(tokenCurrentPrices.entries());
        var s = tokenPrices.size();
        if (s == 0) {
            floorPrice := 0;
            return;
        };
        var tempFloor = tokenPrices[0].1;
        var i = 1;
        while (i < s) {
            if (tempFloor > tokenPrices[i].1) {
                tempFloor := tokenPrices[i].1;
            };
            i += 1;
        };
        floorPrice := tempFloor;
    };

    private func reviseCeiling(): () {
        var tokenPrices = Iter.toArray(tokenCurrentPrices.entries());
        var s = tokenPrices.size();
        if (s == 0) {
            ceilingPrice := 0;
            return;
        };
        var tempCeiling = tokenPrices[0].1;
        var i = 1;
        while (i < s) {
            if (tempCeiling < tokenPrices[i].1) {
                tempCeiling := tokenPrices[i].1;
            };
            i += 1;
        };
        ceilingPrice := tempCeiling;
    };

    public func onGenesis(mintPrice: Nat, minter: Principal): async Bool {
        tokenPk += 1;
        totalVolume += mintPrice;
        let historicalHolderOption = tokenHistoricalHolders.get(tokenPk);
        var hist_holders : [Principal] = [];
        switch historicalHolderOption {
            case null {
                tokenHistoricalHolders.put(tokenPk, Array.make((Time.now(), minter)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), minter)));
                let _res2 = tokenHistoricalHolders.replace(tokenPk, newArr);
            };
        };
        return true;
    };

    public func getFloor(): async Nat {
        reviseFloor();
        return floorPrice;
    };

    public func getCeiling(): async Nat {
        reviseCeiling();
        return ceilingPrice;
    };

    public func getVolume(): async Nat {
        return totalVolume;
    };

    public func getMktCap(): async Nat {
        return marketCap;
    };

    public func getItemCount(): async Nat {
        return tokenPk;
    };

    public func getMeanPrice(): async ?Float {
        
        var priceArr = Iter.toArray(tokenCurrentPrices.entries());
        var i = 0;
        var s = priceArr.size();
        if (s == 0){
            return null;
        };
        var priceFloat  = Buffer.Buffer2<Float>(s);
        while (i < s) {
            priceFloat.add(Float.fromInt(priceArr[i].1));
            i += 1;
        };
        var priceArrFloat = Buffer.toArray(priceFloat);
        return Analytics.mean(priceArrFloat);
    };

    public func getMedianPrice(): async ?Float {
        
        var priceArr = Iter.toArray(tokenCurrentPrices.entries());
        var i = 0;
        var s = priceArr.size();
        if (s == 0){
            return null;
        };
        var priceFloat  = Buffer.Buffer2<Float>(s);
        while (i < s) {
            priceFloat.add(Float.fromInt(priceArr[i].1));
            i += 1;
        };
        var priceArrFloat = Buffer.toArray(priceFloat);
        return Analytics.median(priceArrFloat);
    };
    

    private func _exists(tokenId : Nat) : Bool {
        return (tokenPk >= tokenId);
    };


    system func preupgrade() {
        tokenCurrentPriceEntries := Iter.toArray(tokenCurrentPrices.entries());
        tokenHighestSaleEntries := Iter.toArray(tokenHighestSales.entries());
        tokenLastSaleEntries := Iter.toArray(tokenLastSales.entries());
        tokenHistoricalPriceEntries := Iter.toArray(tokenHistoricalPrices.entries());
        tokenHistoricalSaleEntries := Iter.toArray(tokenHistoricalSales.entries());
        tokenAuctionPriceEntries := Iter.toArray(tokenAuctionPrices.entries());
        tokenAuctionWinEntries := Iter.toArray(tokenAuctionWins.entries());
        tokenHistoricalHolderEntries := Iter.toArray(tokenHistoricalHolders.entries());
    };

    system func postupgrade() {
        tokenCurrentPriceEntries := [];
        tokenHighestSaleEntries := [];
        tokenLastSaleEntries := [];
        tokenHistoricalPriceEntries := [];
        tokenHistoricalSaleEntries:= [];
        tokenAuctionPriceEntries := [];
        tokenAuctionWinEntries := [];
        tokenHistoricalHolderEntries := [];
    };
    
};