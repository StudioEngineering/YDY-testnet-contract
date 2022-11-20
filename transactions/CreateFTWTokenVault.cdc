import FungibleToken from "../contracts/FungibleToken.cdc"
import FTWToken from "../contracts/FTWToken.cdc"

transaction {

    prepare(signer: AuthAccount) {

        if signer.borrow<&FTWToken.Vault>(from: FTWToken.VaultStoragePath) != nil {
            return
        }

        // Create a new FTWToken Vault and put it in storage
        signer.save(
            <-FTWToken.createEmptyVault(),
            to: FTWToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&FTWToken.Vault{FungibleToken.Receiver}>(
            FTWToken.ReceiverPublicPath,
            target: FTWToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&FTWToken.Vault{FungibleToken.Balance}>(
            FTWToken.BalancePublicPath,
            target: FTWToken.VaultStoragePath
        )
    }

    execute {

    }
}