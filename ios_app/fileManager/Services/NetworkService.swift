//
//  NetworkService.swift
//  fileManager
//
//  Network service for API communication
//

import Foundation

class NetworkService {
    static let shared = NetworkService()
    
    private var baseURL: String? {
        didSet {
            if let url = baseURL {
                UserDefaults.standard.set(url, forKey: "backendBaseURL")
            } else {
                UserDefaults.standard.removeObject(forKey: "backendBaseURL")
            }
        }
    }
    
    private var effectiveBaseURL: String {
        // First try saved base URL
        if let savedURL = baseURL ?? UserDefaults.standard.string(forKey: "backendBaseURL") {
            return savedURL
        }
        
        // Try to read from Config.xcconfig file
        if let configPath = Bundle.main.path(forResource: "Config", ofType: "xcconfig"),
           let content = try? String(contentsOfFile: configPath, encoding: .utf8) {
            for line in content.components(separatedBy: .newlines) {
                if line.contains("BACKEND_BASE_URL") && !line.trimmingCharacters(in: .whitespaces).starts(with: "//") {
                    let components = line.components(separatedBy: "=")
                    if components.count > 1 {
                        return components[1].trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        
        // Fallback to default
        return "http://localhost:5000"
    }
    
    func setBaseURL(_ url: String?) {
        self.baseURL = url
    }
    
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
        
        // Load saved URL on init
        if let savedURL = UserDefaults.standard.string(forKey: "backendBaseURL") {
            self.baseURL = savedURL
        }
    }
    
    // MARK: - Server Connection
    
    func testConnection(to url: String) async throws -> Bool {
        guard let testURL = URL(string: "\(url)/") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: testURL)
        request.timeoutInterval = 10
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200 || httpResponse.statusCode == 404 // 404 is OK, means server is responding
        }
        return false
    }
    
    func fetchServerInfo(from url: String) async throws -> ServerInfo {
        guard let infoURL = URL(string: "\(url)/api/info") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: infoURL)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // If endpoint doesn't exist, return default info
        if httpResponse.statusCode == 404 {
            return ServerInfo(name: nil, version: nil, features: nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ServerInfo.self, from: data)
    }
    
    // MARK: - Connection Check
    
    func checkConnection() async throws -> Bool {
        let url = URL(string: "\(effectiveBaseURL)/")!
        let (_, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200
        }
        return false
    }
    
    // MARK: - File Explorer
    
    func fetchFileList(path: String = "") async throws -> FileListResponse {
        var urlString = "\(effectiveBaseURL)/explorer"
        if !path.isEmpty {
            urlString += "/\(path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path)"
        }
        // Add json=true query parameter for JSON response
        urlString += "?json=true"
        
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
        
        // Parse JSON response
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(FileListResponse.self, from: data)
        } catch {
            // Log the actual JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed to decode file list. Response: \(jsonString)")
            }
            print("Decoding error: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
    
    func downloadFile(path: String) async throws -> Data {
        let urlString = "\(effectiveBaseURL)/download/\(path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path)"
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
    
    // MARK: - File Operations
    
    func uploadFile(fileData: Data, fileName: String, targetDirectory: String = "") async throws {
        let urlString = "\(effectiveBaseURL)/upload"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        if !targetDirectory.isEmpty {
            body.append("Content-Disposition: form-data; name=\"directory\"\r\n\r\n".data(using: .utf8)!)
            body.append(targetDirectory.data(using: .utf8)!)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        } else {
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        }
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let _ = errorData["error"] {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    func deleteFile(path: String) async throws {
        let urlString = "\(effectiveBaseURL)/delete"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "filepath=\(path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let _ = errorData["error"] {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    func renameFile(path: String, newName: String) async throws {
        let urlString = "\(effectiveBaseURL)/rename"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let filepathEncoded = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        let newNameEncoded = newName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? newName
        let bodyString = "filepath=\(filepathEncoded)&new_name=\(newNameEncoded)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let _ = errorData["error"] {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    func copyFile(path: String) async throws {
        let urlString = "\(effectiveBaseURL)/copy"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "filepath=\(path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
    }
    
    func cutFile(path: String) async throws {
        let urlString = "\(effectiveBaseURL)/cut"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "filepath=\(path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
    }
    
    func pasteFile(sourcePath: String, targetDirectory: String, operation: String) async throws {
        let urlString = "\(effectiveBaseURL)/paste"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Properly encode form data
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "source_path", value: sourcePath),
            URLQueryItem(name: "target_dir", value: targetDirectory),
            URLQueryItem(name: "operation", value: operation)
        ]
        
        if let bodyString = components.percentEncodedQuery {
            request.httpBody = bodyString.data(using: .utf8)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to decode error message
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw NetworkError.httpError(httpResponse.statusCode, message: errorMessage)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    func moveFile(path: String, targetDirectory: String) async throws {
        let urlString = "\(effectiveBaseURL)/move"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let pathEncoded = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        let targetEncoded = targetDirectory.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? targetDirectory
        let bodyString = "filepath=\(pathEncoded)&target_dir=\(targetEncoded)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let _ = errorData["error"] {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    func createFile(fileName: String, content: String = "", targetDirectory: String = "") async throws {
        let urlString = "\(effectiveBaseURL)/create_file"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let fileNameEncoded = fileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fileName
        let contentEncoded = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? content
        let targetEncoded = targetDirectory.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? targetDirectory
        var bodyString = "filename=\(fileNameEncoded)&content=\(contentEncoded)"
        if !targetDirectory.isEmpty {
            bodyString += "&directory=\(targetEncoded)"
        }
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let _ = errorData["error"] {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    func createFolder(folderName: String, targetDirectory: String = "") async throws {
        let urlString = "\(effectiveBaseURL)/create_folder"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let folderNameEncoded = folderName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? folderName
        let targetEncoded = targetDirectory.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? targetDirectory
        var bodyString = "foldername=\(folderNameEncoded)"
        if !targetDirectory.isEmpty {
            bodyString += "&directory=\(targetEncoded)"
        }
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let _ = errorData["error"] {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Notes
    
    func fetchNotes() async throws -> [Note] {
        let urlString = "\(effectiveBaseURL)/api/notes"
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
        let urlString = "\(effectiveBaseURL)/api/notes/\(id)"
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
        
        let decoder = JSONDecoder()
        do {
            let responseData = try decoder.decode(NoteResponse.self, from: data)
            return responseData.note
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed to decode note. Response: \(jsonString)")
            }
            throw NetworkError.decodingError(error)
        }
    }
    
    func createNote(title: String, content: String) async throws -> Note {
        let urlString = "\(effectiveBaseURL)/api/notes"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = NoteCreateRequest(title: title, content: content)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let _ = errorData["error"] {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        do {
            let responseData = try decoder.decode(NoteResponse.self, from: data)
            return responseData.note
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed to decode created note. Response: \(jsonString)")
            }
            throw NetworkError.decodingError(error)
        }
    }
    
    func updateNote(id: Int, title: String, content: String) async throws -> Note {
        let urlString = "\(effectiveBaseURL)/api/notes/\(id)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = NoteUpdateRequest(title: title, content: content)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let _ = errorData["error"] {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        do {
            let responseData = try decoder.decode(NoteResponse.self, from: data)
            return responseData.note
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed to decode updated note. Response: \(jsonString)")
            }
            throw NetworkError.decodingError(error)
        }
    }
    
    func deleteNote(id: Int) async throws {
        let urlString = "\(effectiveBaseURL)/api/notes/\(id)"
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
    
    func fetchFileInfo(path: String) async throws -> FileInfo {
        let urlString = "\(effectiveBaseURL)/file_info/\(path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw NetworkError.httpError(httpResponse.statusCode, message: errorMessage)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        do {
            let responseData = try decoder.decode(FileInfoResponse.self, from: data)
            return responseData.info
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed to decode FileInfo. Response: \(jsonString)")
            }
            throw NetworkError.decodingError(error)
        }
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, message: String? = nil)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, let message):
            if let message = message {
                return "HTTP error \(code): \(message)"
            }
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

