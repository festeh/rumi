# Rumi - Daily Notes App

A beautiful daily notes application built with Flutter (frontend) and Go (backend).

## Features

- 📝 Create and edit daily notes
- 📅 Browse notes by date
- 🔍 Search across all your notes
- 🎨 Clean, minimalist interface
- 📱 Cross-platform (Android, iOS, Web, Desktop)
- 💾 SQLite database for data persistence

## Architecture

- **Frontend**: Flutter with Provider for state management
- **Backend**: Go with Gorilla Mux for REST API
- **Database**: SQLite for local data storage

## Getting Started

### Prerequisites

- Flutter SDK (3.32.8+)
- Go (1.24+)

### Running the Application

1. **Start the Backend**:
   ```bash
   cd backend
   go run main.go
   ```
   The server will start on `http://localhost:8080`

2. **Start the Frontend**:
   ```bash
   cd frontend
   flutter run
   ```

### API Endpoints

- `GET /api/health` - Health check
- `GET /api/notes` - Get all notes
- `POST /api/notes` - Create a new note
- `GET /api/notes/{id}` - Get a specific note
- `PUT /api/notes/{id}` - Update a note
- `DELETE /api/notes/{id}` - Delete a note
- `GET /api/notes/date/{date}` - Get notes for a specific date (YYYY-MM-DD)
- `GET /api/search?q={query}` - Search notes

## Project Structure

```
rumi/
├── README.md
├── backend/                 # Go REST API
│   ├── main.go
│   ├── go.mod
│   ├── models/
│   │   └── note.go
│   ├── handlers/
│   │   └── notes.go
│   └── database/
│       └── sqlite.go
└── frontend/               # Flutter app
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── models/
        │   └── note.dart
        ├── services/
        │   ├── api_service.dart
        │   └── notes_provider.dart
        ├── screens/
        │   ├── home_screen.dart
        │   └── note_editor_screen.dart
        └── widgets/
            ├── note_card.dart
            └── date_picker_widget.dart
```

## License

MIT License