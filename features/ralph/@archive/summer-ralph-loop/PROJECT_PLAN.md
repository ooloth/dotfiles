# Project Plan: BookShelf - A Social Book Tracking Application

## 1. Project Overview

BookShelf is a production-grade, full-stack web application that allows users to track books they have read or are currently reading. Users can organize books into multiple custom lists, rate and rank them, and write personal notes. The application includes a social layer with a friends system, allowing connected users to view each other's lists. A recommendation engine suggests books based on user reading history and preferences.

## 2. Architecture

### Tech Stack

| Layer        | Technology                          |
|--------------|-------------------------------------|
| Frontend     | React (TypeScript), Vite            |
| Backend API  | Django REST Framework (Python 3.12+)|
| Database     | PostgreSQL                          |
| Cache        | Redis (via Django cache framework)  |
| Auth         | Django Auth + JWT (SimpleJWT)       |
| Book Data    | Google Books API                    |
| API Docs     | drf-spectacular (OpenAPI/Swagger)   |
| Pkg Manager  | uv, pyproject.toml                  |
| Frontend Pkg | npm                                 |
| CI/CD        | GitHub Actions                      |

### High-Level Architecture

```
[React SPA] <--REST API--> [Django REST Framework] <--ORM--> [PostgreSQL]
                                    |                            |
                            [Google Books API]              [Redis Cache]
```

- **Frontend:** React single-page application served separately during development. In production, static build files served via Django or a reverse proxy (Nginx).
- **Backend:** Django REST Framework providing a JSON API. Handles authentication, authorization, business logic, and database operations.
- **Database:** PostgreSQL for all persistent data — users, books, lists, ratings, friendships, notifications.
- **Cache:** Redis via Django's cache framework. Used for recommendation result caching (TTL-based) and rate limiting.
- **External API:** Google Books API for searching and retrieving book metadata (title, author, cover, description, genres/categories).

## 3. Data Models

### User
- Extends Django's built-in User model via a Profile model.
- Fields: bio, avatar_url, favorite_genres, date_joined.
- Profile page displays reading stats (books read, average rating, genre breakdown, etc.).

### Book
- Cached metadata from Google Books API.
- Fields: google_books_id (unique, indexed), title, authors (JSON), description, cover_image_url, categories (JSON), published_date, isbn, page_count.
- Books are stored locally once any user adds them, avoiding repeated API calls.

### BookList
- A user can have multiple lists (e.g., "2024 Reads", "Sci-Fi Favorites", "All Time Greats").
- Fields: owner (FK to User), name, description, created_at, updated_at.

### BookListEntry
- An entry in a list, linking a book to a list with ordering.
- Fields: book_list (FK), book (FK), position (integer for drag-and-drop ordering, indexed), status (enum: "want_to_read", "currently_reading", "finished"), rating (decimal, 0.5-5.0 in 0.5 increments, nullable), personal_note (text, nullable), date_added, date_finished (nullable).
- Unique constraint on (book_list, book) — no duplicate books in the same list.
- **Rating constraint:** Enforced at both the database level (CHECK constraint: value is NULL or between 0.5 and 5.0 in 0.5 increments) and the serializer level for clear validation error messages.

### Friendship
- Fields: requester (FK to User), addressee (FK to User), status (enum: "pending", "accepted", "declined"), created_at, updated_at.
- Unique constraint on (requester, addressee).
- Index on `status` for filtered queries.
- When accepted, both users can view each other's lists.

### Notification
- Fields: recipient (FK to User), notification_type (enum: "friend_request", "friend_accepted", "recommendation"), message (text), is_read (boolean), content_type (FK to ContentType), object_id (PositiveIntegerField), content_object (GenericForeignKey), created_at.
- Uses Django's `ContentType` framework (`GenericForeignKey` with `content_type` and `object_id` fields) for linking to related objects (Friendship, Book, etc.). This is extensible for future notification types.
- Composite index on `(recipient, is_read)` for unread count queries.

### Database Indexing Strategy

Beyond Django's default indexes on primary keys and foreign keys, the following indexes must be explicitly created:

| Model          | Field(s)              | Reason                          |
|----------------|-----------------------|---------------------------------|
| Book           | google_books_id       | Unique lookups on external ID   |
| BookListEntry  | position              | Ordering queries within lists   |
| Friendship     | status                | Filtered queries (pending, etc.)|
| Notification   | (recipient, is_read)  | Unread count and list queries   |

## 4. API Endpoints

All endpoints are prefixed with `/api/v1/`.

### Pagination

All list endpoints use **PageNumberPagination** with a default page size of 20. Response format:

```json
{
  "count": 100,
  "next": "https://host/api/v1/resource/?page=3",
  "previous": "https://host/api/v1/resource/?page=1",
  "results": [...]
}
```

### Standardized Error Response Format

All error responses follow a consistent shape:

```json
{
  "error": "VALIDATION_ERROR",
  "message": "Human-readable description of the error.",
  "details": {
    "field_name": ["Specific field error message."]
  }
}
```

Error codes include: `VALIDATION_ERROR`, `NOT_FOUND`, `PERMISSION_DENIED`, `AUTHENTICATION_FAILED`, `RATE_LIMITED`, `EXTERNAL_SERVICE_ERROR`.

### Authentication
| Method | Endpoint                      | Description            |
|--------|-------------------------------|------------------------|
| POST   | /api/v1/auth/register/        | Create a new account   |
| POST   | /api/v1/auth/login/           | Obtain JWT token pair  |
| POST   | /api/v1/auth/refresh/         | Refresh JWT token      |
| POST   | /api/v1/auth/logout/          | Blacklist refresh token|

### User Profiles
| Method | Endpoint                            | Description                  |
|--------|-------------------------------------|------------------------------|
| GET    | /api/v1/users/me/                   | Get current user profile     |
| PUT    | /api/v1/users/me/                   | Update current user profile  |
| GET    | /api/v1/users/{id}/                 | Get a user's public profile  |
| GET    | /api/v1/users/{id}/stats/           | Get a user's reading stats   |
| GET    | /api/v1/users/search/?q=            | Search users by username     |

### Book Lists
| Method | Endpoint                                     | Description                    |
|--------|----------------------------------------------|--------------------------------|
| GET    | /api/v1/lists/                               | Get current user's lists       |
| POST   | /api/v1/lists/                               | Create a new list              |
| GET    | /api/v1/lists/{id}/                          | Get list details with entries  |
| PUT    | /api/v1/lists/{id}/                          | Update list name/description   |
| DELETE | /api/v1/lists/{id}/                          | Delete a list                  |
| POST   | /api/v1/lists/{id}/entries/                  | Add a book to a list           |
| PUT    | /api/v1/lists/{id}/entries/{entry_id}/       | Update entry (rating, note, status, position) |
| DELETE | /api/v1/lists/{id}/entries/{entry_id}/       | Remove a book from a list      |
| PUT    | /api/v1/lists/{id}/reorder/                  | Batch update positions (drag-and-drop) |
| GET    | /api/v1/users/{id}/lists/                    | Get a friend's lists           |

### Books
| Method | Endpoint                       | Description                        |
|--------|--------------------------------|------------------------------------|
| GET    | /api/v1/books/search/?q=       | Search books via Google Books API  |
| GET    | /api/v1/books/{id}/            | Get locally cached book details    |

### Friends
| Method | Endpoint                                   | Description              |
|--------|-------------------------------------------|--------------------------|
| GET    | /api/v1/friends/                           | List current friends     |
| POST   | /api/v1/friends/request/                   | Send a friend request    |
| GET    | /api/v1/friends/requests/                  | List pending requests    |
| POST   | /api/v1/friends/requests/{id}/accept/      | Accept a request         |
| POST   | /api/v1/friends/requests/{id}/decline/     | Decline a request        |
| DELETE | /api/v1/friends/{id}/                      | Remove a friend          |

### Notifications
| Method | Endpoint                                 | Description                  |
|--------|------------------------------------------|------------------------------|
| GET    | /api/v1/notifications/                   | List user's notifications    |
| PATCH  | /api/v1/notifications/{id}/read/         | Mark notification as read    |
| POST   | /api/v1/notifications/read-all/          | Mark all as read             |

### Recommendations
| Method | Endpoint                       | Description                          |
|--------|--------------------------------|--------------------------------------|
| GET    | /api/v1/recommendations/       | Get personalized book recommendations|

## 5. Recommendation Engine

The recommendation engine uses a **content-based filtering approach enhanced with rating-weighted preferences:**

1. **User Preference Profile:** Build a preference vector from the user's rated books — extract categories, authors, and keywords from highly-rated books (3.5+ stars), weighted by rating.
2. **Candidate Generation:** Query Google Books API for books in the user's top categories and by frequently-read authors.
3. **Scoring:** Score candidate books based on:
   - Category overlap with user preferences (weighted by rating).
   - Author familiarity (bonus for authors the user has rated highly).
   - Popularity signals from Google Books (ratings count, average rating).
4. **Filtering:** Exclude books the user already has in any list.
5. **Ranking:** Return top N scored candidates.

This is more sophisticated than simple genre matching (it incorporates rating weights, author affinity, and multi-factor scoring) while remaining implementable without a complex ML pipeline.

### Caching Strategy

Recommendation results are cached using **Django's cache framework backed by Redis**. Each user's recommendations are cached with a key of `recommendations:{user_id}` and a TTL of **24 hours**. The cache is invalidated when:
- A user adds or removes a book from any list.
- A user updates a rating.

### Fallback Strategy

If the Google Books API is unavailable or rate-limited, the recommendation engine falls back to:
1. **Popular among friends:** Surface books that the user's friends have rated 4.0+ stars that the user has not yet added to any list.
2. **Locally popular:** Surface books from the local database that have the highest average rating across all users, filtered by the user's preferred categories.
3. If neither fallback produces results, display a message: "Recommendations are temporarily unavailable. Please try again later."

## 6. Security Considerations

- **Authentication:** JWT with short-lived access tokens (15 min) and longer refresh tokens (7 days). Refresh token rotation and blacklisting enabled.
- **Authorization:** Users can only modify their own lists/entries/profile. Friend list viewing requires accepted friendship. All endpoints enforce ownership checks.
- **Input Validation:** Django REST Framework serializers validate all input. Rating values constrained to 0.5-5.0 in 0.5 increments at both serializer and database level.
- **CSRF/XSS:** Django's built-in protections. React escapes output by default. API uses JWT (not cookies) for auth, mitigating CSRF.
- **Rate Limiting:** Django REST Framework throttling on authentication endpoints and Google Books API proxy to prevent abuse.
- **SQL Injection:** Mitigated by Django ORM — no raw SQL queries.
- **CORS:** Configured to allow only the frontend origin.
- **Environment Variables:** All secrets (Django secret key, database credentials, Google Books API key, Redis URL) stored in environment variables, never committed to source control.

## 7. Project Structure

```
bookshelf/
  pyproject.toml
  uv.lock
  .env.example
  .gitignore
  README.md                     # Local dev setup instructions
  CONTRIBUTING.md               # Development workflow and conventions
  manage.py
  bookshelf/                    # Django project settings
    __init__.py
    settings.py
    urls.py
    wsgi.py
    asgi.py
  apps/
    users/                      # Auth, profiles, registration
    books/                      # Book model, Google Books integration
    lists/                      # BookList, BookListEntry, ordering
    friends/                    # Friendship model, requests
    notifications/              # Notification model, signals
    recommendations/            # Recommendation engine
  frontend/
    package.json
    tsconfig.json
    vite.config.ts
    src/
      components/
      pages/
      api/
      hooks/
      types/
      App.tsx
      main.tsx
  .github/
    workflows/
      ci.yml                    # GitHub Actions: tests, linting on PRs
```

## 8. Development Workflow

- **Python environment:** Managed with `uv`. All dependencies in `pyproject.toml`.
- **Database migrations:** Django migrations, applied via `python manage.py migrate`.
- **Development servers:** Django dev server (port 8000) + Vite dev server (port 5173) with proxy.
- **Testing:** pytest (backend), React Testing Library (frontend). Each task is considered complete only when its corresponding tests pass.
- **Code quality:** ruff (linting/formatting for Python), ESLint + Prettier (frontend).
- **API documentation:** Auto-generated OpenAPI/Swagger docs via `drf-spectacular`, available at `/api/v1/docs/`.
- **Seed data:** Management command (`python manage.py seed_data`) to populate local databases with sample users, books, lists, and friendships for development.
- **CI/CD:** GitHub Actions workflow runs backend tests, ruff, frontend tests, and ESLint on all PRs. No merging without green CI.

---

## Revision Log

**Rev 2 — Captain Holt, responding to Amy Santiago's review:**

All 13 of Santiago's notes on the project plan have been addressed:

1. **Pagination (Note #1):** Added pagination section under API Endpoints specifying PageNumberPagination with page size 20 and response format.
2. **Notification.related_object_id (Note #2):** Replaced with Django's `GenericForeignKey` using `content_type` and `object_id` fields. Model definition updated.
3. **Database indexing (Note #3):** Added explicit indexing strategy table covering `Book.google_books_id`, `BookListEntry.position`, `Friendship.status`, and `Notification(recipient, is_read)`.
4. **Rating constraint (Note #4):** Specified enforcement at both database level (CHECK constraint) and serializer level.
5. **Error response format (Note #5):** Added standardized error response section with consistent shape and error code enumeration.
6. **API versioning (Note #6):** All endpoints now use `/api/v1/` prefix.
7. **Notification HTTP methods (Note #7):** Changed `PUT /notifications/{id}/read/` to `PATCH` and `PUT /notifications/read-all/` to `POST`.
8. **Recommendation fallback (Note #8):** Added fallback strategy section — popular among friends, then locally popular, then graceful error message.
9. **Recommendation cache specification (Note #9):** Specified Django cache framework backed by Redis, with key format, 24-hour TTL, and invalidation triggers. Redis added to tech stack.
10. **CI/CD (Note #10):** Added GitHub Actions to tech stack and project structure. Described CI policy in development workflow.
11. **API documentation (Note #11):** Added `drf-spectacular` to tech stack. Docs served at `/api/v1/docs/`.
12. **Seed data (Note #12):** Added management command (`seed_data`) to development workflow section.
13. **Developer setup docs (Note #13):** Added `README.md` and `CONTRIBUTING.md` to project structure.

---

## Final Review — Amy Santiago

Captain, I've reviewed Rev 2 of the project plan in full. Every one of my 13 original notes has been addressed correctly and thoroughly. Specific confirmations:

- **Data models** are well-defined with proper constraints, indexes, and the GenericForeignKey approach for notifications is exactly right.
- **API design** is consistent — versioned prefix, correct HTTP methods (PATCH for partial updates, POST for actions), pagination specified, and standardized error responses.
- **Recommendation engine** has a clear algorithm, sensible caching strategy with explicit invalidation triggers, and a solid three-tier fallback.
- **Security section** covers all the essentials — JWT rotation, ownership enforcement, rate limiting, CORS, no raw SQL.
- **Project structure** is clean and well-organized by domain. The addition of README.md and CONTRIBUTING.md ensures onboarding is smooth.

Two minor observations (non-blocking — not requesting changes, just flagging for awareness during implementation):

1. **CONTRIBUTING.md** is listed in the project structure but there's no task in TODO.md to write it. The team should know to create it alongside the README in Phase 1. This is a minor gap but shouldn't block anything — whoever picks up the README task can include it.
2. **WebSocket for notifications** is mentioned as a stretch goal in the TODO frontend tasks (Phase 6). The project plan doesn't mention WebSocket at all in the architecture section, which is fine since it's optional — just want to make sure no one scopes it as a requirement.

**Verdict: This plan is ready. Greenlight to begin work.** The tasks are granular, well-ordered, and any engineer on the team can pick them up independently. Excellent revision, Captain.

---

**Rev 3 — Captain Holt, final adjustments:**

Santiago's final review identified two observations:
1. **CONTRIBUTING.md gap:** While noted as non-blocking, this was unacceptable. Added explicit task to TODO.md Phase 1 to write CONTRIBUTING.md.
2. **WebSocket mention:** Santiago correctly noted that WebSocket for notifications appears in TODO.md Phase 6 as an optional stretch goal but isn't mentioned in the architecture section. This is intentional — WebSocket is not part of the core architecture and remains optional. No changes required to the plan.

**Status: All gaps addressed. This project plan is final and approved for team execution.**
