# Implementation Plan: Drawer Navigation and AI Page

## Overview

This implementation adds drawer navigation, replaces the Profile tab with an AI page in the bottom navigation, and fixes several code quality issues including deprecated API usage, dependency configuration, and async context handling. The implementation follows a phased approach: localization setup, new components creation, existing component modifications, bug fixes, and testing.

## Tasks

- [x] 1. Add localization strings for new UI elements
  - Add translation keys to app_en.arb, app_ru.arb, and app_uz.arb files
  - Keys to add: "drawer", "ai", "aiTitle", "aiDescription"
  - Ensure translations are contextually appropriate for each language
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.7_

- [ ] 2. Create AIScreen widget
  - [x] 2.1 Implement AIScreen placeholder widget
    - Create lib/screens/ai_screen.dart file
    - Implement Scaffold with AppBar showing localized title
    - Add centered Column with AI icon, title, and description
    - Use Material Design 3 theme colors and typography
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6_

  - [x] 2.2 Write unit tests for AIScreen
    - Test that screen displays centered title
    - Test that screen displays "coming soon" message
    - Test that screen displays AI-related icon
    - Test that screen has app bar with title
    - _Requirements: 3.1, 3.2, 3.3, 3.6_

- [ ] 3. Create AppDrawer widget
  - [x] 3.1 Implement AppDrawer custom widget
    - Create lib/widgets/app_drawer.dart file
    - Add properties: selectedIndex, onItemSelected callback, onLogout callback
    - Implement DrawerHeader with app branding
    - Add 5 navigation ListTiles (Today, Upcoming, Categories, Statistics, Profile)
    - Add Divider and Logout ListTile at bottom
    - Use icon mapping from design (outlined/filled based on selection)
    - Highlight currently selected item
    - _Requirements: 1.3, 1.5, 1.8, 1.9_

  - [x] 3.2 Write unit tests for AppDrawer
    - Test drawer contains exactly 5 navigation items plus logout button
    - Test drawer displays correct icons for each item
    - Test logout button is positioned at bottom
    - Test drawer highlights currently selected item
    - _Requirements: 1.3, 1.5, 1.8, 1.9_

- [ ] 4. Modify HomeScreen for drawer and AI navigation
  - [x] 4.1 Update HomeScreen navigation structure
    - Add drawer icon to AppBar leading property using Builder pattern
    - Add drawer property to Scaffold with AppDrawer widget
    - Update _screens list to include AIScreen at index 4, ProfileScreen at index 5
    - Update _selectedIndex range to support 0-5 (6 screens total)
    - _Requirements: 1.1, 1.2, 1.4, 2.1, 2.3, 3.5_

  - [x] 4.2 Update bottom navigation bar items
    - Replace Profile tab with AI tab in bottom navigation items
    - Use appropriate AI icon (Icons.psychology or similar)
    - Ensure exactly 5 tabs: Today, Upcoming, Categories, Statistics, AI
    - Maintain existing visual style and behavior
    - _Requirements: 2.1, 2.2, 2.4, 2.5_

  - [x] 4.3 Implement drawer callbacks
    - Add _handleLogout() method for logout confirmation dialog
    - Implement session clearing and navigation to login screen on logout
    - Wire onItemSelected callback to update _selectedIndex
    - Wire onLogout callback to _handleLogout method
    - _Requirements: 1.6, 1.7_

  - [x] 4.4 Write property test for drawer navigation consistency
    - **Property 1: Drawer Navigation Consistency**
    - **Validates: Requirements 1.4**
    - Generate random drawer item index (0-5)
    - Tap drawer item and verify selected index and displayed screen match
    - _Requirements: 1.4_

  - [~] 4.5 Write property test for drawer highlight synchronization
    - **Property 2: Drawer Highlight Synchronization**
    - **Validates: Requirements 1.9**
    - Generate random screen index (0-5)
    - Set selected index and verify drawer highlights correct item
    - _Requirements: 1.9_

  - [~] 4.6 Write property test for icon consistency
    - **Property 3: Icon Consistency Between Navigation Methods**
    - **Validates: Requirements 1.8**
    - Generate random index for screens in both nav methods (0-3)
    - Verify drawer icon matches bottom nav icon for same screen
    - _Requirements: 1.8_

  - [~] 4.7 Write property test for bottom navigation tab switching
    - **Property 4: Bottom Navigation Tab Switching**
    - **Validates: Requirements 2.6**
    - Generate random bottom nav index (0-4)
    - Tap bottom nav item and verify indicator and screen update
    - _Requirements: 2.6_

  - [~] 4.8 Write property test for AI page accessibility
    - **Property 5: AI Page Accessibility**
    - **Validates: Requirements 3.5**
    - Generate random navigation method (bottom nav or drawer)
    - Navigate to AI page via method and verify same screen displayed
    - _Requirements: 3.5_

- [x] 5. Checkpoint - Verify navigation functionality
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Fix deprecated withOpacity usage
  - [x] 6.1 Replace withOpacity in ProfileScreen
    - Replace all withOpacity() calls with withValues(alpha: x)
    - Verify visual appearance remains identical
    - _Requirements: 4.1, 4.5_

  - [x] 6.2 Replace withOpacity in StatisticsScreen
    - Replace all withOpacity() calls with withValues(alpha: x)
    - Verify visual appearance remains identical
    - _Requirements: 4.2, 4.5_

  - [x] 6.3 Replace withOpacity in TaskCard widget
    - Replace all withOpacity() calls with withValues(alpha: x)
    - Verify visual appearance remains identical
    - _Requirements: 4.3, 4.5_

  - [~] 6.4 Write property test for color opacity visual equivalence
    - **Property 6: Color Opacity Visual Equivalence**
    - **Validates: Requirements 4.5**
    - Generate random color and opacity value (0.0-1.0)
    - Compare ARGB values of withValues(alpha: x) vs deprecated withOpacity(x)
    - _Requirements: 4.5_

- [ ] 7. Fix image_picker dependency configuration
  - [x] 7.1 Move image_picker to dependencies section
    - Update pubspec.yaml to move image_picker from dev_dependencies to dependencies
    - Verify ProfileScreen continues to function correctly
    - _Requirements: 5.1, 5.2, 5.3_

  - [~] 7.2 Write property test for profile image selection
    - **Property 7: Profile Image Selection**
    - **Validates: Requirements 5.3**
    - Generate random valid image file path
    - Select image and verify profile displays selected image
    - _Requirements: 5.3_

- [ ] 8. Fix async BuildContext issues
  - [x] 8.1 Add mounted checks to NewTaskBottomSheet
    - Add if (!mounted) return; checks before using BuildContext after async operations
    - Capture ScaffoldMessenger before async operations where needed
    - _Requirements: 6.2, 6.4_

  - [x] 8.2 Add mounted checks to EditTaskBottomSheet
    - Add if (!mounted) return; checks before using BuildContext after async operations
    - Capture ScaffoldMessenger before async operations where needed
    - _Requirements: 6.1, 6.4_

  - [~] 8.3 Write property test for async operation safety
    - **Property 8: Async Operation Safety**
    - **Validates: Requirements 6.4**
    - Generate random async operation (save, delete, create)
    - Start operation, dispose widget, verify no crash
    - _Requirements: 6.4_

- [ ] 9. Fix unnecessary type check warning
  - [x] 9.1 Remove unnecessary type check in NewTaskBottomSheet
    - Replace "hiveKey is int ? hiveKey : hiveKey.hashCode" with "hiveKey as int"
    - Verify linter no longer produces unnecessary type check warnings
    - _Requirements: 7.1, 7.2, 7.3_

- [ ] 10. Verify localization integration
  - [~] 10.1 Write property test for localization consistency in drawer
    - **Property 9: Localization Consistency in Drawer**
    - **Validates: Requirements 8.5**
    - Generate random locale (uz, en, ru)
    - Change language and verify all drawer items use correct locale
    - _Requirements: 8.5_

  - [~] 10.2 Write property test for localization consistency in AI page
    - **Property 10: Localization Consistency in AI Page**
    - **Validates: Requirements 8.6**
    - Generate random locale (uz, en, ru)
    - Change language and verify AI page content uses correct locale
    - _Requirements: 8.6_

- [ ] 11. Verify existing functionality preservation
  - [~] 11.1 Write property test for navigation method equivalence
    - **Property 11: Navigation Method Equivalence**
    - **Validates: Requirements 9.5**
    - Generate random screen index (0-3) and navigation method
    - Navigate via method and verify same screen and state
    - _Requirements: 9.5_

  - [~] 11.2 Write property test for existing navigation preservation
    - **Property 12: Existing Navigation Preservation**
    - **Validates: Requirements 9.1**
    - Generate random screen index (0-5)
    - Navigate to screen and verify correct screen displayed
    - _Requirements: 9.1_

  - [~] 11.3 Write integration tests for complete user flows
    - Test full navigation flow: drawer → screen → bottom nav → screen
    - Test logout flow: drawer logout → confirmation → session clear → login screen
    - Test language change propagation to all UI elements
    - Test task creation flow with FAB still works with new navigation
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [~] 12. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties across all inputs
- Unit tests validate specific examples and edge cases
- Integration tests verify end-to-end user workflows
- The implementation uses Dart/Flutter as specified in the design document
