//////////////////////////////////////////////////////////////////////////////////
//
//  SYMBIOSE
//  Copyright 2023 Symbiose Technologies, Inc
//  All Rights Reserved.
//
//  NOTICE: This software is proprietary information.
//  Unauthorized use is prohibited.
//
// SwiftUITest
// Created by: Ryan Mckinney on 3/1/24
//
////////////////////////////////////////////////////////////////////////////////

import SwiftUI
import SideMenu


struct ContentView: View {
    @State var selection: Int = 0

    var body: some View {
        SideMenuTesterViewSUI($selection)
    }
}


public struct SideMenuTesterViewSUI: View {
    
    @Binding var selection: Int
    
    @State var updateToggle: Bool = false
    
    public init(_ selection: Binding<Int>) {
        self._selection = selection
    }
    
    public var body: some View {
        SideMenuView(.init(prefs: .init()),
                     updateToggle: $updateToggle) {
            
            mainContent
            
        } menu: {
            MenuTestView { newTabSel in
                selection = newTabSel
            }
        }
//        .onChange(of: selection, perform: { value in
//            print("OnChangeOfTab: \(value)")
//            updateToggle.toggle()
//        })
//        .ignoresSafeArea()
        .background(Color.blue.opacity(0.5))
        
    }
    
    @State var scrolledTab: Int? = nil
    
    @ViewBuilder
    var mainContent: some View {
        ZStack {
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 0) {
                        ForEach(0..<4) { index in
                            TestTabContent(idx: index)
                                .id(index)
                                .containerRelativeFrame(.horizontal)
                                .scrollContentBackground(.visible)
                                .scrollDisabled(false)
                        }
                        .scrollTargetLayout(isEnabled: true)
                    }
                }
                .scrollPosition(id: $scrolledTab, anchor: .center)
                .scrollClipDisabled(true)
                .scrollContentBackground(.hidden)
                .scrollTargetBehavior(.paging)
                .scrollDisabled(true)
                
                .onChange(of: selection, initial: true) {
                    scrolledTab = selection
                    //                            withAnimation {
    //                                scrollProxy.scrollTo(newSelTab, anchor: .center)
    //                            }
                }
                .onChange(of: scrolledTab) { viewScrolledTab in

                    if let scrolledTab = viewScrolledTab,
                       scrolledTab != selection {
                        
                    }
                    
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 30) {
                ForEach(0..<4) { idx in
                    Button {
                        withAnimation {
                            scrolledTab = idx
                        }
                    } label: {
                        Text("Tab \(idx)")
                    }
                }
                .controlSize(.extraLarge)
            }
            .background(Color.yellow)
            .ignoresSafeArea(.keyboard, edges: .all)
        }
//        .background(Color.green)
        
    }
    

    @ViewBuilder
    func changeTabBtn(_ changeToIdx: Int) -> some View {
        Button {
            selection = changeToIdx
        } label: {
            Text("Change Tab \(changeToIdx)")
        }
    }
    
    struct TestTabContent: View {
        var idx: Int
        @State var textInput: String = ""

        @State var scrolledId: String? = nil
        
        var body: some View {
            NavigationView {
                ZStack {
                    VStack {
                        Text("Tab: \(idx)")
                            .font(.largeTitle)
                        
                        ScrollView {
                            LazyVStack {
                                ForEach(0..<50) { i in
                                    HStack {
                                        Text("Item \(i)")
                                        Spacer()
                                    }
                                    .id("\(idx)-Item-\(i)")
                                }
                            }
                            .scrollTargetLayout(isEnabled: true)
                        }
    //                    .defaultScrollAnchor(.bottom)
                        .scrollPosition(id: $scrolledId, anchor: .bottom)
                    }
                    .padding()
                    .safeAreaInset(edge: .bottom) {
                        textInputBar
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
            }
        }
        
        var textInputBar: some View {
            HStack(alignment: .bottom, spacing: 8) {
                Button {
                    
                } label: {
                    Image(systemName: "plus")
                }
                .symbolEffect(.bounce, value: scrolledId)
                
                TextField("Hello world", text: $textInput, prompt: nil, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .background(Color.gray.opacity(0.5).gradient, in: RoundedRectangle(cornerRadius: 16.0, style: .continuous))
                
                Button {
                    
                } label: {
                    Image(systemName: "arrow.up")
                }
                .symbolEffect(.pulse, value: textInput)
                
            }
            .padding(.bottom, 16.0)
            .background(Material.ultraThin)
            
        }
        
    }
    
    
    
    struct MenuTestView: View {
        var tabSelectionCb: (Int) -> Void
        init(_ tabSelection: @escaping (Int) -> Void) {
            self.tabSelectionCb = tabSelection
        }
        
        
        var body: some View {
            content
        }
        
        var content: some View {
            VStack {
                HStack {
                    Text("Menu!")
                    Spacer()
                }
                VStack {
                    changeTabBtn(0)
                    changeTabBtn(1)
                    changeTabBtn(2)
                    changeTabBtn(3)
                }
                
                ScrollView {
                    ForEach(0..<200) { i in
                        Text("Menu Item \(i)")
                    }
                }
            }
            .background(Color.red.opacity(0.5))
            .ignoresSafeArea(.container, edges: .all)
        }
        
        
        @ViewBuilder
        func changeTabBtn(_ changeToIdx: Int) -> some View {
            Button {
                tabSelectionCb(changeToIdx)
            } label: {
                Text("Change Tab \(changeToIdx)")
            }
        }
        
    }
}

#Preview {
    ContentView()
}
