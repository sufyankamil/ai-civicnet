# Project Architecture

## 1. Current Architecture Evolution

The project is currently in a **transitional state** from a Layered-by-Type structure to a **Feature-First Clean Architecture**.

### Current Directory Structure:
```
lib/
├── core/             # App-wide utilities, constants, and base classes
├── features/         # 🟢 New Feature-First Modules (Clean Architecture)
│   ├── auth/         # Authentication & User Profiles
│   ├── events/       # Events, RSVP, and Event Comments
│   └── ...           
├── services/         # Infrastructure implementations (Supabase, Logger)
├── components/       # Reusable global UI widgets
├── theme/            # App styling & design system
└── main.dart         # Entry point and dependency initialization
```

### Improvements Implemented:
1. **MVVM with GetX**: We have successfully migrated core features (Events, Auth) to the MVVM pattern using `GetX` for high-performance state management and dependency injection.
2. **Feature Isolation**: Features like `events` now contain their own models, viewmodels, and screens, reducing cross-feature coupling.
3. **Optimized Data Fetching**: Complex joins (e.g., fetching events with attendee counts and RSVP status) are now handled efficiently in the Service layer to avoid N+1 query problems.

---

## 2. Event Messaging Architecture

The recently implemented **Event Comments** system follows a strict data flow to ensure consistency and a premium UI experience.

### Threaded Messaging Flow:
1.  **Data Schema**: `event_comments` table uses a self-referencing `parent_id` for two-level threading (Comment -> Host Reply).
2.  **Service Layer**: `SupabaseService.getEventComments` fetches all comments for an event in a single query and builds the recursive tree structure in memory for efficient UI rendering.
3.  **ViewModel Layer**: `EventsViewModel` manages a reactive list of comments. It clears state between different events to prevent data "leakage" and provides error handling.
4.  **Presentation Layer**: Utilizes custom `CommentTile` components with visual threading (vertical lines) and host-specific visibility rules.

---

## 3. Reactive State Synchronization

A key architectural addition is the **Auth-Event Synchronization** mechanism.

*   **Global Auth Listener**: The `EventsViewModel` (and other core viewmodels) now listens directly to the Supabase `onAuthStateChange` stream.
*   **Automatic Refresh**: Upon login, logout, or user profile changes, the viewmodels automatically re-trigger their data fetches. 
*   **Location Filtering**: This ensures that when a new user logs in, the location-based event filters and localized data are immediately updated without requiring a manual refresh.

---

## 4. Project Data Flow

```mermaid
graph TD
    subgraph Presentation_Layer [Presentation (GetX)]
        UI[View / Screen]
        VM[ViewModel]
        UI -- User Actions --> VM
        VM -- RxState Updates --> UI
    end

    subgraph Service_Logic [Infrastructure Services]
        SS[SupabaseService]
        LS[LoggerService]
        VM -- Calls --> SS
        SS -- Returns Data --> VM
    end

    subgraph Database_Layer [Supabase Backend]
        DB[(PostgreSQL)]
        RLS[Row Level Security]
        SS -- CRUD Ops --> RLS
        RLS -- Filters --> DB
    end
```
 inside the UI.
4. The Domain layer must be pure Dart.
5. Repositories must implement abstract contracts from the Domain layer.
