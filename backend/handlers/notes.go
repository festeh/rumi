package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"rumi-backend/database"
	"rumi-backend/models"

	"github.com/gorilla/mux"
)

func GetNotes(w http.ResponseWriter, r *http.Request) {
	rows, err := database.DB.Query("SELECT id, title, content, date, created_at, updated_at FROM notes ORDER BY date DESC")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var notes []models.Note
	for rows.Next() {
		var note models.Note
		var dateTime time.Time
		err := rows.Scan(&note.ID, &note.Title, &note.Content, &dateTime, &note.CreatedAt, &note.UpdatedAt)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		note.Date = models.CustomDate{dateTime}
		notes = append(notes, note)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(notes)
}

func GetNote(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid note ID", http.StatusBadRequest)
		return
	}

	var note models.Note
	var dateTime time.Time
	err = database.DB.QueryRow("SELECT id, title, content, date, created_at, updated_at FROM notes WHERE id = ?", id).Scan(
		&note.ID, &note.Title, &note.Content, &dateTime, &note.CreatedAt, &note.UpdatedAt)
	note.Date = models.CustomDate{dateTime}
	
	if err == sql.ErrNoRows {
		http.Error(w, "Note not found", http.StatusNotFound)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(note)
}

func CreateNote(w http.ResponseWriter, r *http.Request) {
	var note models.Note
	if err := json.NewDecoder(r.Body).Decode(&note); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	now := time.Now()
	note.CreatedAt = now
	note.UpdatedAt = now

	if note.Date.IsZero() {
		note.Date = models.CustomDate{time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())}
	}

	result, err := database.DB.Exec(
		"INSERT INTO notes (title, content, date, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
		note.Title, note.Content, note.Date.Time, note.CreatedAt, note.UpdatedAt)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	id, err := result.LastInsertId()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	note.ID = int(id)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(note)
}

func UpdateNote(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid note ID", http.StatusBadRequest)
		return
	}

	var note models.Note
	if err := json.NewDecoder(r.Body).Decode(&note); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	note.ID = id
	note.UpdatedAt = time.Now()

	_, err = database.DB.Exec(
		"UPDATE notes SET title = ?, content = ?, date = ?, updated_at = ? WHERE id = ?",
		note.Title, note.Content, note.Date.Time, note.UpdatedAt, note.ID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(note)
}

func DeleteNote(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid note ID", http.StatusBadRequest)
		return
	}

	_, err = database.DB.Exec("DELETE FROM notes WHERE id = ?", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func GetNotesByDate(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	dateStr := vars["date"]
	
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		http.Error(w, "Invalid date format. Use YYYY-MM-DD", http.StatusBadRequest)
		return
	}

	rows, err := database.DB.Query("SELECT id, title, content, date, created_at, updated_at FROM notes WHERE date = ? ORDER BY created_at DESC", date)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var notes []models.Note
	for rows.Next() {
		var note models.Note
		var dateTime time.Time
		err := rows.Scan(&note.ID, &note.Title, &note.Content, &dateTime, &note.CreatedAt, &note.UpdatedAt)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		note.Date = models.CustomDate{dateTime}
		notes = append(notes, note)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(notes)
}

func SearchNotes(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	if query == "" {
		http.Error(w, "Search query is required", http.StatusBadRequest)
		return
	}

	searchTerm := "%" + query + "%"
	rows, err := database.DB.Query(
		"SELECT id, title, content, date, created_at, updated_at FROM notes WHERE title LIKE ? OR content LIKE ? ORDER BY date DESC",
		searchTerm, searchTerm)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var notes []models.Note
	for rows.Next() {
		var note models.Note
		var dateTime time.Time
		err := rows.Scan(&note.ID, &note.Title, &note.Content, &dateTime, &note.CreatedAt, &note.UpdatedAt)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		note.Date = models.CustomDate{dateTime}
		notes = append(notes, note)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(notes)
}