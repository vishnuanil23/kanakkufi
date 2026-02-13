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

Presentation → Domain → Data → Supabase

Key modules:
- Auth and profile management
- Expenses with currency conversion (AED to INR)
- Dashboard with dynamic charts and pregnancy mode

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
