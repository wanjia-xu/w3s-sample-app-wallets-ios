// Copyright (c) 2023, Circle Technologies, LLC. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI
import CircleProgrammableWalletSDK

struct ContentView: View {

    let adapter = WalletSdkAdapter()

    @State var appId = "your-app-id" // put your App ID here
    @State var endPoint = EndPoint.production

    @State var userToken = ""
    @State var secretKey = ""
    @State var challengeId = ""

    @State var showToast = false
    @State var toastMessage: String?
    @State var toastConfig: Toast.Config = .init()

    var body: some View {
        VStack {
            List {
                titleText
                sectionEndPoint
                sectionInputField("App ID", binding: $appId)
                sectionInputField("User Token", binding: $userToken)
                sectionInputField("Secret Key", binding: $secretKey)
                sectionInputField("Challenge ID", binding: $challengeId)
                sectionExecuteButton

                Spacer()
//                TestButtons
            }
//            versionText
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            self.adapter.initSDK(endPoint: endPoint.urlString, appId: appId)

            if let storedAppId = self.adapter.storedAppId, !storedAppId.isEmpty {
                self.appId = storedAppId
            }
        }
        .onChange(of: endPoint) { newValue in
            self.adapter.updateEndPoint(newValue.urlString, appId: appId)
            self.showToast(.general, message: "End Point: \(newValue.urlString)")
        }
        .onChange(of: appId) { newValue in
            self.adapter.updateEndPoint(endPoint.urlString, appId: newValue)
            self.adapter.storedAppId = newValue
        }
        .toast(message: toastMessage ?? "",
               isShowing: $showToast,
               config: toastConfig)
    }

    var titleText: some View {
        Text("Programmable Wallet SDK\nSample App").font(.title2)
    }

    var versionText: some View {
        Text("v\(Utility.appVersion() ?? "")").font(.footnote)
    }

    var sectionEndPoint: some View {
        Section {
            Text(endPoint.urlString)
        } header: {
            Text("End Point :")
        }
    }

    func sectionInputField(_ title: String, binding: Binding<String>) -> Section<Text, some View, EmptyView> {
        Section {
            TextField(title, text: binding)
                .textFieldStyle(.roundedBorder)
        } header: {
            Text(title + " :")
        }
    }

    var sectionExecuteButton: some View {
        Button {
            guard !userToken.isEmpty else { showToast(.general, message: "User Token is Empty"); return }
            guard !secretKey.isEmpty else { showToast(.general, message: "Secret Key is Empty"); return }
            guard !challengeId.isEmpty else { showToast(.general, message: "Challenge ID is Empty"); return }
            executeChallenge(userToken: userToken, secretKey: secretKey, challengeId: challengeId)

        } label: {
            Text("Execute")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .listRowSeparator(.hidden)
    }
}

extension ContentView {

    enum ToastType {
        case general
        case success
        case failure
    }

    func showToast(_ type: ToastType, message: String) {
        toastMessage = message
        showToast = true

        switch type {
        case .general:
            toastConfig = Toast.Config()
        case .success:
            toastConfig = Toast.Config(backgroundColor: .green, duration: 2.0)
        case .failure:
            toastConfig = Toast.Config(backgroundColor: .pink, duration: 10.0)
        }
    }

    func executeChallenge(userToken: String, secretKey: String, challengeId: String) {
        WalletSdk.shared.execute(userToken: userToken,
                                 secretKey: secretKey,
                                 challengeIds: [challengeId]) { response in
            switch response.result {
            case .success(let result):
                let challengeStatus = result.status.rawValue
                let challeangeType = result.resultType.rawValue
                showToast(.success, message: "\(challeangeType) - \(challengeStatus)")

            case .failure(let error):
                showToast(.failure, message: "Error: " + error.errorString)
                errorHandler(apiError: error, onErrorController: response.onErrorController)
            }
        }
    }

    func errorHandler(apiError: ApiError, onErrorController: UINavigationController?) {
        switch apiError.errorCode {
        case .userHasSetPin:
            onErrorController?.dismiss(animated: true)
        default:
            break
        }
    }

    var TestButtons: some View {
        Section {
            Button("New PIN", action: newPIN)
            Button("Change PIN", action: changePIN)
            Button("Restore PIN", action: restorePIN)
            Button("Enter PIN", action: enterPIN)

        } header: {
            Text("UI Customization Entry")
                .font(.title3)
                .fontWeight(.semibold)
        }
    }

    func newPIN() {
        WalletSdk.shared.execute(userToken: "", secretKey: "", challengeIds: ["ui_new_pin"])
    }

    func enterPIN() {
        WalletSdk.shared.execute(userToken: "", secretKey: "", challengeIds: ["ui_enter_pin"])
    }

    func changePIN() {
        WalletSdk.shared.execute(userToken: "", secretKey: "", challengeIds: ["ui_change_pin"])
    }

    func restorePIN() {
        WalletSdk.shared.execute(userToken: "", secretKey: "", challengeIds: ["ui_restore_pin"])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
