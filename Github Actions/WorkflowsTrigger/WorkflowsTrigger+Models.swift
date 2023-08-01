import Foundation

struct WorkflowList: Codable {
    let workflows: [Workflow]
}

struct Workflow: Codable, Hashable {
    let id: UInt64
    let name: String
}

struct WorkflowOption: Codable, Hashable {
    enum OptionType: String, Codable {
        case string
        case boolean
    }

    let name: String
    let type: OptionType
}

struct Branch: Codable {
    let name: String
}

struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct ConfigResponse: Codable {
    let config: WorkflowConfig

    func getWorkflowOptions() -> [WorkflowOption] {
        let envKeys = config.jobs.reduce(into: Set<String>()) { set, job in
            job.steps.forEach { step in
                if let env = step.env {
                    env.forEach { key, _ in
                        set.insert(key)
                    }
                }
            }
        }

        var options: [WorkflowOption] = []
        envKeys.forEach { key in
            if key.hasPrefix("INPUT_") {
                options.append(WorkflowOption(name: key, type: .string))
            } else {
                options.append(WorkflowOption(name: key, type: .boolean))
            }
        }
        return options
    }
}

struct WorkflowConfig: Codable {
    let jobs: [Job]
}

struct Job: Codable {
    let steps: [Step]
}

struct Step: Codable {
    let env: [String: String]?
}
