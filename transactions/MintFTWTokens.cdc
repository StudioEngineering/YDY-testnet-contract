import FungibleToken from "../contracts/FungibleToken.cdc"
import FTWToken from "../contracts/FTWToken.cdc"

transaction(receiverAccount: Address, amount: UFix64) {
  let tokenAdmin: &FTWToken.Administrator

  prepare(acct: AuthAccount) {
     self.tokenAdmin = acct.borrow<&FTWToken.Administrator>(from: FTWToken.AdminStoragePath)
            ?? panic("Signer is not the token admin")

    let receiverVault = getAccount(receiverAccount).getCapability(FTWToken.ReceiverPublicPath)
                          .borrow<&FTWToken.Vault{FungibleToken.Receiver}>()
                          ?? panic("Couldn't get the public Vault")

    let minter <- self.tokenAdmin.createNewMinter()
    let mintedVault <- minter.mintToken(amount: amount)

        
    receiverVault.deposit(from: <-mintedVault)

    destroy minter
  }

  execute {
        log("deposited tokens into receiver account")
  }
}