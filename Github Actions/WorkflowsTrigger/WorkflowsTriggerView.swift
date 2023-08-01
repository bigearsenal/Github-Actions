import SwiftUI

struct WorkflowsTriggerView: View {
    @StateObject private var viewModel = WorkflowTriggerViewModel(
        api: GithubAPIImpl(
            repositoryOwner: "p2p-org",
            repositoryName: "p2p-wallet-ios",
            personalAccessToken: "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"
        )
    )
    @State private var searchText = ""

    var filteredBranches: [String] {
        viewModel.branches.filter { branch in
            searchText.isEmpty ? true : branch.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack {
            if viewModel.isRefreshing {
                loadingView
            } else {
                loadedView
            }
        }
        .onAppear {
            viewModel.refresh()
        }
        .refreshable {
            viewModel.refresh()
        }
        .padding()
        .onChange(of: searchText) { newValue in
            viewModel.filterBranches(with: newValue)
        }
        .alert(item: $viewModel.alertMessage) { alertMessage in
            Alert(title: Text("Error"), message: Text(alertMessage.message), dismissButton: .default(Text("OK")))
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        ProgressView("Loading...")
            .progressViewStyle(CircularProgressViewStyle())
    }

    @ViewBuilder
    private var loadedView: some View {
        Picker("Select Workflow", selection: $viewModel.selectedWorkflow) {
            Text("No selection")
            ForEach(viewModel.workflows, id: \.self) { workflow in
                Text(workflow.name)
            }
        }

        HStack {
            Text("Select Branch:")
            TextField("Search Branch", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
        }

        List {
            ForEach(filteredBranches, id: \.self) { branch in
                Button(action: {
                    viewModel.selectedBranch = branch
                }) {
                    Text(branch)
                }
            }
        }
        .listStyle(.plain)

        //                if let options = viewModel.selectedWorkflow?.options {
        //                    ForEach(options, id: \.name) { option in
        //                        if option.type == .boolean {
        //                            Toggle(option.name, isOn: $viewModel.booleanOptions[option.name, default: false])
        //                        } else if option.type == .string {
        //                            TextField(option.name, text: $viewModel.stringOptions[option.name, default: ""])
        //                                .textFieldStyle(RoundedBorderTextFieldStyle())
        //                                .padding()
        //                        }
        //                    }
        //                }
        //
        //                Button(action: {
        //                    viewModel.triggerGitHubWorkflow()
        //                }) {
        //                    Text("Trigger Workflow")
        //                        .padding()
        //                        .foregroundColor(.white)
        //                        .background(Color.blue)
        //                        .cornerRadius(8)
        //                }

        Spacer()
    }
}

struct WorkflowsTriggerView_Previews: PreviewProvider {
    static var previews: some View {
        WorkflowsTriggerView()
    }
}
