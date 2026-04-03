# Project Architecture

## 1. Project Organization

The project follows a **Feature-First Clean Architecture** approach, ensuring high modularity and separation of concerns.

### Directory Structure:
```
lib/
├── core/             # App-wide utilities, constants, and base classes
├── features/         # 🟢 Feature-First Modules (Clean Architecture)
│   ├── home/         # Home screen, Community feed, and AI matching UI
│   ├── discover/     # Root-level search, categories, and AI carousels
│   ├── auth/         # Authentication & User Profiles
│   ├── events/       # Events, RSVP, and Event Comments
│   └── request/      # Help requests, creation, and details
├── services/         # Infrastructure implementations (Supabase, AI/Gemini)
├── components/       # Reusable global UI widgets
├── theme/            # App styling & design system (Premium Aura/Glassmorphism)
└── main.dart         # Entry point and dependency initialization
```

---

## 2. AI Opportunity Matching Engine

The core innovation of CivicNet is the **Proactive AI Matching** system, which connects users with help requests based on their skill sets.

### Semantic Matching Flow:
1.  **AI Embeddings**: The `AIService` utilizes the Google Gemini model to generate vector embeddings for both user skills (from profiles) and help request descriptions.
2.  **Vector Similarity**: We use Supabase RPC `match_requests_v3` to perform a cosine similarity search between the user's skill-vector and available requests.
3.  **Tuned Recall**: The match threshold is strategically set to `0.3` (semantic) and `0.6` (for premium "Top Match" UI badges) to ensure a high-quality "For You" experience.
4.  **Real-Time Recommendations**: The `HomeViewModel` and `DiscoverScreen` reactively fetch the `_topRecommendation` and `_recommendedRequests` upon every data refresh or auth-state change.

---

## 3. UI Design System: "Premium AI Aura"

The app utilizes a custom **High-Fidelity UI System** designed to feel state-of-the-art and "alive."

### Core Design Components:
*   **Iridescent Aura (OpportunityCard)**: Uses an animated `SweepGradient` behind a glassmorphic surface to create a "liquid light" border effect.
*   **Breathing Glow**: High-performance `AnimationController` drives a multi-layered `BoxShadow` that expands and contracts, indicating active AI matching.
*   **Advanced Glassmorphism**: Utilizes `BackdropFilter` with `sigma: 20` and inner satin gradients to provide physical depth and high-end texture.
*   **Dynamic Contrast Tuning**: Components automatically adjust label colors (e.g., pure white on vibrant purples) to maintain accessibility without sacrificing aesthetics.

---

## 4. Navigation & Community Structure

To maintain a clean and action-oriented feed, the navigation has been centralized into distinct zones:

*   **🏠 Home Feed**: Prioritizes urgent AI matching and local help requests.
*   **👥 Community (Sub-Tab)**: Houses local neighborhood news and active community polls.
*   **🧭 Discover (Root Tab)**: Serves as the primary exploration hub for categories and broad AI matching carousels.

---

## 5. Reactive State Synchronization

*   **Global Auth Listener**: Core viewmodels listen directly to the Supabase `onAuthStateChange` stream.
*   **Location Filtering**: Location-based data is automatically refreshed upon login/logout, ensuring users always see relative distances and localized matches.
*   **Haptic Integration**: Custom `AppHaptic` wrappers are used project-wide to provide tactile feedback during interactions.

---

## 6. Project Data Flow

```mermaid
graph TD
    subgraph Presentation_Layer [Presentation (MVVM/GetX)]
        UI[View / Screen]
        VM[ViewModel]
        UI -- User Actions --> VM
        VM -- RxState Updates --> UI
    end

    subgraph Service_Logic [Infrastructure Services]
        SS[SupabaseService]
        AI[AIService / Gemini]
        VM -- Calls --> SS
        SS -- Calls AI --> AI
        SS -- Returns Data --> VM
    end

    subgraph Database_Layer [Supabase Backend]
        DB[(PostgreSQL)]
        RPC[match_requests_v3]
        SS -- Vector Search --> RPC
        RPC -- Semantic Match --> DB
    end
```
