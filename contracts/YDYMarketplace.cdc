import YDYHeartNFT from "YDYHeartNFT.cdc"
import NonFungibleToken from "NonFungibleToken.cdc"
import FlowToken from "FlowToken.cdc"
import FungibleToken from "FungibleToken.cdc"

pub contract YDYMarketplace {

  pub event ForSale(id: UInt64, price: UFix64, owner: Address?)
  pub event Purchased(id: UInt64, price: UFix64, seller: Address?, buyer: Address?)

  pub struct SaleItem {
    pub let price: UFix64
    
    pub let nftRef: &YDYHeartNFT.NFT
    
    init(_price: UFix64, _nftRef: &YDYHeartNFT.NFT) {
      self.price = _price
      self.nftRef = _nftRef
    }
  }

  pub resource interface SaleCollectionPublic {
    pub fun getIDs(): [UInt64]
    pub fun getPrice(id: UInt64): UFix64
    pub fun purchase(id: UInt64, recipientCollection: &YDYHeartNFT.Collection{NonFungibleToken.CollectionPublic}, payment: @FlowToken.Vault)
  }

  pub resource SaleCollection: SaleCollectionPublic {
    // maps the id of the NFT --> the price of that NFT
    pub var forSalePrice: {UInt64: UFix64}
    pub let YDYHeartNFTCollection: Capability<&YDYHeartNFT.Collection{YDYHeartNFT.YDYHeartNFTCollectionPrivate, YDYHeartNFT.YDYHeartNFTCollectionPublic}>
    pub let FlowTokenVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>

    pub fun listForSale(id: UInt64, price: UFix64) {
      pre {
        price >= 0.0: "It doesn't make sense to list a token for less than 0.0"
        self.YDYHeartNFTCollection.borrow()!.getIDs().contains(id): "This SaleCollection owner does not have this NFT"
      }

      self.forSalePrice[id] = price

      emit ForSale(id: id, price: price, owner: self.owner?.address)
    }

    pub fun unlistFromSale(id: UInt64) {
      self.forSalePrice.remove(key: id)
    }

    pub fun purchase(id: UInt64, recipientCollection: &YDYHeartNFT.Collection{NonFungibleToken.CollectionPublic}, payment: @FlowToken.Vault) {
      pre {
        payment.balance == self.forSalePrice[id]: "The payment is not equal to the price of the NFT"
      }
      
      // royalty percentage fee
      let ydyWallet = YDYMarketplace.account.getCapability(/public/flowTokenReceiver)
									.borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!
      let nftRoyalty = self.YDYHeartNFTCollection.borrow()!.borrowYDYHeartNFT(id: id)?.royalties![0].cut
      let ydyAmount = payment.balance * nftRoyalty
      let tempYDYWallet <- payment.withdraw(amount: ydyAmount)
		  ydyWallet.deposit(from: <- tempYDYWallet)

      // withdraw NFT and deposit to recipient
      recipientCollection.deposit(token: <- self.YDYHeartNFTCollection.borrow()!.withdraw(withdrawID: id))

      // deposit rest of payment
      self.FlowTokenVault.borrow()!.deposit(from: <- payment)

      self.unlistFromSale(id: id)

      emit Purchased(id: id, price: self.forSalePrice[id]!, seller: self.owner?.address, buyer: recipientCollection.owner?.address)
    }

    pub fun getPrice(id: UInt64): UFix64 {
      return self.forSalePrice[id]!
    }

    pub fun getIDs(): [UInt64] {
      return self.forSalePrice.keys
    }

    init(_YDYHeartNFTCollection: Capability<&YDYHeartNFT.Collection>, _FlowTokenVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>) {
      self.forSalePrice = {}
      self.YDYHeartNFTCollection = _YDYHeartNFTCollection
      self.FlowTokenVault = _FlowTokenVault
    }
  }

  pub fun createSaleCollection(YDYHeartNFTCollection: Capability<&YDYHeartNFT.Collection>, FlowTokenVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>): @SaleCollection {
    return <- create SaleCollection(_YDYHeartNFTCollection: YDYHeartNFTCollection, _FlowTokenVault: FlowTokenVault)
  }

  init() {
    
  }
}