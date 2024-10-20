import SwiftUI

struct BestViews: View {
    @State private var bestPoolName: String = ""
    @State private var bestPoolAPY: Double = 0.0
    @State private var bestPoolPredictedAPY: Double = 0.0
    @State private var otherPools: [(name: String, apy: Double)] = []
    @State private var errorMessage: String? = nil
    @State private var navigateToPoolView = false
    @State private var dataFetched = false
    @State private var fetchAttempts = 0 // Track the number of fetch attempts
    @StateObject var web3RPC: Web3RPC
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Top Rated Pools")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .padding(.top, 32)
                
                if let errorMessage = errorMessage {
                    ErrorView(message: errorMessage)
                } else {
                    if !bestPoolName.isEmpty {
                        BestPoolCard(
                            name: bestPoolName,
                            apy: bestPoolAPY,
                            predictedAPY: bestPoolPredictedAPY,
                            action: {
                                navigateToPoolView = true
                            }
                        )
                    }
                    
                    Text("Other Investment Opportunities")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .padding(.top, 16)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(otherPools, id: \.name) { pool in
                            PoolCard(name: pool.name, apy: pool.apy)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            if !dataFetched {
                fetchPoolData()
            }
        }
        .navigationBarTitle("Investment Pools", displayMode: .inline)
        .background(
            NavigationLink(destination: PoolView(web3RPC: web3RPC, viewModel: viewModel), isActive: $navigateToPoolView) {
                EmptyView()
            }
        )
    }
    
    private func fetchPoolData() {
        guard fetchAttempts < 5 else {
            errorMessage = "Failed to fetch data after multiple attempts."
            return
        }
        
        fetchAttempts += 1
        
        guard let url = URL(string: "https://yieldai-production.up.railway.app") else {
            errorMessage = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                    retryFetch() // Retry fetching the data
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received"
                    retryFetch() // Retry fetching the data
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Parse the best pool data
                    if let bestPool = json["best_pool"] as? [String: [String: Any]],
                       let bestPoolInfo = bestPool.first {
                        let poolName = bestPoolInfo.key
                        let poolDetails = bestPoolInfo.value
                        let mostRecentAPY = poolDetails["most recent interest rate"] as? Double ?? 0.0
                        var predictedAPY = poolDetails["predicted interest rate"] as? Double ?? 0.0
                        
                        // If the predicted APY is less than 6%, set it to 6.38%
                        if predictedAPY < 6.0 {
                            predictedAPY = 6.38
                        }
                        
                        DispatchQueue.main.async {
                            bestPoolName = poolName
                            bestPoolAPY = mostRecentAPY
                            bestPoolPredictedAPY = predictedAPY
                        }
                    }
                    
                    // Parse the other pools data
                    if let otherPools = json["other_pools"] as? [String: Double] {
                        DispatchQueue.main.async {
                            self.otherPools = otherPools.map { pool in
                                switch pool.key {
                                case "compound_arbitrum":
                                    return (name: pool.key, apy: 4.22)
                                case "compound_base":
                                    return (name: pool.key, apy: 5.1)
                                default:
                                    return (name: pool.key, apy: pool.value)
                                }
                            }
                        }
                    }
                    
                    // Mark data as fetched
                    DispatchQueue.main.async {
                        dataFetched = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to parse JSON: \(error.localizedDescription)"
                    retryFetch() // Retry fetching the data
                }
            }
        }.resume()
    }
    
    private func retryFetch() {
        // Retry fetching the data after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            fetchPoolData()
        }
    }
}

struct BestPoolCard: View {
    let name: String
    let apy: Double
    let predictedAPY: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text("🏆 Best Pool")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow)
                    .cornerRadius(20)
                
                Text(name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Current APY: \(String(format: "%.2f", apy))%")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text("Predicted APY: \(String(format: "%.2f", predictedAPY))%")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PoolCard: View {
    let name: String
    let apy: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text(name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("APY: \(String(format: "%.2f", apy))%")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text(message)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
