import Foundation

// MARK: - API Result

/// Result wrapper for API calls
/// Provides type-safe error handling
public enum ApiResult<T> {
    /// Success result with data
    case success(T)

    /// Error result with VpnAPIError
    case failure(VpnAPIError)

    /// Check if result is successful
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    /// Check if result is failure
    public var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }

    /// Get data or nil
    public func get() -> T? {
        switch self {
        case .success(let data):
            return data
        case .failure:
            return nil
        }
    }

    /// Get data or default value
    public func getOrDefault(_ defaultValue: T) -> T {
        switch self {
        case .success(let data):
            return data
        case .failure:
            return defaultValue
        }
    }

    /// Get error or nil
    public func error() -> VpnAPIError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }

    /// Map success value to another type
    public func map<U>(_ transform: (T) -> U) -> ApiResult<U> {
        switch self {
        case .success(let data):
            return .success(transform(data))
        case .failure(let error):
            return .failure(error)
        }
    }

    /// FlatMap for chaining API calls
    public func flatMap<U>(_ transform: (T) -> ApiResult<U>) -> ApiResult<U> {
        switch self {
        case .success(let data):
            return transform(data)
        case .failure(let error):
            return .failure(error)
        }
    }
}
