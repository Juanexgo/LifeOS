import Foundation

/// Marker for domain entities. Forces `Identifiable` + `Sendable` so they can
/// cross actor boundaries (UI ↔ persistence ↔ AI) without ceremony.
public protocol DomainEntity: Identifiable, Sendable, Hashable where ID: Sendable & Hashable {}

/// All use-cases follow a single execute-with-input pattern. Keeps feature
/// code uniform and trivially testable.
public protocol UseCase: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable
    func execute(_ input: Input) async throws -> Output
}

/// Special-case: use-cases that take no input.
public protocol ParameterlessUseCase: UseCase where Input == Void {
    func execute() async throws -> Output
}

public extension ParameterlessUseCase {
    func execute(_ input: Void) async throws -> Output { try await execute() }
}
