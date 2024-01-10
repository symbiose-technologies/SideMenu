//////////////////////////////////////////////////////////////////////////////////
//
//  SYMBIOSE
//  Copyright 2023 Symbiose Technologies, Inc
//  All Rights Reserved.
//
//  NOTICE: This software is proprietary information.
//  Unauthorized use is prohibited.
//
// SideMenu
// Created by: Ryan Mckinney on 1/10/24
//
////////////////////////////////////////////////////////////////////////////////

import Foundation
import SwiftUI


public struct SideMenuView<R: View, M: View>: View {
    
    let updateToggle: Binding<Bool>
    let root: () -> R
    let menu: () -> M
    
    let menuPrefs: SideMenuController.Preferences
    
    public init(
        _ preferences: SideMenuController.Preferences,
        updateToggle: Binding<Bool>,
        @ViewBuilder root: @escaping () -> R,
        @ViewBuilder menu:  @escaping () -> M) {
            self.menuPrefs = preferences
            self.root = root
            self.menu = menu
            self.updateToggle = updateToggle
    }
    
    
    public var body: some View {
        SideMenuRepresentable(preferences: menuPrefs, updateToggle: updateToggle, root: root, menu: menu)
    }
    
    struct EmbedSwiftUIView<Content: View> : UIViewControllerRepresentable {

        var content: () -> Content

        func makeUIViewController(context: Context) -> UIHostingController<Content> {
            let hostingController = UIHostingController(rootView: content())
            hostingController.view.backgroundColor = .clear
            return hostingController
            
        }

        func updateUIViewController(_ host: UIHostingController<Content>, context: Context) {
            host.rootView = content() // Update content
        }
    }
    
    struct SideMenuRepresentable: UIViewControllerRepresentable {
        typealias UIViewControllerType = SideMenuController
        
        var rootView: () -> R
        var menuView: () -> M
        var sideMenuPreferences: SideMenuController.Preferences
        
        //updatetoggle
        @Binding var updateToggle: Bool
        
        init(preferences: SideMenuController.Preferences,
             updateToggle: Binding<Bool> = .constant(false),
             @ViewBuilder root: @escaping () -> R,
             @ViewBuilder menu:  @escaping () -> M) {
            self.rootView = root
            self.menuView = menu
            self.sideMenuPreferences = preferences
            self._updateToggle = updateToggle
        }
        
        func makeCoordinator() -> Coordinator {
            return Coordinator(self)
        }
        
        func makeUIViewController(context: Context) -> SideMenuController {
            //set the preferences
            SideMenuController.preferences = sideMenuPreferences
            
//            let contentVc = EmbedSwiftUIView(content: rootView)
//            let menuVc = EmbedSwiftUIView(content: menuView)
           
            
            let contentViewController = UIHostingController(rootView: rootView())
            contentViewController.view.backgroundColor = .clear
            
            context.coordinator.rootViewHost = contentViewController
            
            let menuViewController = UIHostingController(rootView: menuView())
            menuViewController.view.backgroundColor = .clear
            context.coordinator.menuViewHost = menuViewController
            
            let sideMenu = SideMenuController(contentViewController: contentViewController,
                                              menuViewController: menuViewController)
            sideMenu.delegate = context.coordinator
            
            return sideMenu
        }
        
        func updateUIViewController(_ uiViewController: SideMenuController, context: Context) {
            // Update the controller as needed
            print("updateUIViewController sidemenurepresentable")
            
//            uiViewController.contentViewController.view.setNeedsLayout()
//            uiViewController.menuViewController.view.setNeedsLayout()

            
            context.coordinator.rootViewHost?.rootView = rootView()
            context.coordinator.menuViewHost?.rootView = menuView()
        }
    }
    
    
    
    class Coordinator: SideMenuControllerDelegate {
        var sideMenuRep: SideMenuRepresentable
        
        var rootViewHost: UIHostingController<R>? = nil
        var menuViewHost: UIHostingController<M>? = nil
        
        
        init(_ sideMenuRep: SideMenuRepresentable) {
            self.sideMenuRep = sideMenuRep
        }
        
//        func sideMenuController(_ sideMenuController: SideMenuController,
//                                animationControllerFrom fromVC: UIViewController,
//                                to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//            return BasicTransitionAnimator(options: .transitionFlipFromLeft, duration: 0.6)
//        }

        func sideMenuController(_ sideMenuController: SideMenuController, willShow viewController: UIViewController, animated: Bool) {
            print("[Example] View controller will show [\(viewController)]")
        }

        func sideMenuController(_ sideMenuController: SideMenuController, didShow viewController: UIViewController, animated: Bool) {
            print("[Example] View controller did show [\(viewController)]")
        }

        func sideMenuControllerShouldRevealMenu(_ sideMenuController: SideMenuController) -> Bool {
            print("[Example] Returning true for shouldRevealMenu")
            return true
        }

        func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu will hide")
        }

        func sideMenuControllerDidHideMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu did hide.")
        }

        func sideMenuControllerWillRevealMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu will reveal.")
        }

        func sideMenuControllerDidRevealMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu did reveal.")
        }
        
    }
    
    
    
    
    
}


public struct SideMenuTester_SUIContainer: View {
    
    @State var selection: Int = 0
    public init() {
        
    }
    public var body: some View {
        SideMenuTester_SUI($selection)
    }
    
}

public struct SideMenuTester_SUI: View {
    
    @Binding var selection: Int
    
    @State var updateToggle: Bool = false
    
    public init(_ selection: Binding<Int>) {
        self._selection = selection
    }
    
    public var body: some View {
        SideMenuView(.init(), updateToggle: $updateToggle) {
            TabView(selection: $selection) {
                testTabContent(0)
                testTabContent(1)
                testTabContent(2)
                testTabContent(3)
            }
            
        } menu: {
            MenuTestView { newTabSel in
                selection = newTabSel
            }
        }
        .onChange(of: selection, perform: { value in
            print("OnChangeOfTab: \(value)")
            updateToggle.toggle()
        })
    }

    @ViewBuilder
    func changeTabBtn(_ changeToIdx: Int) -> some View {
        Button {
            selection = changeToIdx
        } label: {
            Text("Change Tab \(changeToIdx)")
        }
    }
    
    
    @ViewBuilder
    func testTabContent(_ forIdx: Int) -> some View {
        NavigationView {
            VStack {
                Text("Tab: \(forIdx)")
                    .font(.largeTitle)
                
                
                ScrollView {
                    ForEach(0..<200) { i in
                        HStack {
                            Text("Item \(i)")
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .tabItem {
            Label("\(forIdx)", systemImage: "tray.and.arrow.up.fill")
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
    SideMenuTester_SUIContainer()
}
