import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    private let dbName = Configuration.Database.sqliteDBName
    private let currentVersion = 1
    
    private init() {
        setupDatabase()
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func setupDatabase() {
        let dbPath = getDocumentsDirectory().appendingPathComponent(dbName).path
        
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            createTablesAndMigrate()
        } else {
            print("Unable to open database")
        }
    }
    
    private func createTablesAndMigrate() {
        let currentVersion = getDatabaseVersion()
        
        if currentVersion < self.currentVersion {
            // Run migrations from current version to target version
            runMigrations(from: currentVersion, to: self.currentVersion)
            setDatabaseVersion(self.currentVersion)
        }
    }
    
    private func getDatabaseVersion() -> Int {
        let sql = "PRAGMA user_version"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let version = Int(sqlite3_column_int(statement, 0))
                sqlite3_finalize(statement)
                return version
            }
        }
        sqlite3_finalize(statement)
        return 0
    }
    
    private func setDatabaseVersion(_ version: Int) {
        let sql = "PRAGMA user_version = \(version)"
        sqlite3_exec(db, sql, nil, nil, nil)
    }
    
    private func runMigrations(from oldVersion: Int, to newVersion: Int) {
        for version in (oldVersion + 1)...newVersion {
            switch version {
            case 1:
                migrationV1_CreateInitialTables()
            default:
                print("Unknown migration version: \(version)")
            }
        }
    }
    
    private func migrationV1_CreateInitialTables() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS usage_stats (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                app_launches INTEGER DEFAULT 0,
                habits_created INTEGER DEFAULT 0,
                habits_formed INTEGER DEFAULT 0,
                last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
                last_review_request DATETIME DEFAULT NULL,
                habits_formed_at_last_review INTEGER DEFAULT 0
            );
            
            INSERT OR IGNORE INTO usage_stats (id, app_launches, habits_created, habits_formed)
            VALUES (1, 0, 0, 0);
        """
        
        if sqlite3_exec(db, createTableSQL, nil, nil, nil) != SQLITE_OK {
            print("Error in migration V1: Creating initial tables")
        }
    }
    
    // MARK: - Database Access Methods
    
    func execute(_ sql: String, completion: ((Bool) -> Void)? = nil) {
        let result = sqlite3_exec(db, sql, nil, nil, nil)
        completion?(result == SQLITE_OK)
    }
    
    func prepare(_ sql: String) -> OpaquePointer? {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            return statement
        }
        return nil
    }
    
    func step(_ statement: OpaquePointer?) -> Int32 {
        return sqlite3_step(statement)
    }
    
    func finalize(_ statement: OpaquePointer?) {
        sqlite3_finalize(statement)
    }
    
    func columnInt(_ statement: OpaquePointer?, _ column: Int32) -> Int {
        return Int(sqlite3_column_int(statement, column))
    }
    
    func columnText(_ statement: OpaquePointer?, _ column: Int32) -> String? {
        if let cString = sqlite3_column_text(statement, column) {
            return String(cString: cString)
        }
        return nil
    }
    
    // MARK: - Usage Statistics Methods
    
    func incrementAppLaunches() {
        let updateSQL = """
            UPDATE usage_stats 
            SET app_launches = app_launches + 1, 
                last_updated = CURRENT_TIMESTAMP 
            WHERE id = 1
        """
        
        execute(updateSQL) { success in
            if !success {
                print("Error updating app launches")
            }
        }
    }
    
    func incrementHabitsCreated() {
        let updateSQL = """
            UPDATE usage_stats 
            SET habits_created = habits_created + 1, 
                last_updated = CURRENT_TIMESTAMP 
            WHERE id = 1
        """
        
        execute(updateSQL) { success in
            if !success {
                print("Error updating habits created")
            }
        }
    }
    
    func incrementHabitsFormed(count: Int = 1) {
        let updateSQL = """
            UPDATE usage_stats 
            SET habits_formed = habits_formed + \(count), 
                last_updated = CURRENT_TIMESTAMP 
            WHERE id = 1
        """
        
        execute(updateSQL) { success in
            if !success {
                print("Error updating habits formed")
            }
        }
    }
    
    func getStats() -> (launches: Int, habitsCreated: Int, habitsFormed: Int) {
        let querySQL = "SELECT app_launches, habits_created, habits_formed FROM usage_stats WHERE id = 1"
        
        guard let statement = prepare(querySQL) else { return (0, 0, 0) }
        defer { finalize(statement) }
        
        if step(statement) == SQLITE_ROW {
            let launches = columnInt(statement, 0)
            let habitsCreated = columnInt(statement, 1)
            let habitsFormed = columnInt(statement, 2)
            return (launches, habitsCreated, habitsFormed)
        }
        
        return (0, 0, 0)
    }
    
    func getReviewData() -> (lastRequest: String?, habitsFormedAtLastReview: Int)? {
        let querySQL = """
            SELECT last_review_request, habits_formed_at_last_review 
            FROM usage_stats WHERE id = 1
        """
        
        guard let statement = prepare(querySQL) else { return nil }
        defer { finalize(statement) }
        
        if step(statement) == SQLITE_ROW {
            let lastRequest = columnText(statement, 0)
            let habitsFormedAtLastReview = columnInt(statement, 1)
            return (lastRequest, habitsFormedAtLastReview)
        }
        
        return nil
    }
    
    func recordReviewRequest() {
        let updateSQL = """
            UPDATE usage_stats 
            SET last_review_request = CURRENT_TIMESTAMP,
                habits_formed_at_last_review = habitsFormed
            WHERE id = 1
        """
        
        execute(updateSQL) { success in
            if !success {
                print("Error recording review request")
            }
        }
    }
}
