import Foundation
import web3swift

// AVAX destination address
let mintRecipient = destinationAddress
let encodedAddress = try! Web3.Utils.abiEncode(parameters: [mintRecipient])

// Assume we have these defined somewhere:
let ethTokenMessengerContractAddress = "0x..." // Ethereum contract address
let avaxMessageTransmitterContractAddress = "0x..." // Avalanche contract address
let fromChain = "Ethereum"
let toChain = "Avalanche"
let amount: BigUInt = 1000000 // Example amount (in smallest unit like wei)
let AVAX_DESTINATION_DOMAIN: BigUInt = 123 // Destination domain
let USDC_ETH_CONTRACT_ADDRESS = "0x07865c6e87b9f70255377e024ace6630c1eaa37f" // USDC contract address
let gasPrice: BigUInt = 1000000000 // Example gas price
let gasLimit: BigUInt = 300000 // Example gas limit
let nonce: BigUInt = 1 // Nonce
let account: EthereumKeystoreV3 = ... // Account for signing transactions

// ABI-encode the function arguments for `depositForBurn` call
let depositForBurnFunction = "depositForBurn"
let depositForBurnABI = try! Web3.Utils.abiEncodeFunction(
    depositForBurnFunction, 
    parameters: [
        amount, 
        AVAX_DESTINATION_DOMAIN, 
        encodedAddress!, 
        USDC_ETH_CONTRACT_ADDRESS
    ]
)

// Step 2: Burn USDC
print("Depositing USDC to Token Messenger contract on \(fromChain)...")

// Create the transaction for the contract call
let burnTx = EthereumTransaction(
    to: EthereumAddress(ethTokenMessengerContractAddress), 
    data: Data(hex: depositForBurnABI),  // Encode ABI for "depositForBurn" call
    value: BigUInt(0), // No ether sent
    gasPrice: gasPrice,
    gasLimit: gasLimit,
    nonce: nonce
)

// Sign and send the transaction
let signedBurnTx = try! web3.eth.signTransaction(burnTx, account: account)
let burnUSDCReceipt = try! web3.eth.sendRawTransaction(signedBurnTx)

// Log the transaction hash
print("Deposited - txHash:", burnUSDCReceipt.transactionHash)

// Step 3: Retrieve message bytes from logs
let logs = burnUSDCReceipt.logs
let eventTopic = Web3.Utils.keccak256("MessageSent(bytes)")

guard let log = logs.first(where: { $0.topics[0] == eventTopic }) else {
    fatalError("Event not found")
}

let decodedMessageBytes = try! ABI.decodeParameters(["bytes"], from: log.data)
let messageBytes = decodedMessageBytes[0] as! Data
let messageHash = Web3.Utils.keccak256(messageBytes)

// Step 4: Fetch attestation signature
print("Fetching attestation signature...")

var attestationResponse: AttestationResponse = AttestationResponse(status: "pending")
let session = URLSession.shared

while attestationResponse.status != "complete" {
    let url = URL(string: "https://iris-api-sandbox.circle.com/attestations/\(messageHash)")!
    let task = session.dataTask(with: url) { data, response, error in
        guard let data = data else { return }
        
        // Decode JSON response
        let decoder = JSONDecoder()
        attestationResponse = try! decoder.decode(AttestationResponse.self, from: data)
        
        print("Attestation Status:", attestationResponse.status ?? "sent")
    }
    
    task.resume()
    Thread.sleep(forTimeInterval: 2.0) // Sleep for 2 seconds
}

let attestationSignature = attestationResponse.attestation!
print("Obtained Signature: \(attestationSignature)")

struct AttestationResponse: Codable {
    let status: String
    let attestation: String?
}

// Step 5: Receive funds on destination chain and address
print("Receiving funds on \(toChain)...")

// ABI-encode the function arguments for `receiveMessage` call
let receiveMessageFunction = "receiveMessage"
let receiveMessageABI = try! Web3.Utils.abiEncodeFunction(
    receiveMessageFunction,
    parameters: [messageBytes, attestationSignature]
)

let receiveTx = EthereumTransaction(
    to: EthereumAddress(avaxMessageTransmitterContractAddress), 
    data: Data(hex: receiveMessageABI), // Encode ABI for "receiveMessage" call
    value: BigUInt(0), // No ether sent
    gasPrice: gasPrice,
    gasLimit: gasLimit,
    nonce: nonce
)

// Sign and send the transaction
let signedReceiveTx = try! web3.eth.signTransaction(receiveTx, account: account)
let receiveTxReceipt = try! web3.eth.sendRawTransaction(signedReceiveTx)

print("Received funds successfully - txHash:", receiveTxReceipt.transactionHash)
