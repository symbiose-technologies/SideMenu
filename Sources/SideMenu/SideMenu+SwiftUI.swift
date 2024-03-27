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

public class GlobalSideMenuViewManager: NSObject {
    public static let shared = GlobalSideMenuViewManager()
    
    public var isMenuOpen: Bool? {
        guard let sideMenuController = sideMenuController else { return nil }
        return sideMenuController.isMenuRevealed
    }
    
    //weak var to a sidemenucontroller
    public var sideMenuController: SideMenuController?
    
    
    public init(sideMenuController: SideMenuController? = nil) {
        self.sideMenuController = sideMenuController
        super.init()
    }
    
    public var menuIsBlocked: Bool = false
    
    public var emitsHaptics: Bool = true
    
    public func setMenuBlocked(_ blocked: Bool) {
        menuIsBlocked = blocked
        if blocked,
           let isMenuOpen = self.isMenuOpen {
            if isMenuOpen {
                self.hideMenu(animated: true)
            }
        }
    }
    
    
    public func setSideMenuController(_ sideMenuController: SideMenuController) {
        self.sideMenuController = sideMenuController
        sideMenuController.delegate = self
    }
    
    // MARK: Reveal/Hide Menu
    
    /// Reveals the menu.
    ///
    /// - Parameters:
    ///   - animated: If set to true, the process will be animated. The default is true.
    ///   - completion: Completion closure that will be executed after revealing the menu.
    @discardableResult
    public func revealMenu(animated: Bool = true, skipIfShown: Bool = true, completion: ((Bool) -> Void)? = nil) -> Bool {
        guard let sideMenuController = sideMenuController else { return false }
        if skipIfShown && sideMenuController.isMenuRevealed { return false }
        
        sideMenuController.revealMenu(animated: animated, completion: completion)
        return true
    }
    
    /// Hides the menu.
    ///
    /// - Parameters:
    ///   - animated: If set to true, the process will be animated. The default is true.
    ///   - completion: Completion closure that will be executed after hiding the menu.
    @discardableResult
    public func hideMenu(animated: Bool = true, skipIfHidden: Bool = true, completion: ((Bool) -> Void)? = nil) -> Bool {
        guard let sideMenuController = sideMenuController else { return false }
        if skipIfHidden && !sideMenuController.isMenuRevealed { return false }
        
        sideMenuController.hideMenu(animated: animated, completion: completion)
        return true
    }
    
}


extension GlobalSideMenuViewManager: SideMenuControllerDelegate {
    public func sideMenuController(_ sideMenuController: SideMenuController,
                            animationControllerFrom fromVC: UIViewController,
                            to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return nil
    }

    public func sideMenuController(_ sideMenuController: SideMenuController,
                            willShow viewController: UIViewController,
                            animated: Bool) {

    }
    public func sideMenuController(_ sideMenuController: SideMenuController,
                            didShow viewController: UIViewController,
                            animated: Bool) {

    }
    
    public func sideMenuControllerShouldRevealMenu(_ sideMenuController: SideMenuController) -> Bool {
        if self.menuIsBlocked {
            return false
        }
        return true
    }
    
    public func sideMenuControllerWillRevealMenu(_ sideMenuController: SideMenuController) {
        self.emitHaptic(willOpen: true)
    }
    public func sideMenuControllerDidRevealMenu(_ sideMenuController: SideMenuController) {
    }
    public func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
        self.emitHaptic(willOpen: false)
    }
    public func sideMenuControllerDidHideMenu(_ sideMenuController: SideMenuController) {

    }
    
    
       
   func emitHaptic(willOpen: Bool) {
       if self.emitsHaptics {
           let mediumGen = UIImpactFeedbackGenerator(style: .soft)
           mediumGen.impactOccurred()
       }
   }
}


public class SideMenuViewModel: ObservableObject {

    public var preferences: SideMenuController.Preferences
    
    public var delegate: SideMenuControllerDelegate?
    var emitsHaptics: Bool = true
    var useGlobalManager: Bool
    
    public init(prefs: SideMenuController.Preferences,
                delegate: SideMenuControllerDelegate? = nil,
                useGlobalManager: Bool = true) {
        self.preferences = prefs
        self.delegate = delegate
        self.useGlobalManager = useGlobalManager
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
//            .ignoresSafeArea(.keyboard, edges: .all)
//            .ignoresSafeArea(.container, edges: .bottom)
//            .ignoresSafeArea()
        
    }
    
    struct SideMenuRepresentable: UIViewControllerRepresentable {
        typealias UIViewControllerType = SideMenuController
        
        var rootView: () -> R
        var menuView: () -> M
        var sideMenuPreferences: SideMenuController.Preferences {
            model.preferences
        }
        
        var model: SideMenuViewModel
        
        //updatetoggle
        @Binding var updateToggle: Bool
        
        init(model: SideMenuViewModel,
             updateToggle: Binding<Bool> = .constant(false),
             @ViewBuilder root: @escaping () -> R,
             @ViewBuilder menu:  @escaping () -> M) {
            self.rootView = root
            self.menuView = menu
            self.model = model
            
            self._updateToggle = updateToggle
        }
        
        func makeCoordinator() -> Coordinator {
            return Coordinator(self, model: model)
        }
        
        func makeUIViewController(context: Context) -> SideMenuController {
            //set the preferences
            SideMenuController.preferences = sideMenuPreferences
            
            let contentViewController = UIHostingController(rootView: rootView())
            contentViewController.view.backgroundColor = .clear
            context.coordinator.rootViewHost = contentViewController
            
            let menuViewController = UIHostingController(rootView: menuView())

            
            if #available(iOS 16.4, *) {
//                contentViewController.safeAreaRegions = SafeAreaRegions()
//                menuViewController.safeAreaRegions = SafeAreaRegions()
//                contentViewController.safeAreaRegions = .keyboard
                menuViewController.safeAreaRegions = .keyboard
            }
            if #available(iOS 16.0, *) {
                menuViewController.sizingOptions = .intrinsicContentSize
            }
            
            menuViewController.view.backgroundColor = .clear
            
            
            context.coordinator.menuViewHost = menuViewController
            
            
            let sideMenu = SideMenuController(contentViewController: contentViewController,
                                              menuViewController: menuViewController)
            
            
            
            if model.useGlobalManager {
                GlobalSideMenuViewManager.shared.setSideMenuController(sideMenu)
            } else {
                sideMenu.delegate = context.coordinator
            }
            
            
            return sideMenu
        }
        
        func updateUIViewController(_ uiViewController: SideMenuController, context: Context) {
            // Update the controller as needed
//            if updateToggle {
//                uiViewController.toggleMenu(animated: true)
//                self.updateToggle = false
//            }
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
            model.delegate?.sideMenuController(sideMenuController, willShow: viewController, animated: animated)
        }

        func sideMenuController(_ sideMenuController: SideMenuController, didShow viewController: UIViewController, animated: Bool) {
            print("[Example] View controller did show [\(viewController)]")
            model.delegate?.sideMenuController(sideMenuController, didShow: viewController, animated: animated)

        }

        func sideMenuControllerShouldRevealMenu(_ sideMenuController: SideMenuController) -> Bool {
            print("[Example] Returning true for shouldRevealMenu")
            return true
        }

        func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu will hide")
            self.emitHaptic(willOpen: false)
            model.delegate?.sideMenuControllerWillHideMenu(sideMenuController)
        }

        func sideMenuControllerDidHideMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu did hide.")
            
            model.delegate?.sideMenuControllerDidHideMenu(sideMenuController)

        }

        func sideMenuControllerWillRevealMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu will reveal.")
            self.emitHaptic(willOpen: true)
            model.delegate?.sideMenuControllerWillRevealMenu(sideMenuController)

        }

        func sideMenuControllerDidRevealMenu(_ sideMenuController: SideMenuController) {
            print("[Example] Menu did reveal.")
            
            model.delegate?.sideMenuControllerDidRevealMenu(sideMenuController)

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
        if #available(iOS 16.0, *) {
            SideMenuTester_SUI($selection)
        } else {
            // Fallback on earlier versions
            Text("Hello world")
        }
    }
    
}

@available(iOS 16.0, *)
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
    
    @State var textInput: String = ""
    
    @ViewBuilder
    func testTabContent(_ forIdx: Int) -> some View {
        NavigationView {
            VStack {
                Text("Tab: \(forIdx)")
                    .font(.largeTitle)
                
                
                ScrollView {
                    ForEach(0..<50) { i in
                        HStack {
                            Text("Item \(i)")
                            Spacer()
                        }
                    }
                    TextField("Hello world", text: $textInput, prompt: nil, axis: .vertical)
                    
                    
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
