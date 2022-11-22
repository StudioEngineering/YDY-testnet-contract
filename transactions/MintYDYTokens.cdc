import FungibleToken from "../contracts/FungibleToken.cdc"
import YDYToken from "../contracts/YDYToken.cdc"

transaction(receiverAccount: Address, amount: UFix64) {
  let tokenAdmin: &YDYToken.Administrator

  prepare(acct: AuthAccount) {
     self.tokenAdmin = acct.borrow<&YDYToken.Administrator>(from: YDYToken.AdminStoragePath)
            ?? panic("Signer is not the token admin")

    let receiverVault = getAccount(receiverAccount).getCapability(YDYToken.ReceiverPublicPath)
                          .borrow<&YDYToken.Vault{FungibleToken.Receiver}>()
                          ?? panic("Couldn't get the public Vault")

    let minter <- self.tokenAdmin.createNewMinter()
    let mintedVault <- minter.mintToken(amount: amount)

        
    receiverVault.deposit(from: <-mintedVault)

    destroy minter
  }

  execute {
  
  }
}