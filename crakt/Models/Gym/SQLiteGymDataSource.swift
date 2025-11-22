//
//  SQLiteGymDataSource.swift
//  crakt
//
//  SQLite implementation of GymDataSource
//

import Foundation
import SQLite3
import CoreLocation

actor SQLiteGymDataSource: GymDataSource {
    static let shared = SQLiteGymDataSource()
    
    private var db: OpaquePointer?
    private let dbPath: String
    private let dateFormatter: ISO8601DateFormatter
    
    // MARK: - Initialization
    
    private init() {
        self.dateFormatter = ISO8601DateFormatter()
        
        // Get path to database in documents directory
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let dbURL = documentsPath.appendingPathComponent("gyms.sqlite")
        self.dbPath = dbURL.path
        
        // Copy database from bundle if needed
        Task {
            do {
                try await initializeDatabase()
            } catch {
                print("Failed to initialize gym database: \(error)")
            }
        }
    }
    
    private func initializeDatabase() async throws {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let dbURL = documentsPath.appendingPathComponent("gyms.sqlite")
        
        // Check if database exists in documents
        if !FileManager.default.fileExists(atPath: dbURL.path) {
            // Copy from bundle
            guard let bundleDB = Bundle.main.url(forResource: "gyms", withExtension: "sqlite") else {
                throw GymDataSourceError.databaseNotFound
            }
            
            do {
                try FileManager.default.copyItem(at: bundleDB, to: dbURL)
                print("✅ Copied gym database to documents directory")
            } catch {
                throw GymDataSourceError.databaseInitializationFailed(error)
            }
        }
        
        // Open database and create indexes
        try await openDatabase()
        try await createIndexes()
    }
    
    private func openDatabase() async throws {
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw GymDataSourceError.queryFailed(NSError(
                domain: "SQLite",
                code: Int(sqlite3_errcode(db)),
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            ))
        }
    }
    
    private func createIndexes() async throws {
        let indexes = [
            "CREATE INDEX IF NOT EXISTS idx_gym_name ON gyms(name COLLATE NOCASE)",
            "CREATE INDEX IF NOT EXISTS idx_gym_city ON gyms(city COLLATE NOCASE)",
            "CREATE INDEX IF NOT EXISTS idx_gym_state ON gyms(state COLLATE NOCASE)",
            "CREATE INDEX IF NOT EXISTS idx_gym_location ON gyms(latitude, longitude)"
        ]
        
        for indexSQL in indexes {
            var statement: OpaquePointer?
            defer { sqlite3_finalize(statement) }
            
            guard sqlite3_prepare_v2(db, indexSQL, -1, &statement, nil) == SQLITE_OK,
                  sqlite3_step(statement) == SQLITE_DONE else {
                continue // Indexes might already exist
            }
        }
        
        print("✅ Created gym database indexes")
    }
    
    // MARK: - GymDataSource Protocol
    
    func fetchAllGyms() async throws -> [Gym] {
        let sql = """
            SELECT id, name, houseNumber, street, city, state, postcode, country,
                   phone, website, hours, latitude, longitude, source, createdAt, updatedAt
            FROM gyms
            ORDER BY name COLLATE NOCASE
        """
        
        return try await executeQuery(sql, parameters: [])
    }
    
    func searchGyms(
        query: String,
        location: CLLocation?,
        limit: Int
    ) async throws -> [Gym] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If query is empty, return nearby gyms if location available
        if trimmed.isEmpty {
            if let location = location {
                return try await fetchNearbyGyms(location: location, radius: 50000, limit: limit)
            } else {
                return try await fetchAllGyms()
            }
        }
        
        // SQL with relevance-based ordering
        let sql = """
            SELECT id, name, houseNumber, street, city, state, postcode, country,
                   phone, website, hours, latitude, longitude, source, createdAt, updatedAt
            FROM gyms
            WHERE name LIKE ? COLLATE NOCASE
               OR city LIKE ? COLLATE NOCASE
               OR state LIKE ? COLLATE NOCASE
            ORDER BY
                CASE
                    WHEN name LIKE ? COLLATE NOCASE THEN 1
                    WHEN name LIKE ? COLLATE NOCASE THEN 2
                    WHEN city LIKE ? COLLATE NOCASE THEN 3
                    WHEN state LIKE ? COLLATE NOCASE THEN 4
                    ELSE 5
                END,
                name COLLATE NOCASE
            LIMIT ?
        """
        
        let pattern = "%\(trimmed)%"
        let exactPattern = "\(trimmed)%"
        
        let gyms = try await executeQuery(sql, parameters: [
            pattern,          // name LIKE
            pattern,          // city LIKE
            pattern,          // state LIKE
            exactPattern,     // name starts with (priority 1)
            pattern,          // name contains (priority 2)
            exactPattern,     // city starts with (priority 3)
            exactPattern,     // state starts with (priority 4)
            limit
        ])
        
        // Sort by distance if location is available
        if let location = location {
            return gyms.sorted { gym1, gym2 in
                gym1.distance(from: location) < gym2.distance(from: location)
            }
        }
        
        return gyms
    }
    
    func fetchNearbyGyms(
        location: CLLocation,
        radius: Double,
        limit: Int
    ) async throws -> [Gym] {
        // Fetch all gyms (could optimize with bounding box query)
        let allGyms = try await fetchAllGyms()
        
        // Filter by distance and sort
        let nearbyGyms = allGyms
            .filter { gym in
                gym.distance(from: location) <= radius
            }
            .sorted { gym1, gym2 in
                gym1.distance(from: location) < gym2.distance(from: location)
            }
            .prefix(limit)
        
        return Array(nearbyGyms)
    }
    
    func fetchGym(id: Int) async throws -> Gym? {
        let sql = """
            SELECT id, name, houseNumber, street, city, state, postcode, country,
                   phone, website, hours, latitude, longitude, source, createdAt, updatedAt
            FROM gyms
            WHERE id = ?
            LIMIT 1
        """
        
        let gyms = try await executeQuery(sql, parameters: [id])
        return gyms.first
    }
    
    func addCustomGym(_ details: NewGymDetails) async throws -> Gym {
        let sql = """
            INSERT INTO gyms
                (name, houseNumber, street, city, state, postcode, country,
                 phone, website, hours, latitude, longitude, source, createdAt, updatedAt)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        guard let db = db else {
            throw GymDataSourceError.insertionFailed("Database not initialized")
        }
        
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw GymDataSourceError.insertionFailed(errorMessage)
        }
        
        let now = dateFormatter.string(from: Date())
        
        let params: [Any?] = [
            details.name,
            details.houseNumber,
            details.street,
            details.city,
            details.state,
            details.postcode,
            details.country,
            details.phone,
            details.website,
            details.hours,
            details.latitude,
            details.longitude,
            "USER_ADDED",
            now,
            now
        ]
        
        for (index, value) in params.enumerated() {
            let idx = Int32(index + 1)
            if let string = value as? String {
                sqlite3_bind_text(statement, idx, (string as NSString).utf8String, -1, nil)
            } else if let doubleValue = value as? Double {
                sqlite3_bind_double(statement, idx, doubleValue)
            } else if let intValue = value as? Int {
                sqlite3_bind_int64(statement, idx, Int64(intValue))
            } else if value == nil {
                sqlite3_bind_null(statement, idx)
            }
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw GymDataSourceError.insertionFailed(errorMessage)
        }
        
        let insertedID = Int(sqlite3_last_insert_rowid(db))
        if let gym = try await fetchGym(id: insertedID) {
            return gym
        }
        
        // Fallback to constructing from details if fetch fails
        let address = Gym.Address(
            houseNumber: details.houseNumber,
            street: details.street,
            city: details.city,
            state: details.state,
            postcode: details.postcode,
            country: details.country
        )
        
        return Gym(
            id: insertedID,
            name: details.name,
            address: address,
            phone: details.phone,
            website: details.website,
            hours: details.hours,
            coordinate: CLLocationCoordinate2D(latitude: details.latitude, longitude: details.longitude),
            source: "USER_ADDED",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Private Helpers
    
    private func executeQuery(_ sql: String, parameters: [Any]) async throws -> [Gym] {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw GymDataSourceError.queryFailed(NSError(
                domain: "SQLite",
                code: Int(sqlite3_errcode(db)),
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            ))
        }
        
        // Bind parameters
        for (index, parameter) in parameters.enumerated() {
            let bindIndex = Int32(index + 1)
            
            switch parameter {
            case let value as String:
                sqlite3_bind_text(statement, bindIndex, (value as NSString).utf8String, -1, nil)
            case let value as Int:
                sqlite3_bind_int64(statement, bindIndex, Int64(value))
            case let value as Double:
                sqlite3_bind_double(statement, bindIndex, value)
            default:
                sqlite3_bind_null(statement, bindIndex)
            }
        }
        
        // Execute and collect results
        var gyms: [Gym] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let gym = parseGym(from: statement) {
                gyms.append(gym)
            }
        }
        
        return gyms
    }
    
    private func parseGym(from statement: OpaquePointer?) -> Gym? {
        guard let statement = statement else { return nil }
        
        let id = Int(sqlite3_column_int64(statement, 0))
        
        guard let namePtr = sqlite3_column_text(statement, 1) else { return nil }
        let name = String(cString: namePtr)
        
        let houseNumber = columnString(statement, 2)
        let street = columnString(statement, 3)
        let city = columnString(statement, 4)
        let state = columnString(statement, 5)
        let postcode = columnString(statement, 6)
        let country = columnString(statement, 7) ?? "US"
        let phone = columnString(statement, 8)
        let website = columnString(statement, 9)
        let hours = columnString(statement, 10)
        
        let latitude = sqlite3_column_double(statement, 11)
        let longitude = sqlite3_column_double(statement, 12)
        
        let source = columnString(statement, 13) ?? "OSM_OVERPASS"
        let createdAt = columnDate(statement, 14) ?? Date()
        let updatedAt = columnDate(statement, 15) ?? Date()
        
        let address = Gym.Address(
            houseNumber: houseNumber,
            street: street,
            city: city,
            state: state,
            postcode: postcode,
            country: country
        )
        
        return Gym(
            id: id,
            name: name,
            address: address,
            phone: phone,
            website: website,
            hours: hours,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    private func columnString(_ statement: OpaquePointer?, _ index: Int32) -> String? {
        guard let textPtr = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: textPtr)
    }
    
    private func columnDate(_ statement: OpaquePointer?, _ index: Int32) -> Date? {
        guard let textPtr = sqlite3_column_text(statement, index) else { return nil }
        let dateString = String(cString: textPtr)
        return dateFormatter.date(from: dateString)
    }
    
    deinit {
        sqlite3_close(db)
    }
}
