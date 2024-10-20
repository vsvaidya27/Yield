//
//  PoolView.swift
//  ios-example
//
//  Created by Varun Vaidya on 10/19/24.
//

import SwiftUI

struct PoolView: View {
    @State private var usdcAmount: String = ""
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var userBalance: Double = 0.0
    @State private var poolBalance: Double = 0.0
    @StateObject var web3RPC: Web3RPC
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                headerView
                balanceView
                inputView
                messageView
                actionButtons
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .onAppear {
            fetchUserBalance()
            startBalanceUpdater()
            startPoolBalanceUpdater()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Text("Aave Pool")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Supply USDC and earn interest")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var balanceView: some View {
        VStack(spacing: 15) {
            balanceCard(title: "Your Balance", amount: userBalance)
            balanceCard(title: "In Pool", amount: poolBalance)
        }
    }
    
    private func balanceCard(title: String, amount: Double) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(amount, specifier: "%.6f") USDC")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private var inputView: some View {
        VStack(spacing: 10) {
            TextField("Enter USDC amount", text: $usdcAmount)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                )
        }
    }
    
    private var messageView: some View {
        Group {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
            }
            
            if let successMessage = successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button(action: {
                validateAndSupply()
            }) {
                Text("Supply to Pool")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            
            Button(action: {
                Task {
                    await web3RPC.withdrawFromCompoundPool(
                        contractAddress: "0x4E5B4B9ae8a4aF96E8eC7702d29efeABD98D89b0",
                        assetAddress: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238")
                }
            }) {
                Text("Withdraw from Pool")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
        }
    }
    
    private func validateAndSupply() {
        guard let amount = Double(usdcAmount), amount > 0 else {
            errorMessage = "Please enter a valid amount of USDC."
            successMessage = nil
            return
        }
        
        if amount > userBalance {
            errorMessage = "Insufficient balance. You only have \(String(format: "%.6f", userBalance)) USDC available."
            successMessage = nil
        } else {
            errorMessage = nil
            successMessage = nil
            print("Ready to supply \(amount) USDC to the pool.")
            Task {
                await web3RPC.sendCompoundPool(
                    contractAddress: "0x4E5B4B9ae8a4aF96E8eC7702d29efeABD98D89b0",
                    assetAddress: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
                    amount: amount)
                handleSupplyResult(true, amount: amount)
            }
        }
    }
    
    private func fetchUserBalance() {
        web3RPC.getUSDCBalance()
        userBalance = web3RPC.usdcBalance
    }
    
    private func handleSupplyResult(_ success: Bool, amount: Double) {
        if success {
            successMessage = "\(String(format: "%.6f", amount)) USDC has been lent and is actively collecting APY!"
            fetchUserBalance()
        } else {
            errorMessage = "Failed to supply USDC. Please try again."
        }
    }
    
    private func startBalanceUpdater() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            Task {
                await fetchUserBalance()
            }
        }
    }
    
    private func startPoolBalanceUpdater() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            Task {
                if let balance = try? await web3RPC.getBalanceFromContract(
                    contractAddress: "0x4E5B4B9ae8a4aF96E8eC7702d29efeABD98D89b0",
                    assetAddress: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"
                ) {
                    poolBalance = Double(balance) / pow(10, 6)
                }
            }
        }
    }
}
