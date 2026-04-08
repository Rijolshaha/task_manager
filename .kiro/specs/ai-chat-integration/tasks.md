# Implementation Plan: AI Chat Integration

## Overview

This implementation plan transforms the placeholder AI page into a fully functional ChatGPT-powered assistant. The implementation follows a layered architecture with clear separation between UI (screens/widgets), business logic (providers/services), and data layers (repositories/storage). The feature includes secure API key management, streaming message responses, persistent chat history, and full localization support across Uzbek, English, and Russian.

## Tasks

- [x] 1. Set up dependencies and data models
  - Add required packages to pubspec.yaml: flutter_secure_storage, http, uuid
  - Create ChatMessage model with Hive annotations (id, content, isUser, timestamp, status)
  - Create MessageStatus enum (sending, sent, error)
  - Generate Hive type adapters using build_runner
  - Create OpenAI API models (ChatCompletionRequest, ChatMessagePayload, ChatCompletionResponse)
  - _Requirements: 6.3, 11.1, 11.2_

- [x] 1.1 Write property test for ChatMessage model
  - **Property 19: Message Persistence Round-Trip**
  - **Validates: Requirements 6.1, 6.2, 6.3**

- [ ] 2. Implement API Key Manager service
  - [x] 2.1 Create ApiKeyManager class with flutter_secure_storage
    - Implement saveApiKey() method with secure storage
    - Implement getApiKey() method to retrieve stored key
    - Implement deleteApiKey() method
    - Implement validateKeyFormat() method (starts with "sk-", min 20 chars)
    - Use storage key "openai_api_key"
    - _Requirements: 1.3, 1.4, 1.6_

  - [x] 2.2 Write property test for API key validation
    - **Property 1: API Key Format Validation**
    - **Validates: Requirements 1.3**

  - [x] 2.3 Write property test for API key configuration round-trip
    - **Property 2: API Key Configuration Round-Trip**
    - **Validates: Requirements 1.7**

  - [x] 2.4 Write unit tests for ApiKeyManager
    - Test valid API key format acceptance
    - Test invalid API key format rejection
    - Test secure storage save/retrieve operations
    - Test key deletion
    - _Requirements: 1.3, 1.4, 1.6_

- [ ] 3. Implement Message Repository
  - [x] 3.1 Create MessageRepository class with Hive integration
    - Initialize Hive box for "chat_messages"
    - Implement saveMessage() method
    - Implement loadMessages() method with chronological ordering
    - Implement clearMessages() method
    - Implement enforceMessageLimit() method (max 100 messages, prune oldest)
    - _Requirements: 6.1, 6.2, 6.6, 6.7_

  - [ ] 3.2 Write property test for message persistence
    - **Property 19: Message Persistence Round-Trip**
    - **Validates: Requirements 6.1, 6.2, 6.3**

  - [~] 3.3 Write property test for message limit enforcement
    - **Property 21: Message Limit Enforcement**
    - **Validates: Requirements 6.7**

  - [~] 3.4 Write unit tests for MessageRepository
    - Test message save and load operations
    - Test clear history functionality
    - Test 100-message limit enforcement
    - Test chronological ordering
    - _Requirements: 6.1, 6.2, 6.6, 6.7_

- [~] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement Task Context Provider
  - [~] 5.1 Create TaskContextProvider class
    - Implement getTaskContext() method to read from existing Hive task box
    - Implement getTaskStatistics() method (total, completed, pending, categories)
    - Format context string with task statistics (max 500 chars)
    - Calculate overdue tasks count
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.6_

  - [~] 5.2 Write property test for task context formatting
    - **Property 23: Task Context Formatting**
    - **Validates: Requirements 8.4**

  - [~] 5.3 Write property test for task context size limit
    - **Property 24: Task Context Size Limit**
    - **Validates: Requirements 8.6**

  - [~] 5.4 Write unit tests for TaskContextProvider
    - Test task statistics calculation
    - Test context string formatting
    - Test 500-character limit enforcement
    - _Requirements: 8.4, 8.6_

- [ ] 6. Implement Chat Service with OpenAI API integration
  - [~] 6.1 Create ChatService class with HTTP client
    - Implement sendMessageStream() method with streaming support
    - Configure API endpoint: https://api.openai.com/v1/chat/completions
    - Set model to "gpt-3.5-turbo", max_tokens to 500, temperature to 0.7
    - Include Authorization header with "Bearer {api_key}" format
    - Set Content-Type header to "application/json"
    - Implement 30-second timeout
    - Build messages array with system prompt, conversation history, and user message
    - _Requirements: 3.3, 3.4, 3.6, 11.1, 11.2, 11.3, 11.4, 11.5, 11.6_

  - [~] 6.2 Implement Server-Sent Events (SSE) stream parsing
    - Parse SSE stream from OpenAI API response
    - Extract content chunks from "data:" lines
    - Handle "[DONE]" termination signal
    - Yield progressive content chunks as Stream<String>
    - _Requirements: 4.6, 4.7_

  - [~] 6.3 Implement error handling and retry logic
    - Create ChatError class with type, message, technicalDetails, isRetryable
    - Create ErrorHandler class to parse HTTP errors
    - Handle 401 (invalid API key), 429 (rate limit), 408/timeout, 500+ (server errors)
    - Implement exponential backoff retry strategy (1s, 2s, 4s, 8s, max 30s)
    - Log all errors with sanitized details
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.7_

  - [~] 6.4 Implement validateApiKey() method
    - Send test request to OpenAI API with provided key
    - Return success/failure based on API response
    - _Requirements: 1.3_

  - [~] 6.5 Write property test for conversation context inclusion
    - **Property 9: Conversation Context Included in Requests**
    - **Validates: Requirements 3.4**

  - [~] 6.6 Write property test for authorization header
    - **Property 29: Authorization Header Inclusion**
    - **Validates: Requirements 11.3**

  - [~] 6.7 Write property test for content-type header
    - **Property 30: Request Content-Type Header**
    - **Validates: Requirements 11.4**

  - [~] 6.8 Write property test for error parsing
    - **Property 18: Error Message Parsing**
    - **Validates: Requirements 5.7**

  - [~] 6.9 Write unit tests for ChatService
    - Test API request construction with correct parameters
    - Test SSE stream parsing with sample responses
    - Test error handling for each error type (401, 429, timeout, 500+)
    - Test retry logic with exponential backoff
    - Mock HTTP client for all tests
    - _Requirements: 3.3, 3.4, 3.6, 4.6, 5.1, 5.2, 5.3, 5.4, 11.1-11.7_

- [~] 7. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Implement Chat Provider for state management
  - [~] 8.1 Create ChatProvider class extending ChangeNotifier
    - Add state properties: messages list, isLoading, error, hasApiKey
    - Inject dependencies: ChatService, MessageRepository, TaskContextProvider, ApiKeyManager
    - Implement loadHistory() method to load messages from repository
    - _Requirements: 6.2_

  - [~] 8.2 Implement sendMessage() method
    - Validate input (non-empty, trim whitespace, under 2000 chars)
    - Create user message with UUID and current timestamp
    - Add user message to messages list and notify listeners
    - Save user message to repository
    - Set isLoading to true and notify listeners
    - Get task context from TaskContextProvider
    - Call ChatService.sendMessageStream() with message, history, and context
    - Create AI message with empty content
    - Listen to stream chunks and progressively update AI message content
    - Save complete AI message to repository when stream completes
    - Set isLoading to false and notify listeners
    - Handle errors and set error state
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.6, 4.7, 8.7, 12.3, 12.4_

  - [~] 8.3 Implement clearHistory() method
    - Call MessageRepository.clearMessages()
    - Clear messages list and notify listeners
    - _Requirements: 6.5, 6.6_

  - [~] 8.4 Implement clearError() method
    - Set error to null and notify listeners

  - [~] 8.5 Write property test for message addition to history
    - **Property 6: Message Addition to History**
    - **Validates: Requirements 3.1, 4.3**

  - [~] 8.6 Write property test for input field cleared after send
    - **Property 7: Input Field Cleared After Send**
    - **Validates: Requirements 3.2**

  - [~] 8.7 Write property test for task context freshness
    - **Property 25: Task Context Freshness**
    - **Validates: Requirements 8.7**

  - [~] 8.8 Write property test for clear history
    - **Property 20: Clear History Removes All Messages**
    - **Validates: Requirements 6.6**

  - [~] 8.9 Write unit tests for ChatProvider
    - Test loadHistory() loads messages from repository
    - Test sendMessage() workflow (add user message, call service, add AI response)
    - Test clearHistory() removes all messages
    - Test error handling sets error state
    - Test loading state transitions
    - Mock all dependencies
    - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.3, 6.2, 6.6_

- [ ] 9. Implement localization strings
  - [~] 9.1 Add AI chat translations to ARB files
    - Add to app_en.arb: "ai_assistant", "type_message", "send", "clear_history", "api_key_setup", "enter_api_key", "save", "cancel"
    - Add error message keys: "invalid_api_key", "network_error", "rate_limit_error", "timeout_error", "server_error", "validation_error"
    - Add welcome message and usage suggestions keys
    - Translate all keys to Uzbek in app_uz.arb
    - Translate all keys to Russian in app_ru.arb
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [~] 9.2 Write property test for locale change updates
    - **Property 22: Locale Change Updates UI Text**
    - **Validates: Requirements 7.2, 7.6**

  - [~] 9.3 Write unit tests for localization
    - Test all keys exist in all three languages
    - Test timestamp formatting for each locale
    - _Requirements: 7.1, 7.2, 7.3, 7.7_

- [ ] 10. Implement UI widgets
  - [~] 10.1 Create MessageBubble widget
    - Display message content with appropriate styling
    - Distinguish user messages (right-aligned, blue) from AI messages (left-aligned, gray)
    - Display formatted timestamp below message
    - Support multiline text with proper wrapping
    - _Requirements: 2.2, 2.4_

  - [~] 10.2 Create TypingIndicator widget
    - Display animated dots to indicate AI is typing
    - Use three dots with sequential fade animation
    - _Requirements: 4.4, 4.5_

  - [~] 10.3 Create ChatInput widget
    - Create StatefulWidget with TextEditingController
    - Display multiline TextField with hint text from localization
    - Display send button (icon) that is enabled only when text is non-empty
    - Implement onSend callback when send button tapped
    - Implement onSend callback when Enter key pressed
    - Clear input field after send
    - Disable input and button when disabled prop is true
    - Show character count when approaching 2000 limit
    - _Requirements: 2.5, 2.6, 2.8, 3.2, 3.7, 12.1, 12.2, 12.5_

  - [~] 10.4 Write property test for send button state
    - **Property 5: Send Button State Reflects Input Validity**
    - **Validates: Requirements 2.6, 12.1**

  - [~] 10.5 Write property test for whitespace normalization
    - **Property 31: Whitespace Normalization**
    - **Validates: Requirements 12.3, 12.4**

  - [~] 10.6 Write widget tests for UI components
    - Test MessageBubble displays content and timestamp correctly
    - Test MessageBubble styling differs for user vs AI messages
    - Test TypingIndicator animation
    - Test ChatInput enables/disables send button based on input
    - Test ChatInput character limit warning
    - Test ChatInput Enter key sends message
    - _Requirements: 2.2, 2.4, 2.6, 2.8, 3.7, 4.4, 12.1, 12.2, 12.5_

- [~] 11. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 12. Implement API Key Setup Dialog
  - [~] 12.1 Create ApiKeySetupDialog widget
    - Create StatefulWidget with TextEditingController
    - Display dialog with title from localization
    - Display secure TextField for API key input (obscureText: true)
    - Display toggle to show/hide API key
    - Display Save and Cancel buttons
    - Validate key format on save using ApiKeyManager.validateKeyFormat()
    - Display validation error if format is invalid
    - Show loading indicator on save button while validating
    - Call onSave callback with validated key
    - Close dialog on successful save or cancel
    - _Requirements: 1.2, 1.3, 9.3_

  - [~] 12.2 Write unit tests for ApiKeySetupDialog
    - Test dialog displays with correct localized text
    - Test validation error shown for invalid format
    - Test onSave called with valid key
    - Test dialog closes on cancel
    - _Requirements: 1.2, 1.3_

- [ ] 13. Implement AI Chat Screen
  - [~] 13.1 Create AiChatScreen StatelessWidget
    - Set up ChangeNotifierProvider for ChatProvider
    - Display AppBar with title "AI Assistant" from localization
    - Add clear history IconButton to AppBar actions
    - Check if API key is configured on init
    - Display ApiKeySetupDialog if no API key configured
    - Display welcome message when chat history is empty
    - Display scrollable ListView of MessageBubble widgets for messages
    - Display TypingIndicator when isLoading is true
    - Display ChatInput at bottom (fixed position)
    - Implement auto-scroll to bottom when new message added
    - Display error SnackBar when error state is set
    - Implement clear history confirmation dialog
    - _Requirements: 1.1, 1.5, 2.1, 2.3, 2.7, 4.4, 6.4, 6.5, 9.1, 9.4_

  - [~] 13.2 Wire ChatInput to ChatProvider
    - Call ChatProvider.sendMessage() when user sends message
    - Disable ChatInput when ChatProvider.isLoading is true
    - Validate message before sending (non-empty, under limit)
    - Display validation error if message is invalid
    - _Requirements: 3.1, 3.2, 3.5, 9.4, 12.1, 12.4, 12.6, 12.7_

  - [~] 13.3 Implement error handling UI
    - Display localized error messages based on error type
    - Show retry button for retryable errors
    - Call ChatProvider.clearError() when error is dismissed
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.6_

  - [~] 13.4 Write property test for message chronological ordering
    - **Property 3: Message Chronological Ordering**
    - **Validates: Requirements 2.1**

  - [~] 13.5 Write property test for timestamp locale formatting
    - **Property 4: Timestamp Locale Formatting**
    - **Validates: Requirements 2.4**

  - [~] 13.6 Write property test for typing indicator lifecycle
    - **Property 14: Typing Indicator Lifecycle**
    - **Validates: Requirements 4.4, 4.5**

  - [~] 13.7 Write property test for UI disabled during processing
    - **Property 10: UI Disabled During Message Processing**
    - **Validates: Requirements 3.5, 9.4**

  - [~] 13.8 Write property test for invalid message validation
    - **Property 32: Invalid Message Validation Error**
    - **Validates: Requirements 12.6**

  - [~] 13.9 Write property test for no API key prevents sending
    - **Property 33: No API Key Prevents Sending**
    - **Validates: Requirements 12.7**

  - [~] 13.10 Write widget tests for AiChatScreen
    - Test screen displays setup dialog when no API key
    - Test screen displays welcome message when history is empty
    - Test screen displays messages in chronological order
    - Test screen auto-scrolls to bottom on new message
    - Test clear history shows confirmation dialog
    - Test error messages display correctly
    - Mock ChatProvider for all tests
    - _Requirements: 1.1, 2.1, 2.3, 2.7, 4.4, 6.4, 6.5_

- [ ] 14. Integrate AI Chat Screen into navigation
  - [~] 14.1 Update HomeScreen navigation
    - Add AI navigation item to BottomNavigationBar
    - Use Icons.chat or Icons.smart_toy for AI icon
    - Add localized label from localization service
    - Navigate to AiChatScreen when AI item tapped
    - Highlight AI item when AiChatScreen is active
    - Preserve AiChatScreen state when navigating away and back
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

  - [~] 14.2 Apply app theme to AI Chat Screen
    - Use existing app color scheme for message bubbles
    - Use existing app typography for message text
    - Ensure consistent styling with other screens
    - _Requirements: 10.7_

  - [~] 14.3 Write property test for navigation state preservation
    - **Property 27: Navigation State Preservation**
    - **Validates: Requirements 10.6**

  - [~] 14.4 Write property test for active navigation highlighting
    - **Property 28: Active Navigation Highlighting**
    - **Validates: Requirements 10.5**

  - [~] 14.5 Write integration tests for navigation
    - Test tapping AI nav item navigates to AiChatScreen
    - Test AI nav item is highlighted when screen is active
    - Test chat state is preserved when navigating away and back
    - _Requirements: 10.1, 10.2, 10.5, 10.6_

- [ ] 15. Final checkpoint and integration testing
  - [~] 15.1 Run all unit tests and property tests
    - Verify all 33 property tests pass
    - Verify all unit tests pass
    - Fix any failing tests
    - _Requirements: All_

  - [~] 15.2 Perform manual integration testing
    - Test complete flow: configure API key → send message → receive response
    - Test error scenarios: invalid key, network error, timeout
    - Test chat history persistence across app restarts
    - Test clear history functionality
    - Test localization in all three languages
    - Test navigation integration
    - Test task context inclusion in AI responses
    - _Requirements: All_

  - [~] 15.3 Final checkpoint
    - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- The implementation follows the existing app architecture and patterns
- All UI components integrate with the existing theme and localization system
- The feature is fully functional after completing all non-optional tasks
