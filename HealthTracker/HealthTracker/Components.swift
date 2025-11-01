//
//  Components.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/21/25.
//

import SwiftUI

struct CardView<Content: View>: View {

    @ViewBuilder var content: Content
    @Binding var backgroundColor: Color?

    private let internalPadding: EdgeInsets
    private let applyGlassEffect: Bool
    private let action: (() -> Void)?

    init(internalPadding: EdgeInsets? = nil, applyGlassEffect: Bool = true, backgroundColor: Binding<Color?> = .constant(nil), action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.internalPadding = internalPadding ?? EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        self.action = action
        self.applyGlassEffect = applyGlassEffect
        self._backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        Button(action: action ?? {}, label: {
            content
                .padding(internalPadding)
                .if(applyGlassEffect, transform: { view in
                    view
                        .glassEffect(in: .rect(cornerRadius: 16))
                })
                .background(backgroundColor)
                .cornerRadius(applyGlassEffect ? 0 : 16)
        })
        .buttonStyle(.plain)
    }
}

struct HeaderListView: View {

    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .bold()
            Spacer()
            Button("", systemImage: icon, action: action)
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
    }
}

struct CardListView<Content: View>: View {

    @ViewBuilder var content: Content

    let isFirst: Bool
    let isUnique: Bool
    let action: (() -> Void)?

    init(isFirst: Bool = false, isUnique: Bool = false, action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.isFirst = isFirst
        self.isUnique = isUnique
        self.action = action
        self.content = content()
    }

    var body: some View {
        CardView {
            HStack {
                content
                Spacer()
            }
        }
        .if(isUnique, transform: { view in
            view
                .frame(width: UIScreen.main.bounds.width-40)
        })
        .if(!isUnique, transform: { view in
            view
                .frame(maxWidth: UIScreen.main.bounds.width-40)
        })
        .if(action != nil, transform: { view in
            view
                .onTapGesture(count: 2) {
                    action?()
                }
        })
        .padding(.leading, isFirst ? 20 : 0)
    }
}
