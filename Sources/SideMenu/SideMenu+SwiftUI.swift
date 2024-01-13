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
import Combine




public class SideMenuViewModel: ObservableObject {

    public var preferences: SideMenuController.Preferences
    
    public var delegate: SideMenuControllerDelegate?
    var emitsHaptics: Bool = true
    
    
    public init(prefs: SideMenuController.Preferences,
                delegate: SideMenuControllerDelegate? = nil) {
        self.preferences = prefs
        self.delegate = delegate
    }
}
extension SideMenuViewModel: SideMenuControllerDelegate {
    public func sideMenuController(_ sideMenuController: SideMenuController,
                            animationControllerFrom fromVC: UIViewController,
                            to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let delegate {
            return delegate.sideMenuController(sideMenuController, animationControllerFrom: fromVC, to: toVC)
        }
        return nil
    }

    public func sideMenuController(_ sideMenuController: SideMenuController,
                            willShow viewController: UIViewController,
                            animated: Bool) {
        delegate?.sideMenuController(sideMenuController, willShow: viewController, animated: animated)
    }
    public func sideMenuController(_ sideMenuController: SideMenuController,
                            didShow viewController: UIViewController,
                            animated: Bool) {
        delegate?.sideMenuController(sideMenuController, didShow: viewController, animated: animated)
    }
    public func sideMenuControllerShouldRevealMenu(_ sideMenuController: SideMenuController) -> Bool {
        if let delegate {
            return delegate.sideMenuControllerShouldRevealMenu(sideMenuController)
        }
        return true
    }
    public func sideMenuControllerWillRevealMenu(_ sideMenuController: SideMenuController) {
        delegate?.sideMenuControllerWillRevealMenu(sideMenuController)
    }
    public func sideMenuControllerDidRevealMenu(_ sideMenuController: SideMenuController) {
        delegate?.sideMenuControllerDidRevealMenu(sideMenuController)
    }
    public func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
        delegate?.sideMenuControllerWillHideMenu(sideMenuController)
    }
    public func sideMenuControllerDidHideMenu(_ sideMenuController: SideMenuController) {
        delegate?.sideMenuControllerDidHideMenu(sideMenuController)
    }
}

/*
 
 #if os(iOS)
 @MainActor
 func hideKeyboard()
 {
     let resign = #selector(UIResponder.resignFirstResponder)
     UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
 }
 */


public struct SideMenuView<R: View, M: View>: View {
    
    let updateToggle: Binding<Bool>
    let root: () -> R
    let menu: () -> M
    
    let model: SideMenuViewModel
    
    let isOpen: Binding<Bool>?
    
    public init(
        _ model: SideMenuViewModel,
        updateToggle: Binding<Bool>,
        isOpen: Binding<Bool>? = nil,
        @ViewBuilder root: @escaping () -> R,
        @ViewBuilder menu:  @escaping () -> M) {
            self.model = model
            self.root = root
            self.menu = menu
            self.isOpen = isOpen
            self.updateToggle = updateToggle
    }
    
    
    public var body: some View {
        SideMenuRepresentable(model: model, updateToggle: updateToggle, root: root, menu: menu)
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
        var sideMenuPreferences: SideMenuController.Preferences {
            model.preferences
        }
        
        @ObservedObject var model: SideMenuViewModel
        
        //updatetoggle
        @Binding var updateToggle: Bool
        
        @Binding var isOpen: Bool
        var shouldRespectIsOpenBinding: Bool
        
        init(model: SideMenuViewModel,
             updateToggle: Binding<Bool> = .constant(false),
             isOpen: Binding<Bool>? = nil,
             @ViewBuilder root: @escaping () -> R,
             @ViewBuilder menu:  @escaping () -> M) {
            self.rootView = root
            self.menuView = menu
            self.model = model
            
            if let isOpen {
                self._isOpen = isOpen
                self.shouldRespectIsOpenBinding = true
                
            } else {
                self._isOpen = .constant(false)
                
                self.shouldRespectIsOpenBinding = false
            }
            
            self._updateToggle = updateToggle
        }
        
        func makeCoordinator() -> Coordinator {
            return Coordinator(self, model: model)
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

            
            if #available(iOS 16.4, *) {
                contentViewController.safeAreaRegions = SafeAreaRegions()
                menuViewController.safeAreaRegions = SafeAreaRegions()
            }
            
            menuViewController.view.backgroundColor = .clear
            context.coordinator.menuViewHost = menuViewController
            
            let sideMenu = SideMenuController(contentViewController: contentViewController,
                                              menuViewController: menuViewController)
//            sideMenu.delegate = context.coordinator.model
            sideMenu.delegate = context.coordinator
            
            return sideMenu
        }
        
        func updateUIViewController(_ uiViewController: SideMenuController, context: Context) {
            // Update the controller as needed
            print("updateUIViewController sidemenurepresentable: shouldRespectIsOpenBinding: \(shouldRespectIsOpenBinding) isOpen: \(isOpen)")
            
            if shouldRespectIsOpenBinding {
                if isOpen != uiViewController.isMenuRevealed {
                    if isOpen {
                        uiViewController.revealMenu(animated: true)
                    } else {
                        uiViewController.hideMenu(animated: true)
                    }
                }
            }
//            uiViewController.contentViewController.view.setNeedsLayout()
//            uiViewController.menuViewController.view.setNeedsLayout()
            
//            context.coordinator.rootViewHost?.rootView = rootView()
//            context.coordinator.menuViewHost?.rootView = menuView()
        }
    }
    
    
    
    class Coordinator: SideMenuControllerDelegate {
        var sideMenuRep: SideMenuRepresentable
        
        var rootViewHost: UIHostingController<R>? = nil
        var menuViewHost: UIHostingController<M>? = nil
        
        var model: SideMenuViewModel
        
        init(_ sideMenuRep: SideMenuRepresentable, 
             model: SideMenuViewModel
        ) {
            self.sideMenuRep = sideMenuRep
            self.model = model
        }
        

        func sideMenuController(_ sideMenuController: SideMenuController, willShow viewController: UIViewController, animated: Bool) {
            print("[Example] View controller will show [\(viewController)]")
            model.sideMenuController(sideMenuController, willShow: viewController, animated: animated)
        }

        func sideMenuController(_ sideMenuController: SideMenuController, didShow viewController: UIViewController, animated: Bool) {
            print("[Example] View controller did show [\(viewController)]")
            model.sideMenuController(sideMenuController, didShow: viewController, animated: animated)

        }

        func sideMenuControllerShouldRevealMenu(_ sideMenuController: SideMenuController) -> Bool {
            print("[Example] Returning true for shouldRevealMenu")
            return true
        }

        func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu will hide")
            self.emitHaptic(willOpen: false)
            model.sideMenuControllerWillHideMenu(sideMenuController)

        }

        func sideMenuControllerDidHideMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu did hide.")
            if sideMenuRep.isOpen && sideMenuRep.shouldRespectIsOpenBinding,
               sideMenuRep.isOpen != false {
                sideMenuRep.isOpen = false
            }
            model.sideMenuControllerDidHideMenu(sideMenuController)

        }

        func sideMenuControllerWillRevealMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu will reveal.")
            self.emitHaptic(willOpen: true)
            model.sideMenuControllerWillRevealMenu(sideMenuController)

        }

        func sideMenuControllerDidRevealMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu did reveal.")
            if sideMenuRep.isOpen && sideMenuRep.shouldRespectIsOpenBinding,
               sideMenuRep.isOpen != true {
                sideMenuRep.isOpen = true
            }
            model.sideMenuControllerDidRevealMenu(sideMenuController)

        }
     
        
        func emitHaptic(willOpen: Bool) {
            if self.model.emitsHaptics {
                let mediumGen = UIImpactFeedbackGenerator(style: .soft)
                mediumGen.impactOccurred()
                
            }
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
        SideMenuView(.init(prefs: .init()),
                     updateToggle: $updateToggle) {
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
        .ignoresSafeArea()
        
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
        .tag(forIdx)
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
