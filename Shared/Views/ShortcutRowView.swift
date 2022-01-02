//
//  ContentView.swift
//  Shared
//
//  Created by Tomas Reimers on 12/26/21.
//

import SwiftUI

struct ShortcutRowView: View {
    var shortcut: Shortcut
    var body: some View {
        HStack {
            Text(shortcut.name)
                .foregroundColor(.black)
        }
    }
}
