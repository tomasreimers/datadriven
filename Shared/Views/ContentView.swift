//
//  ContentView.swift
//  Shared
//
//  Created by Tomas Reimers on 12/26/21.
//

import SwiftUI

struct ContentView: View {
    @StateObject var persistence = Persistence()
    
    @State var newShortcutName: String = ""
    @State var newShortcutURL: String = ""
    @State var newShortcutKey: String = ""
        
    var body: some View {
        NavigationView {
            List {
                // The various cell types could be extracted.
                Section(header: Text("Create new data source")) {
                    HStack {
                        VStack{
                            TextField("Name", text: $newShortcutName)
                            TextField("URL", text: $newShortcutURL)
                            TextField("Key", text: $newShortcutKey)
                        }
                        
                        if (self.newShortcutName.count > 0 && self.newShortcutKey.count > 0 && self.newShortcutURL.count > 0) {
                            Button(action: {
                                Task {
                                    await persistence.createShortcut(shortcut: Shortcut(id: UUID().uuidString, name: self.newShortcutName, url: self.newShortcutURL, key: self.newShortcutKey))
                                    self.newShortcutName = ""
                                    self.newShortcutURL = ""
                                    self.newShortcutKey = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Color.green).imageScale(.large)
                            }
                        }
                    }
                }
                
                Section(header: Text("Saved data sources")) {
                    ForEach(persistence.shortcuts, id: \.id) { shortcut in
                            ShortcutRowView(shortcut: shortcut)
                    }
                    .onDelete(perform: deleteShortcuts(at:))
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text("Data sources"))
            .navigationBarItems(trailing: Button("Sync to watch") {
                Task {
                    await persistence.sendToWatch()
                }
            })
            .task {
                await persistence.loadFromDisk()
            }
        }
    }
    
    func deleteShortcuts(at indexSet: IndexSet) {
        indexSet.forEach { shortcutIdx in
            let shortcut = persistence.shortcuts[shortcutIdx]
            
            Task {
                await persistence.deleteShortcut(id: shortcut.id)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
