//
//  NetworkService.swift
//  fileManager
//
//  Network service for API communication
//

import Foundation

class NetworkService {
    static let shared = NetworkService()
    
    private var baseURL: String {
        // Try to read from Config.xcconfig file
        if let configPath = Bundle.main.path(forResource: "Config", ofType: "xcconfig"),
           let content = try? String(contentsOfFile: configPath) {
            for line in content.components(separatedBy: .newlines) {
                if line.contains("BACKEND_BASE_URL") && !line.trimmingCharacters(in: .whitespaces).starts(with: "//") {
                    let components = line.components(separatedBy: "=")
                    if components.count > 1 {
                        return components[1].trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        
        // Fallback to default or read from UserDefaults
        return UserDefaults.standard.string(forKey: "backendBaseURL") ?? "http://localhost:5000"
    }
    
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Connection Check
    
    func checkConnection() async throws -> Bool {
        let url = URL(string: "\(baseURL)/")!
        let (_, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200
        }
        return false
    }
    
    // MARK: - File Explorer
    
    func fetchFileList(path: String = "") async throws -> FileListResponse {
        var urlString = "\(baseURL)/explorer"
        if !path.isEmpty {
            urlString += "/\(path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path)"
        }
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        // Parse HTML response to extract file list
        // For now, we'll need to parse the HTML or use a JSON endpoint if available
        // This is a simplified version - you may need to adjust based on your backend
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(FileListResponse.self, from: data)
        } catch {
            // If JSON parsing fails, try HTML parsing
            throw NetworkError.decodingError(error)
        }
    }
    
    func downloadFile(path: String) async throws -> Data {
        let urlString = "\(baseURL)/download/\(path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return data
    }
    
    // MARK: - Notes
    
    func fetchNotes() async throws -> [Note] {
        let urlString = "\(baseURL)/api/notes"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode(NoteListResponse.self, from: data)
        return responseData.notes
    }
    
    func fetchNote(id: Int) async throws -> Note {
        let urlString = "\(baseURL)/api/notes/\(id)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode(NoteResponse.self, from: data)
        return responseData.note
    }
    
    func createNote(title: String, content: String) async throws -> Note {
        let urlString = "\(baseURL)/api/notes"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = NoteCreateRequest(title: title, content: content)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode(NoteResponse.self, from: data)
        return responseData.note
    }
    
    func updateNote(id: Int, title: String, content: String) async throws -> Note {
        let urlString = "\(baseURL)/api/notes/\(id)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = NoteUpdateRequest(title: title, content: content)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode(NoteResponse.self, from: data)
        return responseData.note
    }
    
    func deleteNote(id: Int) async throws {
        let urlString = "\(baseURL)/api/notes/\(id)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw NetworkError.invalidResponse
        }
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

