import Foundation

protocol GithubAPI {
    func getWorkflows() async throws -> [Workflow]
    func getBranches() async throws -> [String]
    func getWorkflowOptions(workflowId: UInt64) async throws -> [WorkflowOption]
    func triggerWorkflow(workflowName: String, selectedBranch: String, workflowInputs: [String: String]) async throws
}

final class GithubAPIImpl: GithubAPI {
    // MARK: - Properties

    private let repositoryOwner: String
    private let repositoryName: String
    private let personalAccessToken: String

    // MARK: - Initializer

    init(repositoryOwner: String, repositoryName: String, personalAccessToken: String) {
        self.repositoryOwner = repositoryOwner
        self.repositoryName = repositoryName
        self.personalAccessToken = personalAccessToken
    }

    // MARK: - Methods

    func getWorkflows() async throws -> [Workflow] {
        let baseURL = "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/actions/workflows"

        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.addValue("token \(personalAccessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(WorkflowList.self, from: data).workflows
    }

    func getBranches() async throws -> [String] {
        let baseURL = "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/branches"

        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.addValue("token \(personalAccessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.shared.data(for: request)
        let branchesResponse = try JSONDecoder().decode([Branch].self, from: data)

        return branchesResponse.map(\.name)
    }

    func getWorkflowOptions(workflowId: UInt64) async throws -> [WorkflowOption] {
        let baseURL =
            "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/actions/workflows/\(workflowId)/config"

        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.addValue("token \(personalAccessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.shared.data(for: request)
        let configResponse = try JSONDecoder().decode(ConfigResponse.self, from: data)

        return configResponse.getWorkflowOptions()
    }

    func triggerWorkflow(workflowName: String, selectedBranch: String, workflowInputs: [String: String]) async throws {
        let baseURL =
            "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/actions/workflows/\(workflowName)/dispatches"

        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("token \(personalAccessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["ref": selectedBranch, "inputs": workflowInputs] as [String : Any]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200 ..< 300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Failed to trigger workflow.", code: -1, userInfo: nil)
        }
    }
}
