//
//  ChartView.swift
//  ios-example
//
//  Created by Varun Vaidya on 10/20/24.
//

import SwiftUI
import Charts

struct BalanceDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let balance: Double
}

struct ChartView: View {
    @State private var balanceHistory: [BalanceDataPoint] = []
    @StateObject var web3RPC: Web3RPC
    @State private var selectedDataPoint: BalanceDataPoint?
    @State private var isLoading = true
    @State private var timeRange: TimeRange = .day

    enum TimeRange: String, CaseIterable {
        case hour = "1H"
        case day = "1D"
        case week = "1W"
        case month = "1M"
    }

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Fetching balance data...")
                } else {
                    VStack(alignment: .leading) {
                        Text("Current Balance")
                            .font(.headline)
                        Text("$\(String(format: "%.2f", balanceHistory.last?.balance ?? 0))")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Chart {
                        ForEach(balanceHistory) { dataPoint in
                            LineMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Balance", dataPoint.balance)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.blue.gradient)
                        }
                        if let selectedDataPoint = selectedDataPoint {
                            RuleMark(x: .value("Selected", selectedDataPoint.timestamp))
                                .foregroundStyle(Color.gray.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            PointMark(
                                x: .value("Selected", selectedDataPoint.timestamp),
                                y: .value("Value", selectedDataPoint.balance)
                            )
                            .foregroundStyle(Color.blue)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.hour().minute(), centered: true)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .currency(code: "USD").precision(.fractionLength(2)))
                        }
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .gesture(DragGesture()
                                    .onChanged { value in
                                        updateSelectedDataPoint(at: value.location, proxy: proxy, geometry: geometry)
                                    }
                                )
                        }
                    }
                    .frame(height: 300)
                    .padding()

                    if let selectedDataPoint = selectedDataPoint {
                        VStack(alignment: .leading) {
                            Text("Selected Balance")
                                .font(.headline)
                            Text("$\(String(format: "%.2f", selectedDataPoint.balance))")
                                .font(.title2)
                            Text(selectedDataPoint.timestamp, style: .date)
                            Text(selectedDataPoint.timestamp, style: .time)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                    }

                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }
            }
            .navigationTitle("USDC Balance Chart")
            .onAppear {
                startMonitoringBalance()
            }
            .onChange(of: timeRange) { _ in
                updateChartData()
            }
        }
    }
    
    private func startMonitoringBalance() {
        isLoading = true
        // Initial balance check
        checkBalance()
        
        // Schedule balance checking every minute
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { timer in
            checkBalance()
        }
    }
    
    private func checkBalance() {
        // Directly use the updated `usdcBalance` from `web3RPC`
        let balance = web3RPC.usdcBalance
        addDataPoint(balance: balance)
        isLoading = false
    }

    private func addDataPoint(balance: Double) {
        let newDataPoint = BalanceDataPoint(timestamp: Date(), balance: balance)
        balanceHistory.append(newDataPoint)
        updateChartData()
    }
    
    private func updateChartData() {
        let calendar = Calendar.current
        let now = Date()
        let filteredHistory: [BalanceDataPoint]
        
        switch timeRange {
        case .hour:
            filteredHistory = balanceHistory.filter { calendar.dateComponents([.minute], from: $0.timestamp, to: now).minute ?? 0 <= 60 }
        case .day:
            filteredHistory = balanceHistory.filter { calendar.dateComponents([.hour], from: $0.timestamp, to: now).hour ?? 0 <= 24 }
        case .week:
            filteredHistory = balanceHistory.filter { calendar.dateComponents([.day], from: $0.timestamp, to: now).day ?? 0 <= 7 }
        case .month:
            filteredHistory = balanceHistory.filter { calendar.dateComponents([.day], from: $0.timestamp, to: now).day ?? 0 <= 30 }
        }
        
        balanceHistory = filteredHistory
    }
    
    private func updateSelectedDataPoint(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
        guard let date = proxy.value(atX: xPosition) as Date? else { return }
        
        if let closestDataPoint = balanceHistory.min(by: { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) }) {
            selectedDataPoint = closestDataPoint
        }
    }
}
