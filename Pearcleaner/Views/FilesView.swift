//
//  FilesView.swift
//  Pearcleaner
//
//  Created by Alin Lupascu on 11/1/23.
//

import Foundation
import SwiftUI

struct FilesView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locations: Locations
    @State private var showPop: Bool = false
    @AppStorage("settings.general.mini") private var mini: Bool = false
    @AppStorage("settings.sentinel.enable") private var sentinel: Bool = false
    @AppStorage("settings.general.instant") var instantSearch: Bool = true
    @AppStorage("settings.general.brew") private var brew: Bool = false
    @AppStorage("settings.menubar.enabled") private var menubarEnabled: Bool = false
    @AppStorage("settings.general.selectedSort") var selectedSortAlpha: Bool = true
    @Environment(\.colorScheme) var colorScheme
    @Binding var showPopover: Bool
    @Binding var search: String
    var regularWin: Bool
//    @State private var selectedOption = "Alpha"
    @State private var elapsedTime = 0
    @State private var timer: Timer? = nil
    
    var body: some View {


        let totalSelectedSize = appState.selectedItems.reduce(Int64(0)) { (result, url) in
            result + (appState.appInfo.fileSize[url] ?? 0)
        }

        VStack(alignment: .center) {
            if appState.showProgress {
                VStack {
                    Spacer()
                    Text("Searching the file system").font(.title3)
                        .foregroundStyle((Color("mode").opacity(0.5)))

                    ProgressView()
                        .progressViewStyle(.linear)
                        .frame(width: 400, height: 10)

                    Text("\(elapsedTime)")
                        .font(.title).monospacedDigit()
                        .foregroundStyle((Color("mode").opacity(0.5)))
                        .opacity(elapsedTime == 0 ? 0 : 1)
                        .contentTransition(.numericText())

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
                .onAppear {
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        withAnimation {
                            self.elapsedTime += 1
                        }
                    }
                }
                .onDisappear {
                    self.timer?.invalidate()
                    self.timer = nil
                    self.elapsedTime = 0
                }
            } else {
                // Titlebar
                if !regularWin {
                    HStack(spacing: 0) {

                        Spacer()

                        if instantSearch {
                            Button("Rescan") {
                                updateOnMain {
                                    appState.showProgress.toggle()
                                    let pathFinder = AppPathFinder(appInfo: appState.appInfo, appState: appState, locations: locations) {
                                        updateOnMain {
                                            appState.showProgress = false
                                        }
                                    }
                                    pathFinder.findPaths()
                                }
                            }
                            .buttonStyle(SimpleButtonStyle(icon: "arrow.counterclockwise.circle.fill", help: "Rescan files"))
                        }


                        Button("Close") {
                            updateOnMain {
                                appState.appInfo = AppInfo.empty
                                search = ""
                                appState.currentView = .apps
                                showPopover = false
                            }
                        }
                        .buttonStyle(SimpleButtonStyle(icon: "x.circle.fill", help: "Close"))
                    }
                    .padding([.horizontal, .top], 5)
                }
                VStack(spacing: 0) {
                    
                    // Main Group
                    HStack(alignment: .center) {

                        //app icon, title, size and items
                        VStack(alignment: .center) {
                            HStack(alignment: .center) {
                                if let appIcon = appState.appInfo.appIcon {
                                    Image(nsImage: appIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
//                                        .clipShape(RoundedRectangle(cornerRadius: 8))
//                                        .padding(.trailing)
                                        .padding()
                                        .background{
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color((appState.appInfo.appIcon?.averageColor)!))

                                        }
                                }

                                VStack(alignment: .leading, spacing: 5){
                                    HStack {
                                        Text("\(appState.appInfo.appName)").font(.title).fontWeight(.bold).lineLimit(1)
                                        Text("•").foregroundStyle(Color("AccentColor"))
                                        Text("\(appState.appInfo.appVersion)").font(.title3)
                                        if appState.appInfo.appName.count < 5 {
                                            InfoButton(text: "Pearcleaner searches for files via a combination of bundle id and app name. \(appState.appInfo.appName) has a common or short app name so there might be unrelated files found. Please check the list thoroughly before uninstalling.", color: nil, label: "")
                                        }

                                    }
                                    Text("\(appState.appInfo.bundleIdentifier)")
                                        .lineLimit(1)
                                        .font(.title3)
                                        .foregroundStyle((Color("mode").opacity(0.5)))
                                }
                                .padding(.leading)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 5) {
                                    Text("\(formatByte(size: appState.appInfo.totalSize))").font(.title).fontWeight(.bold)
                                    Text("\(appState.appInfo.fileSize.count == 1 ? "\(appState.selectedItems.count) / \(appState.appInfo.fileSize.count) item" : "\(appState.selectedItems.count) / \(appState.appInfo.fileSize.count) items")")
                                        .font(.callout).foregroundStyle((Color("mode").opacity(0.5)))
                                }

                            }

                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 0)
                        
                    }


                    // Item selection and sorting toolbar
                    HStack() {
                        Toggle("", isOn: Binding(
                            get: { self.appState.selectedItems.count == self.appState.appInfo.files.count },
                            set: { newValue in
                                updateOnMain {
                                    self.appState.selectedItems = newValue ? Set(self.appState.appInfo.files) : []
                                }
                            }
                        ))


                        Spacer()


                        HStack(alignment: .center, spacing: 10) {

                            if appState.appInfo.webApp {
                                Text("web")
                                    .font(.footnote)
                                    .foregroundStyle(Color("mode").opacity(0.5))
                                    .frame(minWidth: 30, minHeight: 15)
                                    .padding(2)
                                    .background(Color("mode").opacity(0.1))
                                    .clipShape(.capsule)

                            }

                            if appState.appInfo.wrapped {
                                Text("iOS")
                                    .font(.footnote)
                                    .foregroundStyle(Color("mode").opacity(0.5))
                                    .frame(minWidth: 30, minHeight: 15)
                                    .padding(2)
                                    .background(Color("mode").opacity(0.1))
                                    .clipShape(.capsule)

                            }

                            Text(appState.appInfo.system ? "system" : "user")
                                .font(.footnote)
                                .foregroundStyle(Color("mode").opacity(0.5))
                                .frame(minWidth: 30, minHeight: 15)
                                .padding(2)
                                .padding(.horizontal, 2)
                                .background(Color("mode").opacity(0.1))
                                .clipShape(.capsule)
                        }


                        Spacer()

                        Button("") {
                            selectedSortAlpha.toggle()
//                            selectedOption = selectedOption == "Alpha" ? "Size" : "Alpha"
                        }
                        .buttonStyle(SimpleButtonStyle(icon: selectedSortAlpha ? "textformat.abc" : "textformat.123", help: selectedSortAlpha ? "Sorted alphabetically" : "Sorted by size"))

                    }
                    .padding()



                    Divider()
                        .padding(.horizontal)



                    ScrollView() {
                        LazyVStack {
                            let sortedFilesSize = appState.appInfo.files.sorted(by: { appState.appInfo.fileSize[$0, default: 0] > appState.appInfo.fileSize[$1, default: 0] })

//                            let sortedFilesAlpha = appState.appInfo.files
                            let sortedFilesAlpha = appState.appInfo.files.sorted { firstURL, secondURL in
                                let isFirstPathApp = firstURL.pathExtension == "app"
                                let isSecondPathApp = secondURL.pathExtension == "app"
                                if isFirstPathApp, !isSecondPathApp {
                                    return true // .app extension always comes first
                                } else if !isFirstPathApp, isSecondPathApp {
                                    return false
                                } else {
                                    // If neither or both are .app, sort alphabetically
                                    return firstURL.lastPathComponent.pearFormat() < secondURL.lastPathComponent.pearFormat()
                                }
                            }

                            let sort = selectedSortAlpha ? sortedFilesAlpha : sortedFilesSize

                            ForEach(Array(sort.enumerated()), id: \.element) { index, path in
                                if let fileSize = appState.appInfo.fileSize[path], let fileIcon = appState.appInfo.fileIcon[path] {
                                    let iconImage = fileIcon.map(Image.init(nsImage:))
                                    VStack {
                                        FileDetailsItem(size: fileSize, icon: iconImage, path: path)
                                        if index < sort.count - 1 {
                                            Divider().padding(.leading, 40).opacity(0.5)
                                        }
                                    }
                                }
                            }

                        }
                        .padding()
                    }


                    Spacer()

                    HStack() {

                        Spacer()

                        Button("\(formatByte(size: totalSelectedSize))") {
                            Task {
                                updateOnMain {
                                    search = ""
                                    if !regularWin {
                                        appState.currentView = .apps
                                        showPopover = false
                                    } else {
                                        appState.currentView = .empty
                                    }
                                }
                                let selectedItemsArray = Array(appState.selectedItems)

                                killApp(appId: appState.appInfo.bundleIdentifier) {
                                    moveFilesToTrash(at: selectedItemsArray) {
                                        withAnimation {
                                            showPopover = false
                                            updateOnMain {
                                                appState.currentView = mini ? .apps : .empty
                                                appState.isReminderVisible.toggle()
                                            }
                                            if sentinel {
                                                launchctl(load: true)
                                            }
                                        }

                                        // Brew cleanup if enabled
                                        if brew {
                                            caskCleanup(app: appState.appInfo.appName)
                                        }

                                        // Remove app from app list if main app bundle is removed
                                        if selectedItemsArray.contains(where: { $0.absoluteString == appState.appInfo.path.absoluteString }) {
                                            removeApp(appState: appState, withId: appState.appInfo.id)
                                        } else {
                                            // Add deleted appInfo object to trashed array
                                            appState.appInfo.files = []
                                            appState.appInfo.fileSize = [:]
                                            appState.trashedFiles.append(appState.appInfo)

                                            // Clear out appInfoStore object
                                            if let index = appState.appInfoStore.firstIndex(where: { $0.path == appState.appInfo.path }) {
                                                appState.appInfoStore[index] = .empty
                                            }
                                        }
                                        appState.appInfo = AppInfo.empty
                                    }
                                }

                            }

                        }
                        .buttonStyle(UninstallButton(isEnabled: !appState.selectedItems.isEmpty))
                        .disabled(appState.selectedItems.isEmpty)
                        .padding(.top)


//                        Spacer()

                    }

                }
                .transition(.opacity)
                .padding([.horizontal, .bottom], 20)
                .padding(.top, !mini ? 10 : 0)

            }

        }
    }

}



struct FileDetailsItem: View {
    @EnvironmentObject var appState: AppState
    let size: Int64?
    let icon: Image?
    let path: URL

    var body: some View {

        HStack(alignment: .center, spacing: 20) {
            Toggle("", isOn: Binding(
                get: { self.appState.selectedItems.contains(self.path) },
                set: { isChecked in
                    if isChecked {
                        self.appState.selectedItems.insert(self.path)
                    } else {
                        self.appState.selectedItems.remove(self.path)
                    }
                }
            ))

            .disabled(self.path.path.contains(".Trash"))

            if let appIcon = icon {
                appIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

            }
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center) {
                    Text(path.lastPathComponent)
                        .font(.title3)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(path.lastPathComponent)
                    if isNested(path: path) {
                        InfoButton(text: "Application file is nested within subdirectories. To prevent deleting incorrect folders, Pearcleaner will leave these alone. You may manually delete the remaining folders if required.", color: nil, label: "")
                    }
                }

                Text(path.path)
                    .font(.footnote)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .opacity(0.5)
                    .help(path.path)
            }

            Spacer()

            Text(formatByte(size:size!))



            Button("") {
                NSWorkspace.shared.selectFile(path.path, inFileViewerRootedAtPath: path.deletingLastPathComponent().path)
            }
            .buttonStyle(SimpleButtonStyle(icon: "folder.fill", help: "Show in Finder"))

        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0))
        )
    }
}
