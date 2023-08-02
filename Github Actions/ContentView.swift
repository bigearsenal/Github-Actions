import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            WorkflowsTriggerView(
                repositoryOwner: "p2p-org",
                repositoryName: "p2p-wallet-ios",
                personalAccessToken: ""
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("p2p-org/p2p-wallet-ios")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
