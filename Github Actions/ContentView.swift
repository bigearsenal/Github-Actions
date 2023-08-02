import SwiftUI

struct ContentView: View {
    var body: some View {
        WorkflowsTriggerView(
            repositoryOwner: "p2p-org",
            repositoryName: "p2p-wallet-ios",
            personalAccessToken: "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"
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
