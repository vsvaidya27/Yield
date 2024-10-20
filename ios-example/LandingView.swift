//
//  LandingView.swift
//  ios-example
//
//  Created by Varun Vaidya on 10/20/24.
//

import SwiftUI

struct LandingView: View {
    @Binding var showLoginView: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Find the Best\nRates in 1 Click\nwith")
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("YIELD")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.blue)
            
            Text("The RobinHood of Finance")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            
            Spacer()
                .frame(height: 20)  // Add some space before the image
            
            Image("Robinhood")
                .resizable()
                .scaledToFit()
                .frame(height: 250)  // Increased height from 200 to 250
            
            Spacer()
                .frame(height: 30)  // Add some space after the image
            
            Button(action: {
                showLoginView = true
            }) {
                HStack {
                    Text("Let's start")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()  // This will push the button up if there's extra space
        }
        .padding()
    }
}
