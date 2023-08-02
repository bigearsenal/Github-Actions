import Foundation

final class GithubAPI {
    // MARK: - Properties

    private let repositoryOwner: String
    private let repositoryName: String
    private let personalAccessToken: String
    private let urlSession: URLSessionProtocol

    // MARK: - Initializer

    init(
        repositoryOwner: String,
        repositoryName: String,
        personalAccessToken: String,
        urlSession: URLSessionProtocol = URLSession.shared
    ) {
        self.repositoryOwner = repositoryOwner
        self.repositoryName = repositoryName
        self.personalAccessToken = personalAccessToken
        self.urlSession = urlSession
    }

    // MARK: - Public Methods

    // Get workflows for the repository
    func getWorkflows() async throws -> [Workflow] {
        let baseURL = "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/actions/workflows"
        let request = try createURLRequest(baseURL: baseURL)
        let (data, _) = try await fetchData(with: request, using: urlSession)
        return try JSONDecoder().decode(WorkflowList.self, from: data).workflows
    }

    // Get branches for the repository
    func getBranches(page: Int = 1, perPage: Int = 100) async throws -> [String] {
        let baseURL =
            "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/branches?page=\(page)&per_page=\(perPage)"
        let request = try createURLRequest(baseURL: baseURL)
        let (data, _) = try await fetchData(with: request, using: urlSession)
        let branchesResponse = try JSONDecoder().decode([Branch].self, from: data)
        return branchesResponse.map(\.name)
    }

    // Get workflow options for a specific workflow by its ID
    func getWorkflowOptions(workflowId: UInt64) async throws -> [WorkflowOption] {
        let baseURL =
            "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/actions/workflows/\(workflowId)/config"
        let request = try createURLRequest(baseURL: baseURL)
        let (data, _) = try await fetchData(with: request, using: urlSession)
        let configResponse = try JSONDecoder().decode(ConfigResponse.self, from: data)
        return configResponse.getWorkflowOptions()
    }

    // Trigger a workflow with selected branch and workflow inputs
    func triggerWorkflow(
        workflowName: String,
        selectedBranch: String,
        workflowInputs: [String: String]
    ) async throws {
        let baseURL =
            "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/actions/workflows/\(workflowName)/dispatches"
        let request = try createURLRequest(
            baseURL: baseURL,
            method: "POST",
            body: ["ref": selectedBranch, "inputs": workflowInputs]
        )
        let (_, response) = try await fetchData(with: request, using: urlSession)
        guard let httpResponse = response as? HTTPURLResponse, (200 ..< 300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Failed to trigger workflow.", code: -1, userInfo: nil)
        }
    }

    // MARK: - Private Methods

    // Create a URLRequest with necessary headers and body
    private func createURLRequest(
        baseURL: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if !personalAccessToken.isEmpty {
            request.addValue("token \(personalAccessToken)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return request
    }

    // Fetch data using URLSessionProtocol
    private func fetchData(
        with request: URLRequest,
        using session: URLSessionProtocol
    ) async throws -> (Data, URLResponse) {
        let (data, response) = try await session.data(for: request)
        print(NSString(string: .init(data: data, encoding: .utf8)!))
        return (data, response)
    }
}
