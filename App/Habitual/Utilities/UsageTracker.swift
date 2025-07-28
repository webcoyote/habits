import Foundation
import Combine
import StoreKit
import UIKit

class UsageTracker: ObservableObject {
    static let shared = UsageTracker()
    private let database = DatabaseManager.shared
    
    @Published var stats: (launches: Int, habitsCreated: Int, habitsFormed: Int) = (0, 0, 0)
    private var countedHabitsToday: Set<String> = []
    private var lastResetDate: Date?
    
    private init() {
        refreshStats()
        resetDailyTrackingIfNeeded()
    }
    
    func incrementAppLaunches() {
        database.incrementAppLaunches()
        refreshStats()
    }
    
    func incrementHabitsCreated() {
        database.incrementHabitsCreated()
        refreshStats()
    }
    
    func incrementHabitsFormed(count: Int = 1) {
        database.incrementHabitsFormed(count: count)
        refreshStats()
    }
    
    func incrementHabitsFormedIfNotCountedToday(habitId: String) {
        resetDailyTrackingIfNeeded()
        
        if !countedHabitsToday.contains(habitId) {
            countedHabitsToday.insert(habitId)
            database.incrementHabitsFormed()
            refreshStats()
        }
    }
    
    private func resetDailyTrackingIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastReset = lastResetDate {
            if !calendar.isDate(lastReset, inSameDayAs: now) {
                countedHabitsToday.removeAll()
                lastResetDate = now
            }
        } else {
            lastResetDate = now
        }
    }
    
    private func refreshStats() {
        stats = database.getStats()
    }
    
    func shouldRequestReview() -> Bool {
        // Criteria 1: User has used the app at least three times
        guard self.stats.launches >= Configuration.ReviewRequest.minimumAppLaunches else { return false }
        
        guard let reviewData = database.getReviewData() else { return false }
        
        // Criteria 2: User has formed habits at least 30 times since last request
        let habitsFormedSinceLastReview = stats.habitsFormed - reviewData.habitsFormedAtLastReview
        guard habitsFormedSinceLastReview >= Configuration.ReviewRequest.minimumCompletedHabits else { return false }
        
        // Criteria 3: At least a week since last request (or never asked)
        if let lastRequestString = reviewData.lastRequest {
            let formatter = ISO8601DateFormatter()
            
            if let lastRequestDate = formatter.date(from: lastRequestString) {
                let weekAgo = Date().addingTimeInterval(-Configuration.ReviewRequest.daysBetweenRequests)
                guard lastRequestDate < weekAgo else { return false }
            }
        }
        
        return true
    }
    
    func recordReviewRequest() {
        database.recordReviewRequest()
    }
    
    @MainActor
    func requestReviewIfAppropriate() async {
        guard shouldRequestReview() else { return }
        
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            if #available(iOS 16.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview(in: scene)
            }
            recordReviewRequest()
        }
    }
}
