//
//  ContentView.swift
//  PhotoDelete
//
//  Created by jackie xiao on 11/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager()

    var body: some View {
        MainTabView()
            .environmentObject(dataManager)
    }
}

#Preview {
    ContentView()
}
