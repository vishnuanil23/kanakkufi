# KanakkuFi

KanakkuFi is a scalable expense tracking application built using Flutter and Supabase.
It focuses on pregnancy-related expenses while being architected for expansion into a full personal finance platform.

---

## Tech Stack

- Flutter (Mobile + Web)
- Supabase (Auth + PostgreSQL)
- GoRouter
- fl_chart
- Clean Architecture
- MVVM Pattern
- Riverpod

---

## Architecture

KanakkuFi follows **Clean Architecture** with a **Feature-first** structure, ensuring high maintainability and testability.

```
Presentation (Widgets/ViewModels) → Domain (Entities/Interfaces) → Data (Models/Repos) → Supabase
```

### Folder Structure

- `lib/core`: Shared infrastructure, themes, and application-wide configurations.
- `lib/features`: Distinct business modules (e.g., `auth`, `expense`, `dashboard`).
  - `presentation`: UI components and Riverpod ViewModels.
  - `domain`: Business logic entities and repository abstractions.
  - `data`: Data transfer objects (Models) and repository implementations.
- `lib/shared`: Cross-feature UI components.

---

## 🛠️ Getting Started

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   ```

2. **Environment Setup**:
   - Copy `.env.example` to `.env`.
   - Fill in your `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

---

## Branching Strategy

- main → production
- dev → development
- feature/* → feature branches

---

## Roadmap

- [x] Authentication (OTP)
- [x] Expense create
- [x] Dashboard summary and charts
- [x] Pregnancy mode and trimester tracking
- [ ] Expense edit/delete
- [ ] Category management
- [ ] AI insights
- [ ] Web deployment
