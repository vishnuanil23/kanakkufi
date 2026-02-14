# Architecture Refactor Summary

We have refactored the Dashboard feature to better align with Clean Architecture principles:

1.  **Separation of Concerns**:
    - **DashboardScreen (UI)**: Now purely responsible for rendering UI based on the state. All business logic for calculating totals and labels has been removed.
    - **DashboardViewModel (Presentation Logic)**: Now encapsulates the logic for determining display values (`displayTotal`, `totalLabel`) based on the view type (Trimester vs Standard) and underlying data.
    - **DashboardState**: Extended to hold these pre-calculated display properties, ensuring the UI remains declarative.

2.  **Logic Centralization**:
    - Logic for filtering expenses by trimester and summing them is now centralized in `fetchExpenses` within the ViewModel, utilizing the Domain layer utility `PregnancyChartUtils`.

This structure ensures that:
- UI components are lightweight and easier to test.
- Business rules are isolated and reusable.
- The codebase follows the intended `core`, `features`, `shared` structure.
