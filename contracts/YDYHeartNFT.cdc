import NonFungibleToken from "NonFungibleToken.cdc"
import MetadataViews from "MetadataViews.cdc"
import FlowToken from "FlowToken.cdc"
import FungibleToken from "FungibleToken.cdc"
import FTWToken from "FTWToken.cdc"

pub contract YDYHeartNFT: NonFungibleToken {

    pub var totalSupply: UInt64
    pub var price: UFix64
    
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Bought(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub enum Rarity: UInt8 {
        pub case common
        pub case rare
        pub case legendary
        pub case epic
    }

    pub fun rarityToString(_ rarity: Rarity): String {
        switch rarity {
            case Rarity.common:
                return "Common"
            case Rarity.rare:
                return "Rare"
            case Rarity.legendary:
                return "Legendary"
            case Rarity.epic:
                return "Epic"
        }

        return ""
    }

    pub fun calculateAttribute(_ rarity: Rarity): UInt64 {
        let commonRange = unsafeRandom() % 5 + 1; // 1-5
        let rareRange = unsafeRandom() % 6 + 4; // 4-9
        let legendaryRange = unsafeRandom() % 11 + 8; //8-18
        let epicRange = unsafeRandom() % 18 + 14; //14-31

        switch rarity {
            case Rarity.common: 
                return commonRange
            case Rarity.rare: 
                return rareRange
            case Rarity.legendary: 
                return legendaryRange
            case Rarity.epic: 
                return epicRange
        }

        return 0
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64

        pub let name: String
        pub let description: String
        pub let thumbnailCID: String

        pub let background: String
        pub let heart: String
        pub let mouth: String
        pub let eyes: String
        pub let pants: String

        pub let zone: String

        pub var level: UInt64
        pub var lastLeveledUp: UFix64

        pub var stamina: UInt64
        pub var endurance: UInt64
        pub var lastEnduranceBoost: UFix64
        pub var efficiency: UInt64
        pub var lastEfficiencyBoost: UFix64
        pub var luck: UInt64
        pub var lastLuckBoost: UFix64

        pub let rarity: Rarity

        pub let royalties: [MetadataViews.Royalty]

        init(
            thumbnailCID: String,
            background: String,
            heart: String,
            mouth: String,
            eyes: String,
            pants: String,
            rarity: Rarity
        ) {
            YDYHeartNFT.totalSupply = YDYHeartNFT.totalSupply + 1
            self.id = YDYHeartNFT.totalSupply

            self.name = "Heart #".concat(self.id.toString())
            self.description = "YDY Heart NFT #".concat(self.id.toString())
            self.thumbnailCID = thumbnailCID
            self.background = background
            self.heart = heart
            self.mouth = mouth
            self.eyes = eyes
            self.pants = pants

            self.zone = background

            self.level = 1
            self.lastLeveledUp = getCurrentBlock().timestamp

            self.stamina = 100

            self.endurance = YDYHeartNFT.calculateAttribute(rarity)
            self.lastEnduranceBoost = getCurrentBlock().timestamp
            self.efficiency = YDYHeartNFT.calculateAttribute(rarity)
            self.lastEfficiencyBoost = getCurrentBlock().timestamp
            self.luck = YDYHeartNFT.calculateAttribute(rarity)
            self.lastLuckBoost = getCurrentBlock().timestamp

            self.rarity = rarity
            
            self.royalties = [MetadataViews.Royalty(recepient: getAccount(YDYHeartNFT.account.address).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), cut: 0.075, description: "This is the royalty receiver for YDY Heart NFTs")]
        }

        access(contract) fun levelUp() {
            self.level = self.level + 1
            self.lastLeveledUp = getCurrentBlock().timestamp
        }

        access(contract) fun repair(_ points: UInt64) {
            pre {
                self.stamina + points <= 100 : "Number of points exceeds stamina repair limit of 100"
            }
            self.stamina = self.stamina + points
        }

        access(contract) fun reduceStamina(_ points: UInt64) {
            self.stamina = self.stamina - points
        }

        access(contract) fun boostEndurance(_ points: UInt64) {
            self.endurance = self.endurance + points
            self.lastEnduranceBoost = getCurrentBlock().timestamp
        }

        access(contract) fun boostEfficiency(_ points: UInt64) {
            self.efficiency = self.efficiency + points
            self.lastEfficiencyBoost = getCurrentBlock().timestamp
        }

        access(contract) fun boostLuck(_ points: UInt64) {
            self.luck = self.luck + points
            self.lastLuckBoost = getCurrentBlock().timestamp
        }
    
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Royalties>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.IPFSFile(
                            cid: self.thumbnailCID,
                            path: "/".concat(self.id.toString()).concat(".png")
                        )
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: YDYHeartNFT.CollectionStoragePath,
                        publicPath: YDYHeartNFT.CollectionPublicPath,
                        providerPath: /private/ydyHeartNFTTCollection,
                        publicCollection: Type<&YDYHeartNFT.Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>(),
                        publicLinkedType: Type<&YDYHeartNFT.Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&YDYHeartNFT.Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-YDYHeartNFT.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "YDY Heart NFT",
                        description: "Collection of YDY Heart NFTs.",
                        externalURL: MetadataViews.ExternalURL("https://www.ydylife.com/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/ydylife")
                        }
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
            }
            return nil
        }
    }

    pub resource interface YDYHeartNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowYDYHeartNFT(id: UInt64): &YDYHeartNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow YDYHeartNFT reference: the ID of the returned reference is incorrect"
            }
        }
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver}
        pub fun buy(collectionCapability: Capability<&Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>,  payment: @FlowToken.Vault)
    }

    pub resource interface YDYHeartNFTCollectionPrivate {
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT
    }

    pub resource Collection: YDYHeartNFTCollectionPublic, YDYHeartNFTCollectionPrivate, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @YDYHeartNFT.NFT
            let id: UInt64 = token.id

            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
 
        pub fun borrowYDYHeartNFT(id: UInt64): &YDYHeartNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &YDYHeartNFT.NFT
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let ydyHeartNFT = nft as! &YDYHeartNFT.NFT
            return ydyHeartNFT as &AnyResource{MetadataViews.Resolver}
        }

        pub fun buy(collectionCapability: Capability<&Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>, payment: @FlowToken.Vault) {
            pre {
				self.owner!.address == YDYHeartNFT.account.address : "You can only buy the NFT directly from the YDYHeartNFT account"
                payment.balance == YDYHeartNFT.price: "Payment does not match the price."
			}
            
            // deposit payment in ydy wallet
            let ydyWallet = YDYHeartNFT.account.getCapability(/public/flowTokenReceiver)
									.borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!
		    ydyWallet.deposit(from: <- payment)

            // get random NFT from ydy wallet
            let ydyCollection = YDYHeartNFT.account.getCapability(YDYHeartNFT.CollectionPublicPath)
                                    .borrow<&AnyResource{YDYHeartNFT.YDYHeartNFTCollectionPublic}>()
                                    ?? panic("Can't get the YDY's collection.")
            let availableNFTs = ydyCollection.getIDs()
            if (availableNFTs.length > 0) {
                let randomInt = unsafeRandom() % UInt64(availableNFTs.length)
                let id = availableNFTs[randomInt]

                // establish the receiver for redeeming YDYHeartNFT
                let receiver = collectionCapability.borrow() ?? panic("Cannot borrow")
            
                // withdraw the NFT from ydy wallet
                let token <- self.withdraw(withdrawID: id) as! @YDYHeartNFT.NFT

                emit Bought(id: id, to: receiver.owner?.address)

                // deposit NFT to receiver's wallet
                receiver.deposit(token: <- token)
            } else {
                panic("No NFTs available.")
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub fun getTotalSupply(): UInt64 {
        return self.totalSupply
    }

    pub resource NFTMinter {

        pub fun mintNFT(
            thumbnailCID: String, background: String, heart: String, mouth: String, eyes: String, pants: String, rarity: Rarity
        ) {
            let accountOwnerCollection = YDYHeartNFT.account.borrow<&AnyResource{NonFungibleToken.CollectionPublic}>(from: YDYHeartNFT.CollectionStoragePath)!
            accountOwnerCollection.deposit(token: <-create YDYHeartNFT.NFT(thumbnailCID: thumbnailCID, background: background, heart: heart, mouth: mouth, eyes: eyes, pants: pants, rarity: rarity))
        }

        pub fun levelUp(id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            post {
                nft.level == beforeLevel + 1: "The level must be increased by 1"
            }
            
            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYHeartNFT(id: id) ?? panic("No NFT with this ID exists for user")

            let beforeLevel= nft.level
            nft.levelUp();
            return nft;
        }

        pub fun repair(points: UInt64, id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            post {
                nft.stamina == beforeStamina + points: "The stamina must be repaired by the points"
            }

            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYHeartNFT(id: id) ?? panic("No NFT with this ID exists for user")

            let beforeStamina = nft.stamina
            nft.repair(points);
            return nft
        }

        pub fun reduceStamina(points: UInt64, id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            post {
                nft.stamina == beforeStamina - points: "The stamina must be reduced by the points"
            }

            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYHeartNFT(id: id) ?? panic("No NFT with this ID exists for user")

            let beforeStamina = nft.stamina
            nft.reduceStamina(points)
            return nft
        }

        pub fun boostEndurance(points: UInt64, id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYHeartNFT(id: id) ?? panic("No NFT with this ID exists for user")
        
            nft.boostEndurance(points)
            return nft
        }

        pub fun boostEfficiency(points: UInt64, id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYHeartNFT(id: id) ?? panic("No NFT with this ID exists for user")
            
            nft.boostEfficiency(points)
            return nft
        }

        pub fun boostLuck(points: UInt64, id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYHeartNFT(id: id) ?? panic("No NFT with this ID exists for user")
            
            nft.boostLuck(points)
            return nft
        }
    }

    init() {
        self.totalSupply = 0
        self.price = 100.0

        self.CollectionStoragePath = /storage/ydyHeartNFTCollection
        self.CollectionPublicPath = /public/ydyHeartNFTCollection
        self.MinterStoragePath = /storage/ydyHeartNFTMinter

        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
 