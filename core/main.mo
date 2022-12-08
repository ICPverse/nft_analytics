import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Analytics "../types/Analytics";
import Buffer "../types/Buffer2";
import Nat32 "mo:base/Nat32";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
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


    public shared({caller}) func launchCollection(collName: Text, symbol: Text, tags: [Text]): async (?DRC721){
        let creator = collections.get(collName);
        var creatorId = Principal.fromText("2vxsx-fae");
        switch creator{
            case null{
                return null;
            };
            case (?principal){
                creatorId := principal;
                if (creatorId != caller){
                    return null;
                };
            };
        };
        let status = collectionCanisters.get(collName);
        switch status{
            case null{
                return null;
            };
            case (?text){
                if (text != "approved"){
                    return null;
                };
            };
        };
        let t = await Minter.DRC721(collName, symbol);
        let res = collectionCanisters.replace(collName, Principal.toText(Principal.fromActor(t)));
        let t2 = await IVAC.IVAC721(collName, symbol);
        let res2 = analyticsCanisters.replace(collName, Principal.toText(Principal.fromActor(t2)));
        return (?t);
    };

    public shared({caller}) func mint(collName: Text, uri: Text, fee: Nat) : async Bool{
        let status = collectionCanisters.get(collName);
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