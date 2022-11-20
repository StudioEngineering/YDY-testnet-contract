import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import YDYHeartNFT from "../contracts/YDYHeartNFT.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
transaction(price: UFix64) {
        let FlowTokenVault: &FlowToken.Vault
        let signerCapability: Capability<&YDYHeartNFT.Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>
        let ownerCollectionRef: &AnyResource{YDYHeartNFT.YDYHeartNFTCollectionPublic}

        prepare(signer: AuthAccount) {
            if signer.borrow<&YDYHeartNFT.Collection>(from: YDYHeartNFT.CollectionStoragePath) == nil {
                  let collection <- YDYHeartNFT.createEmptyCollection()
                  
                  signer.save(<-collection, to: YDYHeartNFT.CollectionStoragePath)
      
                  signer.link<&YDYHeartNFT.Collection{NonFungibleToken.CollectionPublic, YDYHeartNFT.YDYHeartNFTCollectionPublic, MetadataViews.ResolverCollection}>(YDYHeartNFT.CollectionPublicPath, target: YDYHeartNFT.CollectionStoragePath)
            }

            self.FlowTokenVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
    
            let owner = getAccount() // inseert account address here
            self.ownerCollectionRef = owner.getCapability(YDYHeartNFT.CollectionPublicPath)
                        .borrow<&AnyResource{YDYHeartNFT.YDYHeartNFTCollectionPublic}>()
                        ?? panic("Can't get the User's collection.")

            self.signerCapability = signer.getCapability<&YDYHeartNFT.Collection{YDYHeartNFT.YDYHeartNFTCollectionPublic}>(YDYHeartNFT.CollectionPublicPath)

        }

            execute {

            let payment <- self.FlowTokenVault.withdraw(amount: price) as! @FlowToken.Vault

            self.ownerCollectionRef.buy(collectionCapability: self.signerCapability, payment: <- payment);  
            }
        }