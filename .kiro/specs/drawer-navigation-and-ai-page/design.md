# Design Document: Drawer Navigation and AI Page

## Overview

This design introduces a side drawer navigation menu to the Flutter Task Manager application, replaces the Profile tab in the bottom navigation with a new AI page placeholder, and addresses several code quality issues including deprecated API usage and async context handling.

The drawer provides an alternative navigation method that includes all five main screens (Today, Upcoming, Categories, Statistics, Profile) plus a logout action. The bottom navigation bar is modified to replace Profile with AI, making the AI feature more discoverable while keeping profile access available through the drawer.

Additionally, this design addresses technical debt by:
- Replacing deprecated `withOpacity()` calls with `withValues()` for Flutter 3.24+ compatibility
- Moving `image_picker` from dev_dependencies to dependencies
- Adding proper `mounted` checks before using BuildContext after async operations
- Removing unnecessary type checks
- Adding localization support for all new UI elements

## Architecture

### Component Structure

```
HomeScreen (Modified)
├── Scaffold
│   ├── AppBar (with drawer icon)
│   ├── Drawer (NEW)
│   │   ├── DrawerHeader
│   │   ├── Navigation Items (5)
│   │   └── Logout Button
│   ├── Body (IndexedStack)
│   │   ├── TodayScreen
│   │   ├── UpcomingScreen
│   │   ├── CategoriesScreen
│   │   ├── StatisticsScreen
│   │   ├── AIScreen (NEW)
│   │   └── ProfileScreen
│   ├── BottomNavigationBar (Modified)
│   │   ├── Today
│   │   ├── Upcoming
│   │   ├── Categories
│   │   ├── Statistics
│   │   └── AI (replaces Profile)
│   └── FloatingActionButton
```

### Navigation Flow

The app supports two navigation methods:
1. **Bottom Navigation Bar**: Quick access to Today, Upcoming, Categories, Statistics, and AI
2. **Drawer**: Access to all screens including Profile, plus logout functionality

Both navigation methods update the same `_selectedIndex` state variable, ensuring consistent behavior regardless of navigation source.

### State Management

The HomeScreen maintains a single `_selectedIndex` integer that controls which screen is displayed in the IndexedStack. This index is updated by:
- Bottom navigation bar taps
- Drawer item taps
- The drawer highlights the currently selected item based on this index

## Components and Interfaces

### 1. AppDrawer Widget (NEW)

A custom drawer widget that encapsulates all drawer UI and behavior.

**Location**: `lib/widgets/app_drawer.dart`

**Properties**:
- `selectedIndex`: Current navigation index
- `onItemSelected`: Callback function `(int index) -> void`
- `onLogout`: Callback function `() -> void`

**UI Structure**:
- DrawerHeader with app branding/user info
- ListTile for each navigation item (Today, Upcoming, Categories, Statistics, Profile)
- Divider
- Logout ListTile at bottom

**Icon Mapping**:
- Today: `Icons.check_circle_outline` / `Icons.check_circle`
- Upcoming: `Icons.calendar_today_outlined` / `Icons.calendar_today`
- Categories: `Icons.folder_outlined` / `Icons.folder`
- Statistics: `Icons.bar_chart_outlined` / `Icons.bar_chart`
- Profile: `Icons.person_outline` / `Icons.person`
- Logout: `Icons.logout`

### 2. AIScreen Widget (NEW)

A placeholder screen for future AI features.

**Location**: `lib/screens/ai_screen.dart`

**UI Structure**:
```dart
Scaffold(
  appBar: AppBar(title: Text(l10n.aiTitle)),
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.psychology, size: 100, color: primary),
        SizedBox(height: 24),
        Text(l10n.aiTitle, style: headline),
        SizedBox(height: 16),
        Text(l10n.aiDescription, style: body, textAlign: center),
      ],
    ),
  ),
)
```

### 3. HomeScreen Modifications

**Changes**:
1. Add drawer icon to AppBar: `leading: Builder(builder: (context) => IconButton(icon: Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()))`
2. Add `drawer` property to Scaffold with AppDrawer widget
3. Update `_screens` list to include AIScreen at index 4, ProfileScreen at index 5
4. Update bottom navigation items: replace Profile with AI
5. Add `_handleLogout()` method for drawer logout callback
6. Update `_selectedIndex` range to 0-5 (6 screens total)

**Index Mapping**:
- 0: TodayScreen
- 1: UpcomingScreen
- 2: CategoriesScreen
- 3: StatisticsScreen
- 4: AIScreen
- 5: ProfileScreen

**Bottom Nav Indices**: 0-4 (Today, Upcoming, Categories, Statistics, AI)
**Drawer Indices**: 0-5 (Today, Upcoming, Categories, Statistics, AI, Profile)

### 4. Bug Fixes

#### withOpacity → withValues Migration

**Affected Files**:
- `lib/screens/profile_screen.dart`: Line with gradient color
- `lib/screens/statistics_screen.dart`: Multiple shadow and container colors
- `lib/widgets/task_card.dart`: Category chip background color

**Migration Pattern**:
```dart
// Before
color.withOpacity(0.7)

// After
color.withValues(alpha: 0.7)
```

#### image_picker Dependency Fix

**Change**: Move `image_picker: ^1.1.2` from `dev_dependencies` to `dependencies` in `pubspec.yaml`

#### Async BuildContext Fixes

**Pattern**:
```dart
// Before
await someAsyncOperation();
Navigator.pop(context);  // ❌ context used after async gap

// After
await someAsyncOperation();
if (!mounted) return;
Navigator.pop(context);  // ✅ mounted check added
```

**Affected Files**:
- `lib/widgets/new_task_bottom_sheet.dart`: After task creation
- `lib/widgets/edit_task_bottom_sheet.dart`: After task update and delete

**Alternative Pattern** (already used in some places):
```dart
final messenger = ScaffoldMessenger.of(context);
await someAsyncOperation();
if (!mounted) return;
messenger.showSnackBar(...);  // ✅ messenger captured before async
```

#### Type Check Removal

**File**: `lib/widgets/new_task_bottom_sheet.dart`

**Change**:
```dart
// Before
final int notifId = hiveKey is int ? hiveKey : hiveKey.hashCode;

// After
final int notifId = hiveKey as int;
```

**Rationale**: Hive box.add() always returns an int key, so the type check is unnecessary.

## Data Models

No new data models are required. The feature uses existing models:
- `Task`: Existing task model (no changes)
- Session data via `SessionService`: Existing service (no changes)

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Drawer Navigation Consistency

*For any* navigation item in the drawer (indices 0-5), when tapped, the HomeScreen should navigate to the corresponding screen and update the selected index to match.

**Validates: Requirements 1.4**

### Property 2: Drawer Highlight Synchronization

*For any* selected screen index, the drawer should highlight the corresponding navigation item to reflect the current state.

**Validates: Requirements 1.9**

### Property 3: Icon Consistency Between Navigation Methods

*For any* screen accessible from both drawer and bottom navigation (Today, Upcoming, Categories, Statistics), the icon used in the drawer should match the icon used in the bottom navigation bar.

**Validates: Requirements 1.8**

### Property 4: Bottom Navigation Tab Switching

*For any* bottom navigation tab (indices 0-4), when tapped, the HomeScreen should update the selected tab indicator and navigate to the corresponding screen.

**Validates: Requirements 2.6**

### Property 5: AI Page Accessibility

*For any* navigation method (bottom navigation bar or drawer), navigating to the AI page should display the same AIScreen instance.

**Validates: Requirements 3.5**

### Property 6: Color Opacity Visual Equivalence

*For any* color with opacity value, using `withValues(alpha: x)` should produce visually identical output to the deprecated `withOpacity(x)`.

**Validates: Requirements 4.5**

### Property 7: Profile Image Selection

*For any* valid image selected through the image picker, the ProfileScreen should update the displayed profile image to match the selected image.

**Validates: Requirements 5.3**

### Property 8: Async Operation Safety

*For any* async operation (save, delete, create tasks) in bottom sheets, if the widget is disposed during the operation, the app should not crash or attempt to use the disposed BuildContext.

**Validates: Requirements 6.4**

### Property 9: Localization Consistency in Drawer

*For any* supported language (Uzbek, English, Russian), when the user changes the language, all navigation items in the drawer should display in the selected language.

**Validates: Requirements 8.5**

### Property 10: Localization Consistency in AI Page

*For any* supported language (Uzbek, English, Russian), when the user changes the language, the AI page title and description should display in the selected language.

**Validates: Requirements 8.6**

### Property 11: Navigation Method Equivalence

*For any* screen accessible from both drawer and bottom navigation, navigating to that screen via either method should result in the same screen being displayed with the same state.

**Validates: Requirements 9.5**

### Property 12: Existing Navigation Preservation

*For any* existing screen (Today, Upcoming, Categories, Statistics, Profile), navigation to that screen should continue to function correctly after the changes.

**Validates: Requirements 9.1**

## Error Handling

### Drawer Navigation Errors

- **Invalid Index**: If an invalid index is passed to navigation, default to index 0 (TodayScreen)
- **Logout Cancellation**: If user cancels logout dialog, close dialog and maintain current state

### Async Context Errors

- **Widget Disposed**: Check `mounted` before using BuildContext after async operations
- **Navigation After Dispose**: Capture ScaffoldMessenger before async operations to show messages safely

### Image Picker Errors

- **Permission Denied**: Handle gracefully, show no error (user simply doesn't select image)
- **Invalid Image**: Validate file exists before displaying

### Localization Errors

- **Missing Translation**: Fall back to English if translation key not found
- **Invalid Locale**: Default to English locale

## Testing Strategy

### Unit Tests

Unit tests focus on specific examples, edge cases, and integration points:

1. **Drawer UI Tests**:
   - Verify drawer contains exactly 5 navigation items plus logout button
   - Verify drawer displays correct icons for each item
   - Verify logout button is positioned at bottom

2. **Bottom Navigation Tests**:
   - Verify bottom nav contains exactly 5 tabs (Today, Upcoming, Categories, Statistics, AI)
   - Verify Profile tab is not present
   - Verify AI tab uses appropriate icon

3. **AI Screen Tests**:
   - Verify AI screen displays centered title
   - Verify AI screen displays "coming soon" message
   - Verify AI screen displays AI-related icon
   - Verify AI screen has app bar with title

4. **Localization Tests**:
   - Verify all ARB files contain required keys: drawer, ai, aiTitle, aiDescription
   - Verify translations are non-empty strings

5. **Navigation Tests**:
   - Verify tapping AI tab navigates to AI screen
   - Verify Profile screen accessible from drawer
   - Verify FAB continues to open new task bottom sheet

6. **Bug Fix Tests**:
   - Verify no withOpacity usage in modified files
   - Verify image_picker in dependencies (not dev_dependencies)
   - Verify mounted checks present in async operations

### Property-Based Tests

Property tests verify universal behaviors across all inputs. Each test should run minimum 100 iterations.

**Test Configuration**: Use Flutter's built-in test framework with custom generators for property-based testing, or integrate a library like `test_api` with custom property test helpers.

1. **Property Test 1: Drawer Navigation Consistency**
   - **Tag**: Feature: drawer-navigation-and-ai-page, Property 1: For any navigation item in the drawer (indices 0-5), when tapped, the HomeScreen should navigate to the corresponding screen and update the selected index to match
   - **Generator**: Random index 0-5
   - **Test**: Tap drawer item, verify selected index and displayed screen match

2. **Property Test 2: Drawer Highlight Synchronization**
   - **Tag**: Feature: drawer-navigation-and-ai-page, Property 2: For any selected screen index, the drawer should highlight the corresponding navigation item to reflect the current state
   - **Generator**: Random index 0-5
   - **Test**: Set selected index, verify drawer highlights correct item

3. **Property Test 3: Icon Consistency Between Navigation Methods**
   - **Tag**: Feature: drawer-navigation-and-ai-page, Property 3: For any screen accessible from both drawer and bottom navigation, the icon used in the drawer should match the icon used in the bottom navigation bar
   - **Generator**: Random index 0-3 (screens in both nav methods)
   - **Test**: Verify drawer icon matches bottom nav icon for same screen

4. **Property Test 4: Bottom Navigation Tab Switching**
   - **Tag**: Feature: drawer-navigation-and-ai-page, Property 4: For any bottom navigation tab (indices 0-4), when tapped, the HomeScreen should update the selected tab indicator and navigate to the corresponding screen
   - **Generator**: Random index 0-4
   - **Test**: Tap bottom nav item, verify indicator and screen update

5. **Property Test 5: AI Page Accessibility**
   - **Tag**: Feature: drawer-navigation-and-ai-page, Property 5: For any navigation method (bottom navigation bar or drawer), navigating to the AI page should display the same AIScreen instance
   - **Generator**: Random navigation method (bottom nav or drawer)
   - **Test**: Navigate to AI page via method, verify same screen displayed

6. **Property Test 6: Color Opacity Visual Equivalence**
   - **Tag**: Feature: drawer-navigation-and-ai-page, Property 6: For any color with opacity value, using withValues(alpha: x) should produce visually identical output to the deprecated withOpacity(x)
   - **Generator**: Random color and opacity value 0.0-1.0
   - **Test**: Compare ARGB values of both methods

7. **Property Test 7: Profile Image Selection**
   - **Tag**: Feature: drawer-navigation-and-ai-page, Property 7: For any valid image selected through the image picker, the ProfileScreen should update the displayed profile image to match the selected image
   - **Generator**: Random valid image file path
   - **Test**: Select image, verify profile displays selected image

8. **Property Test 8: Async Operation Safety**
   - **Tag**: Feature: drawer-navigation-and-ai-page, Property 8: For any async operation in bottom sheets, if the widget is disposed during the operation, the app should not crash or attempt to use the disposed BuildContext
   - **Generator**: Random async operation (save, delete, create)
   - **Test**: Start operation, dispose widget, verify no crash

9. **Property Test 9: Localization Consistency in Drawer**
   - **Tag**: Feature: drawer-navigation-and-ai-page, Property 9: For any supported language, when the user changes the language, all navigation items in the drawer should display in the selected language
   - **Generator**: Random locale (uz, en, ru)
   - **Test**: Change language, verify all drawer items use correct locale

10. **Property Test 10: Localization Consistency in AI Page**
    - **Tag**: Feature: drawer-navigation-and-ai-page, Property 10: For any supported language, when the user changes the language, the AI page title and description should display in the selected language
    - **Generator**: Random locale (uz, en, ru)
    - **Test**: Change language, verify AI page content uses correct locale

11. **Property Test 11: Navigation Method Equivalence**
    - **Tag**: Feature: drawer-navigation-and-ai-page, Property 11: For any screen accessible from both drawer and bottom navigation, navigating to that screen via either method should result in the same screen being displayed with the same state
    - **Generator**: Random screen index 0-3, random navigation method
    - **Test**: Navigate via method, verify same screen and state

12. **Property Test 12: Existing Navigation Preservation**
    - **Tag**: Feature: drawer-navigation-and-ai-page, Property 12: For any existing screen, navigation to that screen should continue to function correctly after the changes
    - **Generator**: Random screen index 0-5
    - **Test**: Navigate to screen, verify correct screen displayed

### Integration Tests

1. **Full Navigation Flow**: Test complete user journey through drawer → screen → bottom nav → screen
2. **Logout Flow**: Test drawer logout → confirmation → session clear → login screen
3. **Language Change Flow**: Test language change propagation to all UI elements
4. **Task Creation Flow**: Verify FAB and task creation still work with new navigation

### Testing Balance

- Unit tests cover specific UI elements, edge cases, and static checks
- Property tests cover universal navigation behaviors, localization, and state consistency
- Integration tests verify end-to-end user workflows
- Together, they provide comprehensive coverage without redundancy
