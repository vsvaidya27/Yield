//
//  HomeViewModel.swift
//  ios-example
//
//  Created by Varun Vaidya on 10/19/24.
//

import SwiftUI
import Foundation

// ViewModel to handle fetching data
class HomeViewModel: ObservableObject {
    @Published var errorMessage: String?
}

