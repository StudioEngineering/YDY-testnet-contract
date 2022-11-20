import FungibleToken from "../contracts/FungibleToken.cdc"
import YDYToken from "../contracts/YDYToken.cdc"

transaction {

    prepare(signer: AuthAccount) {

        if signer.borrow<&YDYToken.Vault>(from: YDYToken.VaultStoragePath) != nil {
            return
        }

        // Create a new YDYToken Vault and put it in storage
        signer.save(
            <-YDYToken.createEmptyVault(),
            to: YDYToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&YDYToken.Vault{FungibleToken.Receiver}>(
            YDYToken.ReceiverPublicPath,
            target: YDYToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&YDYToken.Vault{FungibleToken.Balance}>(
            YDYToken.BalancePublicPath,
            target: YDYToken.VaultStoragePath
        )
    }

    execute {

    }
}