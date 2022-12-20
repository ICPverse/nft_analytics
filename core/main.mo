import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Analytics "../types/Analytics";
import Option "mo:base/Option";
import Buffer "../types/Buffer2";
import Nat32 "mo:base/Nat32";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Float "mo:base/Float";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Minter "DIP721";
import IVAC "analytics";

actor class Landing(_owner: Principal) = this{

    private stable var collectionEntries : [(Text, Principal)] = [];
    private stable var collectionCanisterEntries : [(Text, Text)] = [];
    private stable var analyticsCanisterEntries : [(Text, Text)] = [];

    private let collections : HashMap.HashMap<Text, Principal> = HashMap.fromIter<Text, Principal>(collectionEntries.vals(), 10, Text.equal, Text.hash);
    private let collectionCanisters : HashMap.HashMap<Text, Text> = HashMap.fromIter<Text, Text>(collectionCanisterEntries.vals(), 10, Text.equal, Text.hash);
    private let analyticsCanisters : HashMap.HashMap<Text, Text> = HashMap.fromIter<Text, Text>(analyticsCanisterEntries.vals(), 10, Text.equal, Text.hash);
   
    
    public type DRC721 = Minter.DRC721;
    public type IVAC721 = IVAC.IVAC721;

    public shared({caller}) func requestApproval(collName: Text): async Bool{
        let creator = collections.get(collName);
        switch creator{
            case null{
                let res = collections.put(collName, caller);
                let status = collectionCanisters.get(collName);
                switch status{
                    case null{
                        collectionCanisters.put(collName, "pending");
                        
                        return true;
                    };
                    case (?text){
                        return false;
                    };
                };
            };
            case (?principal){
                return false;
            };
        };
        return false;
    };

    public shared({caller}) func approveCollection(collName: Text): async Bool{
        if (caller != _owner){
            return false;
        };
        let creator = collections.get(collName);
        switch creator{
            case null{
                return false;
            };
            case (?principal){
                let status = collectionCanisters.get(collName);
                switch status{
                    case null{
                        let res = collectionCanisters.put(collName,"approved");
                        return true;
                    };
                    case (?text){
                        if (text == "pending"){
                            let res = collectionCanisters.replace(collName, "approved");
                            return true;
                        }
                        else {
                            return false;
                        };
                    };
                };
            };
        };
        return false;

    };


    public shared({caller}) func launchCollection(collName: Text, symbol: Text, tags: [Text]): async (?DRC721, ?IVAC721){
        let creator = collections.get(collName);
        var creatorId = Principal.fromText("2vxsx-fae");
        switch creator{
            case null{
                return (null, null);
            };
            case (?principal){
                creatorId := principal;
                if (creatorId != caller){
                    return (null, null);
                };
            };
        };
        let status = collectionCanisters.get(collName);
        switch status{
            case null{
                return (null, null);
            };
            case (?text){
                if (text != "approved"){
                    return (null, null);
                };
            };
        };
        let t = await Minter.DRC721(collName, symbol);
        let res = collectionCanisters.replace(collName, Principal.toText(Principal.fromActor(t)));
        let t2 = await IVAC.IVAC721(collName, symbol);
        let res2 = analyticsCanisters.replace(collName, Principal.toText(Principal.fromActor(t2)));
        return (?t, ?t2);
    };

    public shared({caller}) func mint(collName: Text, uri: Text, fee: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None"){
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    
                    return false;
                }
                else {
                    canisterId := text;
                };
            };
        };
        
        
        let act = actor(canisterId):actor {mint: (Text) -> async (Nat)};
        let mintedNFT = await act.mint(uri);

        let act2 = actor(canisterId):actor {transferFrom: (Principal, Principal, Nat) -> async ()};
        await act2.transferFrom(Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"), caller, mintedNFT);

        let act3 = actor(analytics_canister):actor {onGenesis: (Nat, Principal) -> async (Bool)};
        let gen = await act3.onGenesis(fee, caller);
        return gen;
    };

    public shared({caller}) func listNFT(collName: Text, tid: Nat, price: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None") {
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    return false;
                }
                else {
                    canisterId := analytics_canister;
                };
            };
        };
        let act = actor(canisterId):actor {onRelist: (Principal, Nat, Nat) -> async (Bool)};
        let res = await act.onRelist(caller, tid, price);
        return res;
    }; 

    public shared({caller}) func dynamicListNFT(collName: Text, tid: Nat, code: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None") {
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    return false;
                }
                else {
                    canisterId := analytics_canister;
                };
            };
        };
        let act = actor(canisterId):actor {onDynamicRelist: (Principal, Nat, Nat) -> async (Bool)};
        let res = await act.onDynamicRelist(caller, tid, code);
        return res;
    }; 

    public shared({caller}) func auctionNFTstart(collName: Text, tid: Nat, minPrice: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None") {
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    return false;
                }
                else {
                    canisterId := analytics_canister;
                };
            };
        };
        let act = actor(canisterId):actor {onAuctionCreate: (Principal, Nat, Nat) -> async (Bool)};
        let res = await act.onAuctionCreate(caller, tid, minPrice);
        return res;
    }; 

    public shared({caller}) func dynamicAuctionNFTstart(collName: Text, tid: Nat, code: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None") {
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    return false;
                }
                else {
                    canisterId := analytics_canister;
                };
            };
        };
        let act = actor(canisterId):actor {onDynamicAuctionCreate: (Principal, Nat, Nat) -> async (Bool)};
        let res = await act.onDynamicAuctionCreate(caller, tid, code);
        return res;
    }; 

    public shared({caller}) func auctionNFTapply(collName: Text, tid: Nat, quotePrice: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None") {
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    return false;
                }
                else {
                    canisterId := analytics_canister;
                };
            };
        };
        let act = actor(canisterId):actor {onAuctionApply: (Principal, Nat, Nat) -> async (Bool)};
        let res = await act.onAuctionApply(caller, tid, quotePrice);
        return res;
    }; 

    public shared({caller}) func dynamicAuctionNFTapply(collName: Text, tid: Nat, quotePrice: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None") {
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    return false;
                }
                else {
                    canisterId := analytics_canister;
                };
            };
        };
        let act = actor(canisterId):actor {onDynamicAuctionApply: (Principal, Nat, Nat) -> async (Bool)};
        let res = await act.onDynamicAuctionApply(caller, tid, quotePrice);
        return res;
    }; 

    public shared({caller}) func auctionNFTend(collName: Text, tid: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None") {
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    return false;
                }
                else {
                    canisterId := analytics_canister;
                };
            };
        };
        let act = actor(canisterId):actor {onAuctionEnd: (Principal, Nat) -> async (Bool)};
        let res = await act.onAuctionEnd(caller, tid);
        return res;
    }; 

    public shared({caller}) func dynamicAuctionNFTend(collName: Text, tid: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None") {
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    return false;
                }
                else {
                    canisterId := analytics_canister;
                };
            };
        };
        let act = actor(canisterId):actor {onDynamicAuctionEnd: (Principal, Nat) -> async (Bool)};
        let res = await act.onDynamicAuctionEnd(caller, tid);
        return res;
    }; 

    public shared({caller}) func buyNFT(collName: Text, tid: Nat, price: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None") {
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    return false;
                }
                else {
                    canisterId := text;
                };
            };
        };

        let currentOwnerOpt = await ownerOf(collName, tid);
        var owner = Principal.fromText("2vxsx-fae");
        switch currentOwnerOpt{
            case null {
                return false;
            };
            case (?principal){
                owner := principal;
            };
        };
        let act = actor(analytics_canister):actor {onSale: (Principal, Nat, Nat, Principal) -> async (Bool)};
        let res = await act.onSale(owner, tid, price, caller);
        if (not res){
            return false;
        };
        let act2 = actor(canisterId):actor {transferFrom: (Principal, Principal, Nat) -> async ()};
        let res2 = await act2.transferFrom(owner, caller,tid);
        return true;
    }; 

    public shared({caller}) func dynamicBuyNFT(collName: Text, tid: Nat, price: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None") {
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    return false;
                }
                else {
                    canisterId := text;
                };
            };
        };

        let currentOwnerOpt = await ownerOf(collName, tid);
        var owner = Principal.fromText("2vxsx-fae");
        switch currentOwnerOpt{
            case null {
                return false;
            };
            case (?principal){
                owner := principal;
            };
        };
        let act = actor(analytics_canister):actor {onDynamicSale: (Principal, Nat, Nat, Principal) -> async (Bool)};
        let res = await act.onDynamicSale(owner, tid, price, caller);
        if (not res){
            return false;
        };
        let act2 = actor(canisterId):actor {transferFrom: (Principal, Principal, Nat) -> async ()};
        let res2 = await act2.transferFrom(owner, caller,tid);
        return true;
    }; 


    public shared({caller}) func transferNFT(collName: Text, tid: Nat, to: Principal) : async Bool{
        let status = collectionCanisters.get(collName);
        let analytics_canister = Option.get(analyticsCanisters.get(collName), "None");
        if (analytics_canister == "None") {
            return false;
        };
        var canisterId = "";
        switch status{
            case null{
                return false;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    return false;
                }
                else {
                    canisterId := text;
                };
            };
        };

        let act = actor(analytics_canister):actor {onTransfer: (Principal, Nat, Principal) -> async (Bool)};
        let res = await act.onTransfer(caller, tid, to);

        if (not res){
            return false;
        };
        
        let act2 = actor(canisterId):actor {transferFrom: (Principal, Principal, Nat) -> async ()};
        await act2.transferFrom(caller, to, tid);
        return true;
    }; 

    public func ownerOf(collName: Text, tid: Nat): async ?Principal {
        let status = collectionCanisters.get(collName);
        var canisterId = "";
        switch status{
            case null{
                
                return null;
            };
            case (?text){
                if (text == "pending" or text == "approved"){
                    
                    return null;
                }
                else {
                    canisterId := text;
                };
            };
        };
        
        
        let act = actor(canisterId):actor {ownerOf: (Nat) -> async (?Principal)};
        let ownerNFT = await act.ownerOf(tid);
        return ownerNFT;
    };

    public func getFloor(collName: Text): async Nat {
        let canisterId = Option.get(analyticsCanisters.get(collName), "None");
        if (canisterId == "None"){
            return 0;
        }
        else {
            let act = actor(canisterId):actor {getFloor: () -> async (Nat)};
            let floor = await act.getFloor();
            return floor;
        };
    };

    public func getCeiling(collName: Text): async Nat {
        let canisterId = Option.get(analyticsCanisters.get(collName), "None");
        if (canisterId == "None"){
            return 0;
        }
        else {
            let act = actor(canisterId):actor {getCeiling: () -> async (Nat)};
            let ceil = await act.getCeiling();
            return ceil;
        };
    };

    public func getVolume(collName: Text): async Nat {
        let canisterId = Option.get(analyticsCanisters.get(collName), "None");
        if (canisterId == "None"){
            return 0;
        }
        else {
            let act = actor(canisterId):actor {getVolume: () -> async (Nat)};
            let vol = await act.getVolume();
            return vol;
        };
    };

    public func getMcap(collName: Text): async Float {
        let canisterId = Option.get(analyticsCanisters.get(collName), "None");
        if (canisterId == "None"){
            return 0.0;
        }
        else {
            let act = actor(canisterId):actor {getMktCap: () -> async (Float)};
            let mc = await act.getMktCap();
            return mc;
        };
    };

    public func getAll(collName: Text): async [Float] {
        let fl = await getFloor(collName);
        let cl = await getCeiling(collName);
        let vol = await getVolume(collName);
        let mc = await getMcap(collName);
        return [Float.fromInt(fl), Float.fromInt(cl), Float.fromInt(vol), mc];
    };

    system func preupgrade(){
        collectionEntries := Iter.toArray(collections.entries());
        collectionCanisterEntries := Iter.toArray(collectionCanisters.entries());
        analyticsCanisterEntries := Iter.toArray(analyticsCanisters.entries());
    };

    system func postupgrade(){
        collectionEntries := [];
        collectionCanisterEntries := [];
        analyticsCanisterEntries := [];
    };
};