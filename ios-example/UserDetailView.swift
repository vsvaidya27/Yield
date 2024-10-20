import SwiftUI
import Web3Auth

struct UserDetailView: View {
    @State private var isPrivateKeySectionVisible = false
    @State private var showingAlert = false
    @StateObject var web3RPC: Web3RPC
    @StateObject var viewModel: ViewModel
    @Binding var showLoginView: Bool

    var body: some View {
        if let user = viewModel.user {
            List {
                // IMP START - Get User Info
                Section(header: Text("User Information")) {
                    Text("Name: \(user.userInfo?.name ?? "")")
                    Text("Email: \(user.userInfo?.email ?? "")")
                }
                // IMP END - Get User Info

                Section(header: Text("Public Address")) {
                    Button {
                        web3RPC.getAccounts()
                    } label: {
                        Label("Get Public Address", systemImage: "person.crop.circle")
                    }
                    if !web3RPC.publicAddress.isEmpty {
                        Text("\(web3RPC.publicAddress)")
                    }
                }

                Section(header: Text("Blockchain Calls")) {
                    Button {
                        web3RPC.getBalance()
                    } label: {
                        Label("Get Eth Balance", systemImage: "dollarsign.circle")
                    }
                    if web3RPC.balance >= 0 {
                        Text("\(web3RPC.balance) ETH")
                    }
                    Button {
                        web3RPC.getUSDCBalance()
                    } label: {
                        Label("Get USDC Balance", systemImage: "dollarsign.circle")
                    }
                    if web3RPC.balance >= 0 {
                        Text("\(web3RPC.usdcBalance) USDC")
                    }
                    Button {
                        web3RPC.signMessage()
                    } label: {
                        Label("Sign Transaction", systemImage: "pencil.circle")
                    }
                    if !web3RPC.signedMessageHashString.isEmpty {
                        Text("\(web3RPC.signedMessageHashString)")
                    }

                    Button {
                        web3RPC.sendTransaction()
                    } label: {
                        Label("Send Transaction", systemImage: "paperplane.circle")
                    }
                    if !web3RPC.sentTransactionID.isEmpty {
                        Text("\(web3RPC.sentTransactionID)")
                    }
                }

                Button {
                    isPrivateKeySectionVisible.toggle()
                } label: {
                    Label("Private Key", systemImage: "key")
                }
                if isPrivateKeySectionVisible {
                    Section(header: Text("Private Key")) {
                        Text("\(user.privKey ?? "")")
                    }
                }

                Section {
                    Button {
                        Task.detached {
                            do {
                              
                                try await viewModel.logout()
                                showLoginView = false
                                
                            } catch {
                                DispatchQueue.main.async {
                                    showingAlert = true
                                }
                            }
                        }
                    } label: {
                        Label("Logout", systemImage: "arrow.left.square.fill")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("Error"), message: Text("Logout failed!"), dismissButton: .default(Text("OK")))
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await web3RPC.callUSDCFaucet(contractAddress: "0xf1c844d9499e19a3215160c92cdeb377bbc14097")
                            //await web3RPC.approveUSDC(contractToApprove: "0x4E5B4B9ae8a4aF96E8eC7702d29efeABD98D89b0")
                        }
                    } label: {
                        Label("Buy USDC", systemImage: "arrow.up.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("User Details")
        }
    }
}
