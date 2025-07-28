import Foundation
import StoreKit
import UIKit

class ReviewRequestManager {
    static let shared = ReviewRequestManager()
    
    private init() {}
    
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
    
    private func shouldRequestReview() -> Bool {
        let settings = AppSettings.shared
        
        let appLaunches = settings.appLaunches
        guard appLaunches >= 3 else { return false }
        
        let completedHabitsCount = settings.totalCompletedHabits
        let completedHabitsSinceLastReview = completedHabitsCount - settings.completedHabitsAtLastReview
        guard completedHabitsSinceLastReview > 50 else { return false }
        
        if let lastRequestDate = settings.lastReviewRequestDate {
            let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            guard lastRequestDate < weekAgo else { return false }
        }
        
        return true
    }
    
    private func recordReviewRequest() {
        let settings = AppSettings.shared
        settings.lastReviewRequestDate = Date()
        settings.completedHabitsAtLastReview = settings.totalCompletedHabits
    }
}
