import Foundation

final class GithubAPI {
    private let repositoryOwner: String
    private let repositoryName: String
    private let personalAccessToken: String
    private let urlSession: URLSessionProtocol

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

    func getWorkflows() async throws -> [Workflow] {
        let baseURL = "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/actions/workflows"
        let request = try createURLRequest(baseURL: baseURL)
        let (data, _) = try await fetchData(with: request, using: urlSession)
        return try JSONDecoder().decode(WorkflowList.self, from: data).workflows
    }

    func getBranches() async throws -> [String] {
        let baseURL = "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/branches"
        let request = try createURLRequest(baseURL: baseURL)
        let (data, _) = try await fetchData(with: request, using: urlSession)
        let branchesResponse = try JSONDecoder().decode([Branch].self, from: data)
        return branchesResponse.map(\.name)
    }

    func getWorkflowOptions(workflowId: UInt64) async throws -> [WorkflowOption] {
        let baseURL =
            "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/actions/workflows/\(workflowId)/config"
        let request = try createURLRequest(baseURL: baseURL)
        let (data, _) = try await fetchData(with: request, using: urlSession)
        let configResponse = try JSONDecoder().decode(ConfigResponse.self, from: data)
        return configResponse.getWorkflowOptions()
    }

    func triggerWorkflow(workflowName: String, selectedBranch: String, workflowInputs: [String: String]) async throws {
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

    private func createURLRequest(baseURL: String, method: String = "GET",
                                  body: [String: Any]? = nil) throws -> URLRequest
    {
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("token \(personalAccessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return request
    }

    private func fetchData(with request: URLRequest,
                           using session: URLSessionProtocol) async throws -> (Data, URLResponse)
    {
        let (data, response) = try await session.data(for: request)
        return (data, response)
    }
}
