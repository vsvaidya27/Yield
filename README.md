![Yield Project Banner](https://github.com/user-attachments/assets/83a3f759-24ee-47fe-8df4-aefc35f997f7)
# Yield
A Yield aggregator iOS platform friendly to non-crypto-native users 

![Logo_Yield](https://github.com/user-attachments/assets/6ba20894-bfbb-4dbf-bd54-8fe0dced756f)

## Architecture Overview
![yield_excalidraw](https://github.com/user-attachments/assets/928243a9-599b-4600-8998-a96d8c5f6d42)


## Guide
In this repository you can find different parts of the application:

- `/bridge` Bridge, implementing CCTP
- `/contracts` Solidity smart contracts
- `/FlowDevFeedback` Flow's feedback
AI and API scripts:
-  `/pools`, `/gpt`, `/server` are the AI + API webscript

Everything else is SWIFT for the mobile app frontend.

## Deployments

#### Ethereum Sepolia
Testnet Aave Pool: 0xF32c42eD0903D8AD98E23aA4a23E99fBdDA8c22e
Testnet Compound Pool: 0x4E5B4B9ae8a4aF96E8eC7702d29efeABD98D89b0
USDCFaucet: 0xf1c844d9499e19a3215160c92cdeb377bbc14097

#### Flow

FlowConvertAndStake Testnet - 0x4E5B4B9ae8a4aF96E8eC7702d29efeABD98D89b0
Flow-Staking (Derivative stake rewards) Testnet - 0x580798abCb1F13Cd06642185b2772a96f3173F20


## Figma UI
### This link gives you viewing access to the design:

https://www.figma.com/design/qy7SUzy2URRL2J1jqhdvbC/YIELD-ETH-GLOBAL?node-id=0-1&t=oLZsxPOFiKG1DBSG-1

## Projects Integrated

#### Flow

Yield - the app would allow users to convert their USDC to Flow tokens and stake it for pool rewards in a single click. For the functionality, we use two contracts deployed on Flow EVM testnet.

Contracts deployed on Flow (EVM Testnet) -

FlowConvertAndStake - 0x4E5B4B9ae8a4aF96E8eC7702d29efeABD98D89b0

Flow-Staking (Derivative stake rewards) - 0x580798abCb1F13Cd06642185b2772a96f3173F20


Source code - contracts/


As a process of working on Flow, our developer feedback is attached here: ./FlowDevFeedback


#### Circle

The project is based on the USDC token as a starting asset - given the mobile app targets users with NO experience, USDC offers a familiar and stable foundation for their exposure to crypto yields. 
Additionally, the fact that USDC is a multichain asset, and Cross Chain Transfer Protocol (CCTP) allows us to on-ramp users crypto to Ethereum and then subsequently teleport it to the necessary chains, which is more of the reason why we chose USDC as a foundational crypto representation of their assets.


#### Polygon

We track multiple staking opportunitie/ lending protocols across several chains. Multiple pools (Compound v3, Aave v3 etc) in Polygon PoS are tracked for finding the most effective yields.


#### Alchemy

To make the UX as simple as it can get for users - aside Social login, we plan to abstract tx fees, and everything that make users feel like they are using a blockchain. Account Abstraction - and Alchemy’s Account Kit comes in this place and helps enforce AA and have users work with a Smart Account in the background while using social login to sign.


#### Unlimit

To convert fiat (USD) to USDC - that would subsequently go to other platforms as a way of generating yields (automatically in the background), Unlimit comes in handy in providing users the easiest approach to buy in on “Yield”. When users take profit, Unlimit comes in yet again and provides an easy way to off-ramp the USDC tokens to their bank account (all in an abstracted way)

#### Next Partners' Tech to add, TBD (will be added in the future):
##### NeomEVM
Adding Neom would permit to get access to Solana's DeFi rates for our users. Should we implement in the future, we would track multiple staking opportunitie/ lending protocols across the chain. Multiple pools would be compared for finding the most effective yields.

##### Dynamic
We would like to replace web3auth with Dynamic for social login.

##### Skale
Adding Skale would permit to get access to the chain's rising DeFi ecosystem and high rates for our users. Should we implement in the future, we would track multiple staking opportunitie/ lending protocols across the chain. Multiple pools would be compared for finding the most effective yields.

##### AirDAO
Adding AirDAO layer1 would permit to get access to the chain's rising DeFi ecosystem and high rates for our users, notably as the DAO community is within our target audience. Should we implement in the future, we would track multiple staking opportunitie/ lending protocols across the chain. Multiple pools would be compared for finding the most effective yields.


##### Privy
We would like to implement Privy's account abstraction and social log-in.
