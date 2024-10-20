import SwiftUI
// IMP START - Installation
import Web3Auth
// IMP END - Installation

@main
struct MainApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(vm: ViewModel())
        }
    }
}

struct ContentView: View {
    @StateObject var vm: ViewModel
    @State private var showLoginView = false

    var body: some View {
        NavigationView {
                    VStack {
                        if vm.isLoading {
                            ProgressView()
                        } else {
                            if vm.loggedIn,let user = vm.user, let web3rpc = Web3RPC(user: user) {
                                TabView {
                                    BestViews(
                                        web3RPC: web3rpc,
                                        viewModel: vm
                                    )
                                    .tabItem {
                                        Label("Home", systemImage: "house.fill")
                                    }
                                    .tag(0)
                                    ChartView(
                                        web3RPC: web3rpc
                                    )
                                    .tabItem {
                                        Label("Chart", systemImage: "chart.bar.fill")
                                    }
                                    .tag(1)
                                    UserDetailView(
                                        web3RPC: web3rpc,
                                        viewModel: vm,
                                        showLoginView: $showLoginView
                                    )
                                    .tabItem {
                                        Label("User", systemImage: "person.crop.circle")
                                    }
                                    .tag(2)
                                }
                                
                            } else {
                                if showLoginView {
                                    LoginView(vm: vm)
                                } else {
                                    LandingView(showLoginView: $showLoginView)
                                }
                            }
                        }
                    }
                    //.navigationTitle(vm.navigationTitle)
                    Spacer()
                }
                .onAppear {
                    Task {
                        await vm.setup()
                    }
                }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(vm: ViewModel())
    }
}
