import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import YDYHeartNFT from "../contracts/YDYHeartNFT.cdc"

transaction(thumbnailCID: String, background: String, heart: String, mouth: String, eyes: String, pants: String, rarity: UInt8) {
    let Admin: &YDYHeartNFT.Admin
        
    prepare(signer: AuthAccount) {
        self.Admin = signer.borrow<&YDYHeartNFT.Admin>(from: YDYHeartNFT.AdminStoragePath)
                        ?? panic("Could not borrow a reference to the Admin")
    }
    execute {
        let rarityValue = YDYHeartNFT.Rarity(rawValue: rarity) ?? panic("invalid rarity")
        
        self.Admin.mintNFT(
            thumbnailCID: thumbnailCID,
            background: background,
            heart: heart,
            mouth: mouth, 
            eyes: eyes,
            pants: pants,
            rarity: rarityValue
        )
    }
}