
import BigInt
import Combine
import Foundation
import web3
import Web3Auth
import SwiftUI

class Web3RPC : ObservableObject {
    var user: Web3AuthState
    private var client: EthereumClientProtocol
    public var address: EthereumAddress
    private var account: EthereumAccount
    private var latestBlock = 0
    private var chainID = 11155111
    private var RPC_URL = "https://rpc.ankr.com/eth_sepolia"
    
    @Published var balance: Double = 0
    @Published var signedMessageHashString:String = ""
    @Published var sentTransactionID:String = ""
    @Published var publicAddress: String = ""
    @Published var usdcBalance: Double = 0
    
    init?(user: Web3AuthState){
        self.user = user
        do{
            client = EthereumHttpClient(url: URL(string: RPC_URL)!, network: .fromString("11155111"))
            account = try EthereumAccount(keyStorage: user as EthereumSingleKeyStorageProtocol )
            address = account.address
        } catch {
             return nil
        }
    }
    
    func getAccounts() {
        self.publicAddress = address.asString()
        print(address.asString())
    }
    

    func checkLatestBlockChanged() async -> Bool {
        return await withCheckedContinuation({ continuation in
            client.eth_blockNumber { [weak self] result in
                switch result {
                case .success(let val):
                    if self?.latestBlock != val {
                        self?.latestBlock = val
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        })
    }

    // IMP START - Blockchain Calls
    func getBalance() {
        Task {
            let blockChanged = await checkLatestBlockChanged()
            guard blockChanged == true else {
                return
            }
            let _ = client.eth_getBalance(address: self.address, block: .Latest) { [unowned self] result in
                switch result {
                case .success(let weiValue):
                    let balance = Web3AuthWeb3Utils.toEther(wei: weiValue) // Access the value directly
                    DispatchQueue.main.async { [weak self] in
                        self?.balance = balance
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    func getUSDCBalance() {
        Task {
            let usdcContractAddress = EthereumAddress("0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238")
            
            // Create an instance of the ERC20 contract
            let erc20 = ERC20(client: client)
                  
            erc20.balanceOf(tokenContract: usdcContractAddress, address: address) { [unowned self] result in
              switch result {
              case .success(let usdcBalanceBigUInt):
                  // Assuming USDC has 6 decimal places
                  let usdcBalance = Double(usdcBalanceBigUInt) / pow(10, 6)
                  DispatchQueue.main.async { [weak self] in
                      self?.usdcBalance = usdcBalance
                  }
              case .failure(let error):
                  print("Error getting USDC balance: \(error)")
              }
          }
      }
  }


    func signMessage() {
        do {
            let val = try account.sign(message: "Hello World")
            self.signedMessageHashString = val.web3.hexString
            print(self.signedMessageHashString)
        } catch {
            self.signedMessageHashString = "Something Went Wrong"
        }
    }
    
    func sendTransaction()  {
        Task{
            do {
                let val = try await transferAsset(sendTo: "0x24BfD1c2D000EC276bb2b6af38C47390Ae6B5FF0", amount: 0.0001, maxTip: 0.0001)
                self.sentTransactionID = val
                print(val)
            } catch let error {
                print("error: ", error)
                self.sentTransactionID = "Something Went Wrong, please check if you have insufficient funds"
            }
            
        }
        
    }
    
    func transferAsset(sendTo: String, amount: Double, maxTip: Double, gasLimit: BigUInt = 21000) async throws -> String {
        let gasPrice = try await client.eth_gasPrice()
        let maxTipInGwie = BigUInt(Web3AuthWeb3Utils.toEther(Gwie: BigUInt(amount)))
        let totalGas = gasPrice + maxTipInGwie
        let amtInGwie = Web3AuthWeb3Utils.toWei(ether: amount)
        let nonce = try await client.eth_getTransactionCount(address: address, block: .Latest)
        let transaction = EthereumTransaction(from: address, to: EthereumAddress(sendTo), value: amtInGwie, data: Data(), nonce: nonce + 1, gasPrice: totalGas, gasLimit: gasLimit, chainId: chainID)
        let signed = try account.sign(transaction: transaction)
        let val = try await client.eth_sendRawTransaction(signed.transaction, withAccount: account)
        return val
    }
    // IMP END - Blockchain Calls
    func dataFromHexString(_ hex: String) -> Data {
        var data = Data()
        var hex = hex
        while hex.count > 0 {
            let subIndex = hex.index(hex.startIndex, offsetBy: 2)
            let byteString = String(hex[..<subIndex])
            hex = String(hex[subIndex...])
            if let num = UInt8(byteString, radix: 16) {
                data.append(num)
            }
        }
        return data
    }
    
    func callUSDCFaucet(contractAddress: String) async {
        do {
            // Get the nonce for the account
            let nonce = try await client.eth_getTransactionCount(address: address, block: .Latest)
            print("Nonce fetched: \(nonce)")
            
            // Encode the hardcoded function selector for 'get()'
            let encodedFunctionCall = dataFromHexString("6d4ce63c") // This is the hardcoded function selector
            print("Encoded function call: \(encodedFunctionCall)")
            
            // Create the transaction object
            let gasPrice = try await client.eth_gasPrice()
            print("Fetched gas price: \(gasPrice)")
            
            let transaction = EthereumTransaction(
                from: address,
                to: EthereumAddress(contractAddress),
                value: BigUInt(0), // No ETH needed for calling the get function
                data: encodedFunctionCall,
                nonce: nonce,
                gasPrice: gasPrice,
                gasLimit: BigUInt(100000), // Set a reasonable gas limit
                chainId: chainID
            )
            print("Transaction created: \(transaction)")
            
            // Sign the transaction
            let signedTransaction = try account.sign(transaction: transaction)
            print("Transaction signed")

            // Send the transaction
            let transactionHash = try await client.eth_sendRawTransaction(signedTransaction.transaction, withAccount: account)
            print("Transaction sent with hash: \(transactionHash)")

            // Update UI or state accordingly
            DispatchQueue.main.async {
                self.sentTransactionID = transactionHash
            }
            
        } catch {
            // Print the error to get more details about the failure
            print("Error calling USDC Faucet: \(error)")
            DispatchQueue.main.async {
                self.sentTransactionID = "Failed to call faucet"
            }
        }
    }
    func encodeAddress(_ address: String) -> Data {
        var data = Data()
        let addressWithoutPrefix = address.hasPrefix("0x") ? String(address.dropFirst(2)) : address
        if let addressData = Data(hex: addressWithoutPrefix) {
            // An Ethereum address is 20 bytes, so we need to pad to 32 bytes
            let padding = Data(repeating: 0, count: 12) // 32 bytes - 20 bytes = 12 bytes padding
            data.append(padding)
            data.append(addressData)
        }
        return data
    }

    // Helper function to encode a uint256 value (32 bytes)
    func encodeUInt256(_ value: BigUInt) -> Data {
        // Convert the BigUInt to a data representation
        var valueData = value.serialize()
        // Ensure the data is 32 bytes long (padded with leading zeros if necessary)
        if valueData.count < 32 {
            let padding = Data(repeating: 0, count: 32 - valueData.count)
            valueData = padding + valueData
        }
        return valueData
    }
    
    func approveUSDC(contractToApprove: String) async {
        do {
            // usdc value for approval
            let approvalAmount = BigUInt(2).power(5) - 1
            
            let approveFunctionSelector = "095ea7b3" // Keccak-256 hash of "approve(address,uint256)" truncated to 4 bytes
            var approveFunctionCall = dataFromHexString(approveFunctionSelector)
            approveFunctionCall.append(encodeAddress(contractToApprove))
            approveFunctionCall.append(encodeUInt256(approvalAmount))
            
            let nonce = try await client.eth_getTransactionCount(address: address, block: .Latest)
            print("Nonce fetched for approval: \(nonce)")
            
            let gasPrice = try await client.eth_gasPrice()
            print("Fetched gas price for approval: \(gasPrice)")
            
            // Create the approval transaction
            let approvalTransaction = EthereumTransaction(
                from: address,
                to: EthereumAddress("0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"), // USDC token address
                value: BigUInt(0),
                data: approveFunctionCall,
                nonce: nonce,
                gasPrice: gasPrice,
                gasLimit: BigUInt(50000), // Adjust gas limit as needed for approval
                chainId: chainID
            )
            
            // Sign the approval transaction
            let signedApprovalTransaction = try account.sign(transaction: approvalTransaction)
            print("Approval transaction signed")
            
            // Send the approval transaction
            let approvalTransactionHash = try await client.eth_sendRawTransaction(signedApprovalTransaction.transaction, withAccount: account)
            print("Approval transaction sent with hash: \(approvalTransactionHash)")
            
            // Update UI or state accordingly
            DispatchQueue.main.async {
                self.sentTransactionID = approvalTransactionHash
            }
            
        } catch {
            // Print the error to get more details about the failure
            print("Error during the approval process: \(error)")
            DispatchQueue.main.async {
                self.sentTransactionID = "Failed to approve USDC"
            }
        }
    }
    
    func sendCompoundPool(contractAddress: String, assetAddress: String, amount: Double) async {
        do {
            // Convert the amount to the smallest unit (wei for ETH or token's smallest unit)
            let amountInSmallestUnit = BigUInt(amount * pow(10, 6))
            
            // Get the nonce for the account
            let nonce = try await client.eth_getTransactionCount(address: address, block: .Latest)
            print("Nonce fetched: \(nonce)")
            
            // Encode the function selector for 'supply(address,uint256)'
            var encodedFunctionCall = dataFromHexString("f2b9fdb8") // This is the hardcoded function selector
            print("Encoded function call: \(encodedFunctionCall)")
            
            // Encode the parameters
            encodedFunctionCall.append(encodeAddress(assetAddress))
            encodedFunctionCall.append(encodeUInt256(amountInSmallestUnit))
            
            // Create the transaction object
            let gasPrice = try await client.eth_gasPrice()
            print("Fetched gas price: \(gasPrice)")
            
            let transaction = EthereumTransaction(
                from: address,
                to: EthereumAddress(contractAddress),
                value: BigUInt(0),
                data: encodedFunctionCall,
                nonce: nonce,
                gasPrice: gasPrice,
                gasLimit: BigUInt(1_000_000), // Set a reasonable gas limit
                chainId: chainID
            )
            print("Transaction created: \(transaction)")
            
            // Sign the transaction
            let signedTransaction = try account.sign(transaction: transaction)
            print("Transaction signed")
            
            // Send the transaction
            let transactionHash = try await client.eth_sendRawTransaction(signedTransaction.transaction, withAccount: account)
            print("Transaction sent with hash: \(transactionHash)")
            
            // Update UI or state accordingly
            DispatchQueue.main.async {
                self.sentTransactionID = transactionHash
            }
            
        } catch {
            // Print the error to get more details about the failure
            print("Error calling contract: \(error)")
            DispatchQueue.main.async {
                self.sentTransactionID = "Failed to call contract"
            }
        }
    }
    
    func withdrawFromCompoundPool(contractAddress: String, assetAddress: String) async -> Double? {
        do {
            // Fetch the current balance for the user using the getBalance function
            let balance = try await getBalanceFromContract(contractAddress: contractAddress, assetAddress: assetAddress)
            print("Current balance: \(balance)")
            let withdrawalAmount = balance
            guard balance > 0 else {
                print("No funds to withdraw.")
                return nil
            }

            // Get the nonce for the account
            let nonce = try await client.eth_getTransactionCount(address: address, block: .Latest)
            print("Nonce fetched: \(nonce)")
            
            // Encode the function selector for 'withdraw(address,uint256)'
            var encodedFunctionCall = dataFromHexString("f3fef3a3") // Hardcoded function selector for withdraw(address,uint256)
            print("Encoded function call: \(encodedFunctionCall)")
            
            // Encode the parameters
            encodedFunctionCall.append(encodeAddress(assetAddress))
            encodedFunctionCall.append(encodeUInt256(BigUInt(withdrawalAmount)))
            
            // Create the transaction object
            let gasPrice = try await client.eth_gasPrice()
            print("Fetched gas price: \(gasPrice)")
            
            let transaction = EthereumTransaction(
                from: address,
                to: EthereumAddress(contractAddress),
                value: BigUInt(0),
                data: encodedFunctionCall,
                nonce: nonce,
                gasPrice: gasPrice,
                gasLimit: BigUInt(200_000), // Set a reasonable gas limit
                chainId: chainID
            )
            print("Transaction created: \(transaction)")
            
            // Sign the transaction
            let signedTransaction = try account.sign(transaction: transaction)
            print("Transaction signed")
            
            // Send the transaction
            let transactionHash = try await client.eth_sendRawTransaction(signedTransaction.transaction, withAccount: account)
            print("Transaction sent with hash: \(transactionHash)")
            
            // Return the withdrawn amount (convert from smallest unit to normal unit)
            let withdrawnAmount = Double(balance) / pow(10, 6)
            return withdrawnAmount
            
        } catch {
            // Print the error to get more details about the failure
            print("Error calling withdraw: \(error)")
            return nil
        }
    }

    // Helper function to get the user's balance from the contract
    func getBalanceFromContract(contractAddress: String, assetAddress: String) async throws -> BigUInt {
        // Encode the function selector for 'getBalance(address,address)'
        var encodedFunctionCall = dataFromHexString("d4fac45d") // Hardcoded function selector for getBalance(address,address)
        encodedFunctionCall.append(encodeAddress(assetAddress))
        encodedFunctionCall.append(encodeAddress(address.asString()))

        // Perform the call to get the balance
        // Perform the eth_call
        let transaction = EthereumTransaction(
            to: EthereumAddress(contractAddress),
            data: encodedFunctionCall
        )

        // Perform the eth_call
        let result = try await client.eth_call(transaction, block: .Latest)

        // Convert the returned data to a BigUInt
        guard let balanceData = result.web3.hexData else {
            throw SampleAppError.somethingWentWrong
        }

        // Now convert balanceData to BigUInt
        let balance = BigUInt(balanceData)
        return balance
    }

}

extension Web3AuthState: EthereumSingleKeyStorageProtocol {
    public func storePrivateKey(key: Data) throws {
        
    }
    
    public func loadPrivateKey() throws -> Data {
        guard let privKeyData = self.privKey?.web3.hexData else {
            throw SampleAppError.somethingWentWrong
        }
        return privKeyData
        
    }
    
    
}

public enum SampleAppError:Error{
    
    case noInternetConnection
    case decodingError
    case somethingWentWrong
    case customErr(String)
}
