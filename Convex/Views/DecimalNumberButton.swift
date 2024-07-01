//
//  DecimalNumberButton.swift
//  Convex
//
//  Created by Matt Daigle on 6/30/24.
//

import SwiftUI

struct DecimalNumberButton: View {
    
    @State var viewModel: NumberButtonViewModel
    @State var width: CGFloat = .zero
    
    var body: some View {
        Button {
            print("\(viewModel.value) button pressed")
        } label: {
            Text(viewModel.title)
                .frame(maxWidth: .infinity)
                .frame(height: width)
                .onSizeChange { size in
                    width = size.width
                }
        }
        .buttonStyle(NumberButtonStyle(base: .decimal, size: width))
    }
}

#Preview {
    DecimalNumberButton(viewModel: .init(value: 9))
}
