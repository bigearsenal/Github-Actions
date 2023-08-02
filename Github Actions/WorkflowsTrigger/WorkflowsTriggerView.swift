import SwiftUI

struct WorkflowsTriggerView: View {
    @StateObject private var viewModel: WorkflowTriggerViewModel
    @State private var searchText = ""

    init(
        repositoryOwner: String,
        repositoryName: String,
        personalAccessToken: String
    ) {
        _viewModel = .init(wrappedValue: .init(api: .init(
            repositoryOwner: repositoryOwner,
            repositoryName: repositoryName,
            personalAccessToken: personalAccessToken
        )))
    }

    init(viewModel: WorkflowTriggerViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                if viewModel.isRefreshing {
                    loadingView
                } else {
                    loadedView
                }
            }
        }
        .onAppear {
            viewModel.refresh.send()
        }
        .padding()
        .onChange(of: searchText) { newValue in
            viewModel.filterBranches.send(newValue)
        }
        .alert(item: $viewModel.alertMessage) { alertMessage in
            Alert(title: Text("Error"), message: Text(alertMessage.message), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var loadingView: some View {
        ProgressView("Loading...")
            .progressViewStyle(CircularProgressViewStyle())
    }

    @ViewBuilder
    private var loadedView: some View {
        reloadButton

        selectWorkflowView

        if viewModel.selectedBranch.isEmpty {
            selectBranchView
        } else {
            currentSelectedBranchView
                .padding(.bottom, 20)

            optionsView

            Spacer()

            triggerButton
        }
    }

    @ViewBuilder var reloadButton: some View {
        Button {
            viewModel.refresh.send()
        } label: {
            Text("Reload")
        }
    }

    @ViewBuilder
    private var selectWorkflowView: some View {
        Picker("Select Workflow", selection: $viewModel.selectedWorkflow) {
            Text("No selection")
            ForEach(viewModel.workflows, id: \.self) { workflow in
                Text(workflow.name)
            }
        }
    }

    @ViewBuilder
    private var selectBranchView: some View {
        HStack {
            Text("Select Branch:")
            TextField("Search Branch", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .padding(.horizontal)
        }

        ForEach(viewModel.branches, id: \.self) { branch in
            Button(action: {
                viewModel.selectedBranch = branch
            }) {
                Text(branch)
            }
        }
    }

    @ViewBuilder
    private var currentSelectedBranchView: some View {
        HStack {
            Text("Selected Branch: \(viewModel.selectedBranch)")

            Button {
                viewModel.selectedBranch = ""
            } label: {
                Image(systemName: "x.circle.fill")
            }
        }
    }

    @ViewBuilder
    private var optionsView: some View {
        Text("Options")
    }

    @ViewBuilder
    private var triggerButton: some View {
        Button(action: {
            viewModel.triggerWorkflow.send()
        }) {
            Text("Trigger Workflow")
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
        }
    }
}

struct WorkflowsTriggerView_Previews: PreviewProvider {
    static var previews: some View {
        WorkflowsTriggerView(repositoryOwner: "", repositoryName: "", personalAccessToken: "")
    }
}
