import Combine
import Foundation

@MainActor
class WorkflowTriggerViewModel: ObservableObject {
    // MARK: - Dependencies

    private let api: GithubAPI

    // MARK: - Input

    @Published var selectedWorkflow: Workflow = .init(id: 0, name: "")
    @Published var selectedBranch: String = ""
    @Published var alertMessage: AlertMessage?

    // MARK: - Output

    @Published private(set) var isRefreshing = false
    @Published private(set) var isFetchingWorkflowOptions = false
    @Published private(set) var isTriggeringWorkflow = false

    @Published private(set) var workflows: [Workflow] = []
    @Published private(set) var branches: [String] = []

    @Published private(set) var booleanOptions: [String: Bool] = [:]
    @Published var stringOptions: [String: String] = [:]

    // MARK: - Actions

    let refresh = PassthroughSubject<Void, Never>()

    // MARK: - Properties

    private var originalBranches: [String] = []
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Initializer

    init(api: GithubAPI) {
        self.api = api
        bindActions()
    }

    // MARK: - Binding

    private func bindActions() {
        refresh
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?._refresh()
            }
            .store(in: &subscriptions)
    }

    // MARK: - Methods

    private func _refresh() {
        isRefreshing = true
        booleanOptions = [:]
        stringOptions = [:]

        Task {
            defer { isRefreshing = false }

            do {
                let _ = try await(
                    fetchWorkflows(),
                    fetchBranches()
                )
            } catch {
                alertMessage = .init(message: "Something went wrong")
            }
        }
    }

    func filterBranches(with searchText: String) {
        if searchText.isEmpty {
            branches = originalBranches
        } else {
            branches = originalBranches.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    func fetchWorkflowOptions() {
        isFetchingWorkflowOptions = true
        Task {
            do {
                defer { isFetchingWorkflowOptions = false }
                let options = try await api.getWorkflowOptions(workflowId: selectedWorkflow.id)

                booleanOptions = [:]
                stringOptions = [:]
                options.forEach { option in
                    if option.type == .boolean {
                        booleanOptions[option.name] = false
                    } else if option.type == .string {
                        stringOptions[option.name] = ""
                    }
                }
            } catch {
                alertMessage = AlertMessage(message: "Error fetching workflow options: \(error)")
            }
        }
    }

    func triggerGitHubWorkflow() {
        isTriggeringWorkflow = true
        Task {
            defer { isTriggeringWorkflow = false }

            do {
                let workflowInputs = getWorkflowInputs()
                try await api.triggerWorkflow(
                    workflowName: selectedWorkflow.name,
                    selectedBranch: selectedBranch,
                    workflowInputs: workflowInputs
                )
                print("Workflow '\(selectedWorkflow.name)' triggered successfully!")
                // Show a success message to the user if needed
            } catch {
                print(error)
                alertMessage = AlertMessage(message: "Error triggering workflow: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func fetchWorkflows() async throws {
        workflows = try await api.getWorkflows()
    }

    private func fetchBranches(page: Int = 1, combinedResult: [String] = []) async throws {
        let perPage = 100
        let result = try await api.getBranches(page: page)
        let combinedResult = combinedResult + result
        if result.count < perPage {
            branches = combinedResult
            originalBranches = combinedResult
            return
        } else {
            try await fetchBranches(page: page + 1, combinedResult: combinedResult)
            return
        }
    }

    private func getWorkflowInputs() -> [String: String] {
        var workflowInputs: [String: String] = [:]

        for (key, value) in booleanOptions {
            workflowInputs[key] = value ? "true" : "false"
        }

        for (key, value) in stringOptions {
            workflowInputs[key] = value
        }

        return workflowInputs
    }
}
