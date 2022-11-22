import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import YDYHeartNFT from "../contracts/YDYHeartNFT.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"

transaction(price: UFix64, quantity: quantity, receiver: Address) {
    let FlowTokenVault: &FlowToken.Vault
    let ReceiverCapability: Capability<&YDYHeartNFT.Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>
    let Admin: &YDYHeartNFT.Admin

    prepare(signer: AuthAccount) {
        self.Admin = signer.borrow<&YDYHeartNFT.Admin>(from: YDYHeartNFT.AdminStoragePath)
                        ?? panic("Could not borrow a reference to the Admin")
        
        let receiverAccount = getAccount(receiver)

        if receiverAccount.borrow<&YDYHeartNFT.Collection>(from: YDYHeartNFT.CollectionStoragePath) == nil {
            let collection <- YDYHeartNFT.createEmptyCollection()  
            receiverAccount.save(<-collection, to: YDYHeartNFT.CollectionStoragePath)
            receiverAccount.link<&YDYHeartNFT.Collection{NonFungibleToken.CollectionPublic, YDYHeartNFT.YDYHeartNFTCollectionPublic, MetadataViews.ResolverCollection}>(YDYHeartNFT.CollectionPublicPath, target: YDYHeartNFT.CollectionStoragePath)
        }

        self.FlowTokenVault = receiverAccount.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!

        self.ReceiverCapability = receiverAccount.getCapability<&YDYHeartNFT.Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>(YDYHeartNFT.CollectionPublicPath)
    }

    execute {
        let payment <- self.FlowTokenVault.withdraw(amount: price) as! @FlowToken.Vault
        self.Admin.buy(collectionCapability: self.ReceiverCapability, payment: <- payment, quantity: quantity);  
    }
}