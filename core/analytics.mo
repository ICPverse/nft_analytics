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
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import T "../types/dip721_types";
import Analytics "../types/Analytics";
import Prelude "mo:base/Prelude";

actor class IVAC721(_name : Text, _symbol : Text) {
    private stable var tokenPk : Nat = 0;
    private stable var floorPrice: Nat = 0;
    private stable var marketCap: Float = 0.0;
    private stable var totalVolume: Nat = 0;
    private stable var ceilingPrice: Nat = 0;

    private stable var tokenCurrentPriceEntries : [(T.TokenId, Nat)] = [];
    // Current Prices of all NFTs by Token ID
    private stable var tokenHighestSaleEntries : [(T.TokenId, Nat)] = [];
    // Highest Ever sale of each NFT by Token ID
    private stable var tokenLastSaleEntries : [(T.TokenId, Nat)] = [];
    // Record of Last Sale for Each NFT
    private stable var tokenHistoricalPriceEntries : [(T.TokenId, [(Int, ?Nat)])] = [];
    // Records for Each NFT Price as a Function of Timestamp
    private stable var tokenHistoricalSaleEntries : [(T.TokenId, [(Int, Nat)])] = [];
    // Records for Each NFT Sale as a Function of Timestamp
    private stable var tokenAuctionPriceEntries : [(T.TokenId, Nat)] = [];
    // Auction Quoted Price for Each NFT
    private stable var tokenAuctionWinningEntries : [(T.TokenId, (Principal, Nat))] = [];
    // Winner bids for Each NFT Auction
    private stable var tokenHistoricalHolderEntries: [(T.TokenId, [(Int, Principal)])] = [];
    // Record of All HODLers for Each NFT
    private stable var dynamicListingEntries: [(T.TokenId, Nat)] = [];
    // Records for the dynamic Listing status of each NFT in the collection
    private stable var dynamicAuctionEntries: [(T.TokenId, Nat)] = [];
    // Records for the dynamic Auction status of each NFT in the collection
    // Codes pertaining to Dynamic Listing/Auction:
    /* 
        0: disabled
        1: floor price
        2: mean price
        3: median price
        4: ceiling price
    */

    private let tokenCurrentPrices : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenCurrentPriceEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenHighestSales : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenHighestSaleEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenLastSales : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenLastSaleEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenHistoricalPrices : HashMap.HashMap<T.TokenId, [(Int, ?Nat)]> = HashMap.fromIter<T.TokenId, [(Int, ?Nat)]>(tokenHistoricalPriceEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenHistoricalSales : HashMap.HashMap<T.TokenId, [(Int, Nat)]> = HashMap.fromIter<T.TokenId, [(Int, Nat)]>(tokenHistoricalSaleEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenAuctionPrices : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(tokenAuctionPriceEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenAuctionWinning : HashMap.HashMap<T.TokenId, (Principal, Nat)> = HashMap.fromIter<T.TokenId, (Principal, Nat)>(tokenAuctionWinningEntries.vals(), 10, Nat.equal, Hash.hash);
    private let tokenHistoricalHolders : HashMap.HashMap<T.TokenId, [(Int, Principal)]> = HashMap.fromIter<T.TokenId, [(Int, Principal)]>(tokenHistoricalHolderEntries.vals(), 10, Nat.equal, Hash.hash);
    private let dynamicListings : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(dynamicListingEntries.vals(), 10, Nat.equal, Hash.hash);
    private let dynamicAuctions : HashMap.HashMap<T.TokenId, Nat> = HashMap.fromIter<T.TokenId, Nat>(dynamicAuctionEntries.vals(), 10, Nat.equal, Hash.hash);
  

    public shared({caller}) func onSale(by: Principal, id: T.TokenId, price: Nat, newOwner: Principal): async Bool {
        assert _exists(id);
        //assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
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
                    Debug.print(debug_show nat);
                    Debug.print(debug_show price);
                    let _res5 = tokenHighestSales.replace(id, price);
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

        let _res5 = dynamicAuctions.remove(id);
        let _res6 = dynamicListings.remove(id);

        totalVolume += price;
        
        reviseFloor();
        reviseCeiling();
        //marketCap -= Float.fromInt(price);
        await reviseMcap();
        return true;

    };

    public shared({caller}) func onDynamicSale(by: Principal, id: T.TokenId, price: Nat, newOwner: Principal): async Bool {
        assert _exists(id);
        assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
        let historicalHolders = Option.get(tokenHistoricalHolders.get(id), []);
        if (historicalHolders.size() == 0 or historicalHolders[historicalHolders.size() - 1].1 != by){
            return false;
        };
        
        let code = Option.get(dynamicListings.get(id), 0);
        assert (code != 0);

        let currentPrice: Float = switch code {
            case 1 Float.fromInt(floorPrice);
            case 2 Option.get(await getMeanPrice(), 0.00);
            case 3 Option.get(await getMedianPrice(), 0.0);
            case 4 Float.fromInt(ceilingPrice);
            case _ 0.00; 
        };
        if (currentPrice == 0.00 or not (currentPrice <= Float.fromInt(price) and currentPrice + 1.00 > Float.fromInt(price))){
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
                    let _res5 = tokenHighestSales.replace(id, price);
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

        let _res5 = dynamicAuctions.remove(id);
        let _res6 = dynamicListings.remove(id);

        totalVolume += price;
        
        reviseFloor();
        reviseCeiling();
        //marketCap -= Float.fromInt(price);
        await reviseMcap();
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
                marketCap -= Float.fromInt(nat);
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

        let _res4 = dynamicAuctions.remove(id);
        let _res5 = dynamicListings.remove(id);
        
        
        reviseFloor();
        reviseCeiling();
        await reviseMcap();
        return true;

    };

    public shared({caller}) func onAuctionCreate(by: Principal, id: T.TokenId, minPrice: Nat): async Bool {
        assert _exists(id);
        assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
        let historicalHolders = Option.get(tokenHistoricalHolders.get(id), []);
        if (historicalHolders.size() == 0 or historicalHolders[historicalHolders.size() - 1].1 != by){
            return false;
        };
        tokenAuctionPrices.put(id, minPrice);
        tokenAuctionWinning.put(id, (by, 0));
        let _res1 = dynamicAuctions.remove(id);
        let _res2 = dynamicListings.remove(id);
        return true;
    };

    public shared({caller}) func onDynamicAuctionCreate(by: Principal, id: T.TokenId, code: Nat): async Bool {
        assert _exists(id);
        assert (code == 1 or code == 2 or code == 3 or code == 4);
        assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
        let historicalHolders = Option.get(tokenHistoricalHolders.get(id), []);
        if (historicalHolders.size() == 0 or historicalHolders[historicalHolders.size() - 1].1 != by){
            return false;
        };
        let _res1 = dynamicAuctions.replace(id, code);
        let _res2 = tokenAuctionPrices.remove(id);
        tokenAuctionWinning.put(id, (by, 0));
        let _res3 = dynamicListings.remove(id);
        return true;
    };

    public shared({caller}) func onAuctionApply(by: Principal, id: T.TokenId, quotePrice: Nat): async Bool {
        assert _exists(id);
        assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
        let minPrice = Option.get(tokenAuctionPrices.get(id), 0);
        assert (minPrice != 0);
        let historicalHolders = Option.get(tokenHistoricalHolders.get(id), []);
        if (historicalHolders.size() == 0 or historicalHolders[historicalHolders.size() - 1].1 == by){
            return false;
        };
        let currentNominee = Option.get(tokenAuctionWinning.get(id), (Principal.fromText("2vxsx-fae"), 0));
        if (currentNominee.0 == Principal.fromText("2vxsx-fae")){
            return false;
        }
        else if (currentNominee.1 < quotePrice and quotePrice > minPrice) {
            tokenAuctionWinning.put(id, (by, quotePrice));
        };
        
        await reviseMcap();
        return (quotePrice > minPrice);
    };

    public shared({caller}) func onDynamicAuctionApply(by: Principal, id: T.TokenId, quotePrice: Nat): async Bool {
        assert _exists(id);
        assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
        let code = Option.get(dynamicAuctions.get(id), 0);
        assert (code != 0);
        let minPrice: Float = switch code {
            case 1 Float.fromInt(floorPrice);
            case 2 Option.get(await getMeanPrice(), 0.00);
            case 3 Option.get(await getMedianPrice(), 0.0);
            case 4 Float.fromInt(ceilingPrice);
            case _ 0.00; 
        };
        assert (minPrice != 0.0);
        let historicalHolders = Option.get(tokenHistoricalHolders.get(id), []);
        if (historicalHolders.size() == 0 or historicalHolders[historicalHolders.size() - 1].1 == by){
            return false;
        };
        let currentNominee = Option.get(tokenAuctionWinning.get(id), (Principal.fromText("2vxsx-fae"), 0));
        if (currentNominee.0 == Principal.fromText("2vxsx-fae")){
            return false;
        }
        else if (currentNominee.1 < quotePrice and Float.fromInt(quotePrice) > minPrice) {
            tokenAuctionWinning.put(id, (by, quotePrice));
        };
        
        await reviseMcap();
        return (Float.fromInt(quotePrice) > minPrice);
    };

    public shared({caller}) func onAuctionEnd(by: Principal, id: T.TokenId): async Bool {
        assert _exists(id);
        assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
        let historicalHolders = Option.get(tokenHistoricalHolders.get(id), []);
        if (historicalHolders.size() == 0 or historicalHolders[historicalHolders.size() - 1].1 != by){
            return false;
        };
        let minPrice = Option.get(tokenAuctionPrices.get(id), 0);
        let winner = Option.get(tokenAuctionWinning.get(id), (Principal.fromText("2vxsx-fae"), 0));
        if (winner.1 == 0 or minPrice == 0){
            return false;
        };
        assert (winner.1 > minPrice);
        

        let _res1 = tokenCurrentPrices.remove(id);
        let _res2 = tokenLastSales.replace(id, winner.1);
        
        let historicalHolderOption = tokenHistoricalHolders.get(id);
        var hist_holders : [Principal] = [];
        switch historicalHolderOption {
            case null {
                tokenHistoricalHolders.put(id, Array.make((Time.now(), winner.0)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), winner.0)));
                let _res3 = tokenHistoricalHolders.replace(id, newArr);
            };
        };
        let historicalPriceOption = tokenHistoricalPrices.get(id);
        var hist_prices : [(Int, Nat)] = [];
        switch historicalPriceOption {
            case null {
                tokenHistoricalPrices.put(id, Array.make((Time.now(), ?winner.1)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), ?winner.1)));
                let _res4 = tokenHistoricalPrices.replace(id, newArr);
            };
        };
        let highestSaleOption = tokenHighestSales.get(id);
        switch highestSaleOption {
            case null {
                tokenHighestSales.put(id, winner.1);
            };
            case (?nat) {
                if (nat < winner.1) {
                    let _res5 = tokenHighestSales.replace(id, winner.1);
                };
            };
        };
        let historicalSaleOption = tokenHistoricalSales.get(id);
        var hist_sales : [(Int, Nat)] = [];
        switch historicalSaleOption {
            case null {
                tokenHistoricalSales.put(id, Array.make((Time.now(), winner.1)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), winner.1)));
                let _res4 = tokenHistoricalSales.replace(id, newArr);
            };
        };

        let _res5 = dynamicAuctions.remove(id);
        let _res6 = dynamicListings.remove(id);
        let _res7 = tokenAuctionPrices.remove(id);
        let _res8 = tokenAuctionWinning.remove(id);

        totalVolume += winner.1;
        
        
        reviseFloor();
        reviseCeiling();
        await reviseMcap();
        return true;

    };

    public shared({caller}) func onDynamicAuctionEnd(by: Principal, id: T.TokenId): async Bool {
        assert _exists(id);
        assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
        let historicalHolders = Option.get(tokenHistoricalHolders.get(id), []);
        if (historicalHolders.size() == 0 or historicalHolders[historicalHolders.size() - 1].1 != by){
            return false;
        };

        let code = Option.get(dynamicAuctions.get(id), 0);
        assert (code != 0);
        let minPrice: Float = switch code {
            case 1 Float.fromInt(floorPrice);
            case 2 Option.get(await getMeanPrice(), 0.00);
            case 3 Option.get(await getMedianPrice(), 0.0);
            case 4 Float.fromInt(ceilingPrice);
            case _ 0.00; 
        };
        assert (minPrice != 0.0);
        
        let winner = Option.get(tokenAuctionWinning.get(id), (Principal.fromText("2vxsx-fae"), 0));
        if (winner.1 == 0 or minPrice == 0){
            return false;
        };
        assert (Float.fromInt(winner.1) > minPrice);
        

        let _res1 = tokenCurrentPrices.remove(id);
        let _res2 = tokenLastSales.replace(id, winner.1);
        
        let historicalHolderOption = tokenHistoricalHolders.get(id);
        var hist_holders : [Principal] = [];
        switch historicalHolderOption {
            case null {
                tokenHistoricalHolders.put(id, Array.make((Time.now(), winner.0)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), winner.0)));
                let _res3 = tokenHistoricalHolders.replace(id, newArr);
            };
        };
        let historicalPriceOption = tokenHistoricalPrices.get(id);
        var hist_prices : [(Int, Nat)] = [];
        switch historicalPriceOption {
            case null {
                tokenHistoricalPrices.put(id, Array.make((Time.now(), ?winner.1)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), ?winner.1)));
                let _res4 = tokenHistoricalPrices.replace(id, newArr);
            };
        };
        let highestSaleOption = tokenHighestSales.get(id);
        switch highestSaleOption {
            case null {
                tokenHighestSales.put(id, winner.1);
            };
            case (?nat) {
                if (nat < winner.1) {
                    let _res5 = tokenHighestSales.replace(id, winner.1);
                };
            };
        };
        let historicalSaleOption = tokenHistoricalSales.get(id);
        var hist_sales : [(Int, Nat)] = [];
        switch historicalSaleOption {
            case null {
                tokenHistoricalSales.put(id, Array.make((Time.now(), winner.1)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), winner.1)));
                let _res4 = tokenHistoricalSales.replace(id, newArr);
            };
        };

        let _res5 = dynamicAuctions.remove(id);
        let _res6 = dynamicListings.remove(id);
        let _res7 = tokenAuctionPrices.remove(id);
        let _res8 = tokenAuctionWinning.remove(id);

        totalVolume += winner.1;
        
        
        reviseFloor();
        reviseCeiling();
        await reviseMcap();
        return true;

    };

    public shared({caller}) func onRelist(by: Principal, id: T.TokenId, newPrice: Nat): async Bool {
        assert _exists(id);
        //assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
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
        
        
        let _res3 = dynamicAuctions.remove(id);
        let _res4 = dynamicListings.remove(id);
        
        reviseFloor();
        reviseCeiling();
        //marketCap := marketCap + Float.fromInt(newPrice) - Float.fromInt(oldPrice);
        await reviseMcap();
        return true;
    };

    public shared({caller}) func onDynamicRelist(by: Principal, id: T.TokenId, code: Nat): async Bool {
        assert _exists(id);
        assert (caller == Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"));
        assert (code == 1 or code == 2 or code == 3 or code == 4);
        let historicalHolders = Option.get(tokenHistoricalHolders.get(id), []);
        if (historicalHolders.size() == 0 or historicalHolders[historicalHolders.size() - 1].1 != by){
            return false;
        };
        
        var oldPrice = Option.get(tokenCurrentPrices.get(id), 0);
        let _res1 = tokenCurrentPrices.remove(id);
        
        
        
        let historicalPriceOption = tokenHistoricalPrices.get(id);
        var hist_prices : [(Int, Nat)] = [];
        switch historicalPriceOption {
            case null {
                tokenHistoricalPrices.put(id, Array.make((Time.now(), null)));
            };
            case (?arr) {
                var newArr = Array.append(arr, Array.make((Time.now(), null)));
                let _res2 = tokenHistoricalPrices.replace(id, newArr);
            };
        };
        
        
        let _res3 = dynamicAuctions.remove(id);
        let _res4 = dynamicListings.replace(id, code);

        let newPrice: Float = switch code {
            case 1 Float.fromInt(floorPrice);
            case 2 Option.get(await getMeanPrice(), 0.00);
            case 3 Option.get(await getMedianPrice(), 0.0);
            case 4 Float.fromInt(ceilingPrice);
            case _ 0.00; 
        };

        
        reviseFloor();
        reviseCeiling();
        //marketCap := marketCap + newPrice - Float.fromInt(oldPrice);
        await reviseMcap();
        return true;
    };

    private func reviseMcap(): async () {
        
        var tokenPrices = Iter.toArray(tokenCurrentPrices.entries());
        var s = tokenPrices.size();
        if (s == 0) {
            marketCap := 0.00;
            return;
        };
        var tempMc = Float.fromInt(tokenPrices[0].1);
        var i = 1;
        while (i < s) {
            tempMc += Float.fromInt(tokenPrices[i].1);
            i += 1;
        };
        var dynamicListingArr = Iter.toArray(dynamicListings.entries());
        let s2 = dynamicListingArr.size();
        i := 0;
        let meanPrice = Option.get(await getMeanPrice(), 0.00);
        let medPrice = Option.get(await getMedianPrice(), 0.00);
        while (i < s2) {
            var code = dynamicListingArr[i].1;
            var el: Float = switch code {
                case 1 Float.fromInt(floorPrice);
                case 2 meanPrice;
                case 3 medPrice;
                case 4 Float.fromInt(ceilingPrice);
                case _ 0.00; 
            };
            tempMc += el;
            i += 1;
        };

        marketCap := tempMc;

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

    public func getMktCap(): async Float {
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

    public func getModalPrice(): async ?Float {
        
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
        return Analytics.mode(priceArrFloat);
    };

    public func getStandardDeviation(): async ?Float{
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
        return Analytics.sdeviation(priceArrFloat);
    };

    public func highestEverSale(): async [Nat]{
        let highestSaleKeys = tokenHighestSales.keys();
        var maxKey = 0;
        var maxPrice = 0;
        for (key in highestSaleKeys){
            let thisHighestSale = Option.get(tokenHighestSales.get(key), 0);
            if (thisHighestSale > maxPrice){
                maxKey := key;
                maxPrice := thisHighestSale;
            };
        };
        Debug.print("goodbye");
        return [maxKey, maxPrice]; 
    };

    public func getSalesProfile(tokenId: Nat): async [(Int, Nat)]{
        let allSales = tokenHistoricalSales.get(tokenId);
        switch allSales {
            case null {
                return [];
            };
            case (?arr){
                return arr;
            };
        };
        return [];
    };

    public func getHolderProfile(tokenId: Nat): async [(Int, Principal)]{
        let allHolders = tokenHistoricalHolders.get(tokenId);
        switch allHolders {
            case null {
                return [];
            };
            case (?arr){
                return arr;
            };
        };
        return [];
    };

    public func getTokenProfile(tokenId: Nat): async [Text]{
        let allHolders = Option.get(tokenHistoricalHolders.get(tokenId), []);
        let currentHolder = switch (allHolders.size()){
            case 0 {""};
            case _ {
                Principal.toText(allHolders[allHolders.size() - 1].1);
            };
        };
        
        let lastSale = Nat.toText(Option.get(tokenLastSales.get(tokenId), 0));
        let maxSale = Nat.toText(Option.get(tokenHighestSales.get(tokenId), 0));
        return [lastSale, maxSale, currentHolder];
    };

    public func nextSalePredictor(tokenId: Nat): async ?Float{
        var saleArr = Option.get(tokenHistoricalPrices.get(tokenId), []);
        var i = 0;
        var s = saleArr.size();
        if (s == 0){
            return null;
        };
        var saleFloat  = Buffer.Buffer2<(Float)>(s);
        while (i < s) {
            switch (saleArr[i].1){
                case null {};
                case (?nat){
                    saleFloat.add(Float.fromInt(nat));
                };
            };
            
            i += 1;
        };
        var saleArrFloat = Buffer.toArray(saleFloat);
        return Analytics.predict_next(saleArrFloat, 0.50);
    };

    public func getAverageHoldingTime(tokenId: Nat): async ?Float{
        var holderArr = Option.get(tokenHistoricalHolders.get(tokenId), []);
        let size = holderArr.size();
        if (size == 1 or size == 0){
            return null;
        };
        var i = 1;
        
        var timeFloat = Buffer.Buffer2<(Float)>(size);
        while (i < size){
            var thisTimestamp = holderArr[i].0;
            var prevTimestamp = holderArr[i - 1].0;
            var el = thisTimestamp - prevTimestamp;
            timeFloat.add(Float.fromInt(el));
            
            i += 1;
        };
        var timeArray = Buffer.toArray(timeFloat);
        return Analytics.mean(timeArray);
    };

    public func getMedianHoldingTime(tokenId: Nat): async ?Float{
        var holderArr = Option.get(tokenHistoricalHolders.get(tokenId), []);
        let size = holderArr.size();
        if (size == 1 or size == 0){
            return null;
        };
        var i = 1;
        
        var timeFloat = Buffer.Buffer2<(Float)>(size);
        while (i < size){
            var thisTimestamp = holderArr[i].0;
            var prevTimestamp = holderArr[i - 1].0;
            var el = thisTimestamp - prevTimestamp;
            timeFloat.add(Float.fromInt(el));
            
            i += 1;
        };
        var timeArray = Buffer.toArray(timeFloat);
        return Analytics.median(timeArray);
    };

    public func getModalHoldingTime(tokenId: Nat): async ?Float{
        var holderArr = Option.get(tokenHistoricalHolders.get(tokenId), []);
        let size = holderArr.size();
        if (size == 1 or size == 0){
            return null;
        };
        var i = 1;
        
        var timeFloat = Buffer.Buffer2<(Float)>(size);
        while (i < size){
            var thisTimestamp = holderArr[i].0;
            var prevTimestamp = holderArr[i - 1].0;
            var el = thisTimestamp - prevTimestamp;
            timeFloat.add(Float.fromInt(el));
            
            i += 1;
        };
        var timeArray = Buffer.toArray(timeFloat);
        return Analytics.mode(timeArray);
    };

    public func getPastHolders(tokenId: Nat): async [Principal]{
        var holderArr = Option.get(tokenHistoricalHolders.get(tokenId), []);
        let size = holderArr.size();
        if (size == 0){
            return [];
        };
        var i = 0;
        
        var holderBuff = Buffer.Buffer2<(Principal)>(size);
        while (i < size){
            var holder = holderArr[i].1;
            
            holderBuff.add(holder);
            
            i += 1;
        };
        return Buffer.toArray(holderBuff);
        
    };

    public func getNextHoldingTimePredictor(tokenId: Nat): async ?Float{
        var holderArr = Option.get(tokenHistoricalHolders.get(tokenId), []);
        let size = holderArr.size();
        if (size == 1 or size == 0){
            return null;
        };
        var i = 1;
        
        var timeFloat = Buffer.Buffer2<(Float)>(size);
        while (i < size){
            var thisTimestamp = holderArr[i].0;
            var prevTimestamp = holderArr[i - 1].0;
            var el = thisTimestamp - prevTimestamp;
            timeFloat.add(Float.fromInt(el));
            
            i += 1;
        };
        var timeArray = Buffer.toArray(timeFloat);
        return Analytics.predict_next(timeArray, 0.50);
    };

    public func getMostLikelyBuyers(): async [Principal]{
        var holderBuff = Buffer.Buffer2<(Text)>(1);
        var uniqueHolderBuff = Buffer.Buffer2<(Text)>(1);
        for (key in tokenHistoricalHolders.keys()){
            var holderArr = Option.get(tokenHistoricalHolders.get(key), []);
            var i = 0;
            var size = holderArr.size();
            
            while (i < size){
                var holder = holderArr[i].1;
                
                holderBuff.add(Principal.toText(holder));
                if (not Buffer.contains<Text>(uniqueHolderBuff, Principal.toText(holder), Text.equal)){
                    uniqueHolderBuff.add(Principal.toText(holder));
                };
                
                i += 1;
            };

        };
        var k = 0;
        var net_occurences = 0;
        var occurenceBuff = Buffer.Buffer2<(Nat)>(uniqueHolderBuff.size());
        while (k < uniqueHolderBuff.size()){
            var occurences = Buffer.occurences(holderBuff.clone(), holderBuff.clone().get(k) ,Text.equal); 
            occurenceBuff.add(occurences);
            net_occurences += occurences;
            k += 1;
        };
        k := 0;
        var resultBuff = Buffer.Buffer2<(Principal)>(5);
        while (k < occurenceBuff.size()){
            if (occurenceBuff.get(k) * 10 >= net_occurences){
                resultBuff.add(Principal.fromText(uniqueHolderBuff.get(k)));
            };
            k += 1;
        };
        return Buffer.toArray(resultBuff);
        
        
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
        tokenAuctionWinningEntries := Iter.toArray(tokenAuctionWinning.entries());
        tokenHistoricalHolderEntries := Iter.toArray(tokenHistoricalHolders.entries());
        dynamicAuctionEntries := Iter.toArray(dynamicAuctions.entries());
        dynamicListingEntries := Iter.toArray(dynamicListings.entries());
    };

    system func postupgrade() {
        tokenCurrentPriceEntries := [];
        tokenHighestSaleEntries := [];
        tokenLastSaleEntries := [];
        tokenHistoricalPriceEntries := [];
        tokenHistoricalSaleEntries:= [];
        tokenAuctionPriceEntries := [];
        tokenAuctionWinningEntries := [];
        tokenHistoricalHolderEntries := [];
        dynamicAuctionEntries := [];
        dynamicListingEntries := [];
    };
    
};