import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import YDYHeartNFT from "../contracts/YDYHeartNFT.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"

transaction(price: UFix64, quantity: quantity) {
    let FlowTokenVault: &FlowToken.Vault
    let ReceiverCapability: Capability<&YDYHeartNFT.Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>

    prepare(signer: AuthAccount) { 
        if signer.borrow<&YDYHeartNFT.Collection>(from: YDYHeartNFT.CollectionStoragePath) == nil {
            let collection <- YDYHeartNFT.createEmptyCollection()  
            signer.save(<-collection, to: YDYHeartNFT.CollectionStoragePath)
            signer.link<&YDYHeartNFT.Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>(YDYHeartNFT.CollectionPublicPath, target: YDYHeartNFT.CollectionStoragePath)
        }

        self.FlowTokenVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!

        self.ReceiverCapability = signer.getCapability<&YDYHeartNFT.Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>(YDYHeartNFT.CollectionPublicPath)
    }

    execute {
        let payment <- self.FlowTokenVault.withdraw(amount: price) as! @FlowToken.Vault
        YDYHeartNFT.buy(collectionCapability: self.ReceiverCapability, payment: <- payment, quantity: quantity);  
    }
}