//
//  SearchView.swift
//  CovidGraphs
//
//  Created by Miguel de Icaza on 10/15/20.
//
// From: https://stackoverflow.com/questions/56490963/how-to-display-a-search-bar-with-swiftui/58473985#58473985

import SwiftUI

struct SearchView: View {
    struct Item: Identifiable {
        let id = UUID()
        var code: String = ""
    }

    var array = prettifiedLocations
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    @State private var previewItem: Item?
    
    func filteredArray () -> [Pretty]
    {
        let chunks = searchText.split (separator: " ")
        
        if searchText == "" {
            return array
        }
        return array.filter { element in chunks.allSatisfy { v in element.visible.range (of: v, options: .caseInsensitive) != nil } }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search view
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        
                        TextField("search", text: $searchText, onEditingChanged: { isEditing in
                            self.showCancelButton = true
                        }, onCommit: {
                            print("onCommit")
                        }).foregroundColor(.primary)
                        
                        Button(action: {
                            self.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill").opacity(searchText == "" ? 0 : 1)
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                    .foregroundColor(.secondary)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10.0)
                    
                    if showCancelButton  {
                        Button("Cancel") {
                            UIApplication.shared.endEditing(true) // this must be placed before the other commands here
                            self.searchText = ""
                            self.showCancelButton = false
                        }
                        .foregroundColor(Color(.systemBlue))
                    }
                }
                .padding(.horizontal)
                .navigationBarHidden(showCancelButton) // .animation(.default) // animation does not work properly
                
                List {
                    // Filtered list of names
                    ForEach(filteredArray (), id: \.self) {
                        slot in
                        HStack {
                            Text(slot.visible)
                                .onTapGesture {
                                    self.previewItem = Item (code: slot.code)
                                }
                        }
                    }
                }
                .navigationBarTitle(Text("Search"))
                .resignKeyboardOnDragGesture()
                .sheet(item: $previewItem, onDismiss: { self.previewItem = nil }) {
                    
                        LocationDetailView(stat: fetch (code: $0.code))
                    
                }
            }
        }
    }
}

struct PresentSearchAsSheet: View {
    @Binding var showSearch: Bool
    
    var body: some View {
        VStack {
            ZStack {
                SearchView ()
//                VStack {
//                    HStack {
//                        Spacer ()
//                        Button(action: { self.showSearch = false}) {
//                            Image(systemName: "multiply.circle.fill")
//                                .font(.system(size: 24, weight: .regular))
//                                .padding([.trailing], 10)
//                        }
//                    }
//                    Spacer ()
//                }
            }
        }.padding (.top, 10)
    }
}

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.windows
            .filter{$0.isKeyWindow}
            .first?
            .endEditing(force)
    }
}

struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged{_ in
        UIApplication.shared.endEditing(true)
    }
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

extension View {
    func resignKeyboardOnDragGesture() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
