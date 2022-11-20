import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import YDYHeartNFT from "../contracts/YDYHeartNFT.cdc"

transaction(thumbnailCID: String, background: String, heart: String, mouth: String, eyes: String, pants: String, rarity: UInt8) {
          let minter: &YDYHeartNFT.NFTMinter
        
          prepare(signer: AuthAccount) {

            self.minter = signer.borrow<&YDYHeartNFT.NFTMinter>(from: YDYHeartNFT.MinterStoragePath)
                      ?? panic("Could not borrow a reference to the NFT minter")
          }
          execute {
            let rarityValue = YDYHeartNFT.Rarity(rawValue: rarity) ?? panic("invalid rarity")
        
                self.minter.mintNFT(
                    thumbnailCID: thumbnailCID,
                    background: background,
                    heart: heart,
                    mouth: mouth, 
                    eyes: eyes,
                    pants: pants,
                    rarity: rarityValue
                )
        
            log("Minted an NFT")
          }
          }