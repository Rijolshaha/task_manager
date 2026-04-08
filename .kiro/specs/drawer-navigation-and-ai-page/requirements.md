# Requirements Document

## Introduction

This document specifies requirements for adding drawer navigation and an AI page to the Flutter Task Manager application. The feature will introduce a side drawer menu containing all navigation items, replace the Profile tab in the bottom navigation bar with a new AI page, and fix existing deprecated code issues.

## Glossary

- **Drawer**: A side navigation panel that slides in from the left edge of the screen
- **Bottom_Navigation_Bar**: The navigation bar fixed at the bottom of the screen with tab items
- **AI_Page**: A new screen placeholder for future AI-powered task management features
- **Profile_Screen**: The existing user profile management screen
- **Home_Screen**: The main screen container that manages navigation between different screens
- **Localization_System**: The ARB-based internationalization system supporting Uzbek, English, and Russian
- **withOpacity**: Deprecated Flutter method for color opacity (replaced by withValues)
- **BuildContext**: Flutter's widget tree context object used for navigation and UI operations
- **image_picker**: Flutter package for selecting images from gallery or camera

## Requirements

### Requirement 1: Add Drawer Navigation

**User Story:** As a user, I want to access all app screens from a side drawer menu, so that I can navigate efficiently without relying solely on the bottom navigation bar.

#### Acceptance Criteria

1. WHEN the user opens the app, THE Home_Screen SHALL display a drawer icon in the app bar
2. WHEN the user taps the drawer icon or swipes from the left edge, THE Drawer SHALL slide in from the left
3. THE Drawer SHALL display all five navigation items: Today, Upcoming, Categories, Statistics, and Profile
4. WHEN the user taps a navigation item in the Drawer, THE Home_Screen SHALL navigate to the corresponding screen
5. THE Drawer SHALL display a Logout button at the bottom
6. WHEN the user taps the Logout button, THE Home_Screen SHALL display a confirmation dialog
7. WHEN the user confirms logout, THE Home_Screen SHALL clear session data and navigate to the Login screen
8. THE Drawer SHALL display appropriate icons for each navigation item matching the Bottom_Navigation_Bar icons
9. THE Drawer SHALL highlight the currently active screen

### Requirement 2: Modify Bottom Navigation Bar

**User Story:** As a user, I want to see an AI tab instead of Profile in the bottom navigation, so that I can quickly access AI features while keeping profile access in the drawer.

#### Acceptance Criteria

1. THE Bottom_Navigation_Bar SHALL display exactly five tabs: Today, Upcoming, Categories, Statistics, and AI
2. THE Bottom_Navigation_Bar SHALL NOT display the Profile tab
3. WHEN the user taps the AI tab, THE Home_Screen SHALL navigate to the AI_Page
4. THE Bottom_Navigation_Bar SHALL use an appropriate AI-related icon for the AI tab
5. THE Bottom_Navigation_Bar SHALL maintain the same visual style and behavior as before
6. WHEN the user switches tabs, THE Home_Screen SHALL update the selected tab indicator

### Requirement 3: Create AI Page

**User Story:** As a user, I want to see a placeholder AI page, so that I know the feature exists and will be developed in the future.

#### Acceptance Criteria

1. THE AI_Page SHALL display a centered title indicating it is the AI feature page
2. THE AI_Page SHALL display a descriptive message explaining that AI features are coming soon
3. THE AI_Page SHALL use an AI-related icon or illustration
4. THE AI_Page SHALL follow the app's Material Design 3 theme and color scheme
5. THE AI_Page SHALL be accessible from both the Bottom_Navigation_Bar and the Drawer
6. THE AI_Page SHALL display an app bar with the AI page title

### Requirement 4: Fix Deprecated withOpacity Usage

**User Story:** As a developer, I want to use the current Flutter API, so that the app remains compatible with Flutter 3.24+ and avoids deprecation warnings.

#### Acceptance Criteria

1. THE Profile_Screen SHALL replace all withOpacity() calls with withValues()
2. THE Statistics_Screen SHALL replace all withOpacity() calls with withValues()
3. THE Task_Card widget SHALL replace all withOpacity() calls with withValues()
4. WHEN the app is compiled, THE build process SHALL NOT produce withOpacity deprecation warnings
5. THE visual appearance of colors SHALL remain identical after the change

### Requirement 5: Add image_picker Dependency

**User Story:** As a developer, I want image_picker properly declared as a dependency, so that the Profile_Screen can use it without import errors.

#### Acceptance Criteria

1. THE pubspec.yaml file SHALL include image_picker in the dependencies section (not dev_dependencies)
2. WHEN the app is compiled, THE build process SHALL NOT produce import warnings for image_picker
3. THE Profile_Screen SHALL continue to function correctly for selecting profile images

### Requirement 6: Fix Async BuildContext Issues

**User Story:** As a developer, I want to properly handle BuildContext in async operations, so that the app avoids potential crashes and follows Flutter best practices.

#### Acceptance Criteria

1. THE Edit_Task_Bottom_Sheet SHALL check widget.mounted before using BuildContext after async operations
2. THE New_Task_Bottom_Sheet SHALL check widget.mounted before using BuildContext after async operations
3. WHEN the app is analyzed, THE linter SHALL NOT produce async BuildContext warnings
4. WHEN a user performs async operations (save, delete, create tasks), THE app SHALL NOT crash if the widget is disposed

### Requirement 7: Fix Unnecessary Type Check Warning

**User Story:** As a developer, I want to remove unnecessary type checks, so that the code is cleaner and follows Dart best practices.

#### Acceptance Criteria

1. THE New_Task_Bottom_Sheet SHALL remove the unnecessary "hiveKey is int" type check
2. THE New_Task_Bottom_Sheet SHALL use hiveKey directly as an int for notification ID
3. WHEN the app is analyzed, THE linter SHALL NOT produce unnecessary type check warnings

### Requirement 8: Add Localization Support

**User Story:** As a multilingual user, I want all new UI elements translated into Uzbek, English, and Russian, so that I can use the app in my preferred language.

#### Acceptance Criteria

1. THE Localization_System SHALL include translations for "drawer" in all three languages
2. THE Localization_System SHALL include translations for "ai" (tab label) in all three languages
3. THE Localization_System SHALL include translations for "aiTitle" (page title) in all three languages
4. THE Localization_System SHALL include translations for "aiDescription" (coming soon message) in all three languages
5. WHEN the user changes language, THE Drawer SHALL display navigation items in the selected language
6. WHEN the user changes language, THE AI_Page SHALL display content in the selected language
7. THE app_en.arb, app_ru.arb, and app_uz.arb files SHALL contain all new translation keys

### Requirement 9: Maintain Existing Functionality

**User Story:** As a user, I want all existing features to continue working, so that the new changes don't break my workflow.

#### Acceptance Criteria

1. THE Home_Screen SHALL continue to support all existing navigation between screens
2. THE Profile_Screen SHALL remain accessible through the Drawer
3. THE floating action button for creating new tasks SHALL continue to function
4. THE task list, categories, statistics, and profile features SHALL continue to work as before
5. WHEN the user navigates using either the Drawer or Bottom_Navigation_Bar, THE app SHALL maintain consistent state
6. THE Hive local storage SHALL continue to be used for all data persistence
