//
//  NotificationToggleStyle.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 2/16/23.
//

import SwiftUI

struct SymbolToggleStyle: ToggleStyle {
    
    var systemImage: String = "checkmark"
    var activeColor: Color = .green
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            
            RoundedRectangle(cornerRadius: 30)
                .fill(configuration.isOn ? activeColor : Color(.systemGray5))
                .overlay {
                    Circle()
                        .fill(.white)
                        .padding(2)
                        .overlay {
                            Image(systemName: systemImage)
                                .resizable()
                                .foregroundColor(configuration.isOn ? activeColor : Color(.systemGray5))
                        }
                        .offset(x: configuration.isOn ? 10 : -10)
                }
                .frame(width: 50, height: 32)
                .onTapGesture {
                    withAnimation(.spring()) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}
