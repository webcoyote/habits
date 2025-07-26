# Habitual iOS App Specification

## Overview
Habitual is a habit tracking iOS application that helps users build and maintain positive habits through visual progress tracking and multiple visualization methods.

## Core Features

### 1. Habit Management
- **Add/Edit/Delete Habits**: Users can create custom habits with personalized names and icons
- **Habit Categories**: Each habit has a distinct color theme for visual organization
- **Icons**: Custom icons for each habit type (exercise, running, water, mood, reading, meditation, sleep)

### 2. Progress Tracking
- **Grid View**: Primary view showing a grid of squares representing days
  - Each row contains approximately 30 squares (monthly view)
  - Filled squares indicate completed days
  - Empty squares indicate incomplete days
  - Current day is highlighted
- **Multiple Visualization Types**:
  - Binary tracking (completed/not completed)
  - Numerical tracking (e.g., "5/8" glasses of water)
  - Mood tracking with line graph visualization
  - Bar chart view for habits with daily quantities

### 3. User Interface
- **Main Screen**: List view of all active habits
  - Each habit card displays:
    - Icon and name
    - Progress grid/chart
    - Quick complete button (circle icon)
  - Floating action button (+) to add new habits
- **Detail View**: Expanded view for each habit showing:
  - Full progress history
  - Statistics
  - Edit capabilities
- **Compact View**: Option to show more habits on screen with truncated names

### 4. Navigation
- **Tab Bar**: Bottom navigation with standard iOS styling
- **Header**: 
  - App name "Habitual" with logo
  - Menu icon for additional options
  - Settings gear icon
  - Premium/star icon
- **Skip/Next Navigation**: For onboarding or tutorial flows

## Technical Requirements

### Platform
- iOS 15.0+
- iPhone optimized
- SwiftUI framework

### Data Model
```swift
struct Habit {
    let id: UUID
    let name: String
    let icon: String
    let color: Color
    let type: HabitType
    let goal: Goal?
    let history: [DayRecord]
}

enum HabitType {
    case binary // Simple yes/no
    case numeric(target: Int) // e.g., 8 glasses of water
    case mood(scale: Int) // e.g., 1-10 scale
}

struct DayRecord {
    let date: Date
    let value: HabitValue
}

enum HabitValue {
    case binary(completed: Bool)
    case numeric(value: Int)
    case mood(value: Int)
}
```

### Color Scheme
- Purple: Exercise/Fitness habits
- Orange/Red: Running/Cardio habits
- Blue: Hydration/Water habits
- Purple (lighter): Mood/Mental health
- Orange (lighter): Reading/Learning habits
- Green: Meditation/Mindfulness
- Purple (darker): Sleep habits

### Key Components
1. **HabitCardView**: Displays individual habit with progress
2. **ProgressGridView**: Shows the grid of completion squares
3. **ProgressChartView**: Shows bar/line charts for numeric habits
4. **HabitListView**: Main screen showing all habits
5. **AddHabitView**: Form for creating new habits
6. **HabitDetailView**: Detailed view of single habit

### Data Persistence
- Core Data for local storage
- iCloud sync capability for cross-device synchronization

### Animations
- Smooth transitions when marking habits complete
- Grid fill animation
- Chart update animations

## User Flow
1. **First Launch**: Brief onboarding showing app features
2. **Main Screen**: View all habits with quick complete actions
3. **Add Habit**: Tap + button, select type, customize appearance
4. **Track Progress**: Tap habit card or complete button
5. **View Details**: Tap habit for expanded view with statistics

## Future Enhancements
- Widget support for home screen
- Apple Watch companion app
- Reminders and notifications
- Social features/accountability partners
- Export data functionality
- Themes and customization options
