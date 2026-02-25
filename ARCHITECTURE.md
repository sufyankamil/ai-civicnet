# Project Architecture

## 1. Current Architecture Analysis

The `community_net` Flutter project currently follows a traditional **Layered Architecture by Type**.

### Current Structure:
```
lib/
├── components/   # Reusable UI widgets
├── models/       # Data models
├── screens/      # UI screens organized by feature/domain
├── services/     # Third-party integrations & Business logic
├── theme/        # App styling
├── widgets/      # General widgets
└── main.dart     # Entry point
```

### Problems with the Current Architecture:
1. **Tight Coupling (UI & Services)**: The Presentation layer (screens) interacts directly with the Data/Service layer. For instance, `LoginScreen` directly calls `SupabaseService().signIn()`. This makes unit testing the UI or business logic extremely difficult.
2. **Lack of State Management**: There is no dedicated state management solution (like Provider, Riverpod, or BLoC) for managing the UI state based on business logic. State is handled locally using `StatefulWidget` and `setState`, which becomes unmanageable as the app scales.
3. **No Domain Layer**: The business logic is scattered across UI components and generic "Services". There are no clear UseCases or abstract repositories defining the contracts.
4. **Poor Scalability**: Organizing files by type (`screens/`, `services/`, `models/`) rather than by feature means that as the app grows, developers have to jump between multiple distant folders to work on a single feature.

---

## 2. Target Architecture: Clean Architecture

To ensure the project is scalable, maintainable, and testable, we are migrating to **Clean Architecture** combined with a **Feature-First folder structure** and the **MVVM (Model-View-ViewModel)** pattern in the presentation layer.

### Target Structure:
```
lib/
├── core/                   # App-wide core files (errors, network, constants, utils, di)
├── components/             # Reusable global UI widgets (e.g., PrimaryButton)
├── theme/                  # Theme configuration
├── features/               # Feature-first modules
│   ├── auth/
│   │   ├── domain/         # Entities, Repository Interfaces, UseCases
│   │   ├── data/           # Models, Repository Implementations, Data Sources
│   │   └── presentation/   # ViewModels (MVVM), Screens, Feature Widgets
│   ├── home/
│   ├── discover/
│   ...
└── main.dart               # App entry and initialization
```

### The Three Layers:
#### 1. Presentation Layer (MVVM)
* **View**: The UI (Screens, Widgets). It only listens to state changes and propagates user actions to the ViewModel.
* **ViewModel**: Manages the state for the view and interacts with the Domain layer (UseCases). It does not know anything about Flutter UI details.

#### 2. Domain Layer
* **Entities**: Pure Dart classes representing core business objects.
* **UseCases**: Encapsulate specific business rules (e.g., `LoginUseCase`, `FetchUserRequestsUseCase`).
* **Repositories (Abstract)**: Interfaces defining the contracts for data operations.
* *Rule*: **This layer NEVER imports Flutter or any external data/UI libraries.**

#### 3. Data Layer
* **Models**: Extensions of Entities with fromJson/toJson serialization methods.
* **Data Sources**: Remote (Supabase API) and Local (Hive, SharedPreferences) sources.
* **Repositories (Implementation)**: Act as the single source of truth, fetching from data sources and mapping models to entities the Domain layer expects.

---

## 3. Data Flow Architecture Diagram

```mermaid
graph TD
    subgraph Presentation Layer [Presentation Layer (MVVM)]
        UI[UI/View - Screens & Widgets]
        VM[ViewModel / StateNotifier]
        UI -- User Actions --> VM
        VM -- State Updates --> UI
    end

    subgraph Domain Layer [Domain Layer (Business Logic)]
        UC[UseCases]
        RI[Repository Interfaces]
        E[Entities]
        VM -- Executes --> UC
        UC -- Uses --> RI
        UC -. Returns .-> E
    end

    subgraph Data Layer [Data Layer (Data Source)]
        RI_Impl[Repository Implementations]
        DS_Remote[Remote Data Source (Supabase/API)]
        DS_Local[Local Data Source (Hive/Cache)]
        M[Data Models]
        RI_Impl -. Implements .- RI
        RI_Impl -- Calls --> DS_Remote
        RI_Impl -- Calls --> DS_Local
        DS_Remote -. Returns .-> M
        DS_Local -. Returns .-> M
        RI_Impl -- Maps Models to --> E
    end
```

### Strict Rules to Follow:
1. No API calls directly inside UI components.
2. No business logic inside Widgets.
3. No Firebase/Supabase HTTP logic directly inside the UI.
4. The Domain layer must be pure Dart.
5. Repositories must implement abstract contracts from the Domain layer.
