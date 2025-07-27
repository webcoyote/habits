import Foundation

class UsageTracker {
    static let shared = UsageTracker()
    private let database = DatabaseManager.shared
    
    private init() {}
    
    func incrementAppLaunches() {
        database.incrementAppLaunches()
    }
    
    func incrementHabitsCreated() {
        database.incrementHabitsCreated()
    }
    
    func incrementHabitsFormed(count: Int = 1) {
        database.incrementHabitsFormed(count: count)
    }
    
    func getStats() -> (launches: Int, habitsCreated: Int, habitsFormed: Int)? {
        return database.getStats()
    }
    
    func shouldRequestReview() -> Bool {
        guard let stats = database.getStats() else { return false }
        
        // Criteria 1: User has used the app at least three times
        guard stats.launches >= 3 else { return false }
        
        guard let reviewData = database.getReviewData() else { return false }
        
        // Criteria 2: User has formed habits at least 30 times since last request
        let habitsFormedSinceLastReview = stats.habitsFormed - reviewData.habitsFormedAtLastReview
        guard habitsFormedSinceLastReview >= 30 else { return false }
        
        // Criteria 3: At least a week since last request (or never asked)
        if let lastRequestString = reviewData.lastRequest {
            let formatter = ISO8601DateFormatter()
            
            if let lastRequestDate = formatter.date(from: lastRequestString) {
                let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
                guard lastRequestDate < weekAgo else { return false }
            }
        }
        
        return true
    }
    
    func recordReviewRequest() {
        database.recordReviewRequest()
    }
}
