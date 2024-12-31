//
//  ViewExtensions.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/7/24.
//

import SwiftUI

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
