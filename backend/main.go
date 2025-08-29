package main

import (
	"log"
	"net/http"

	"rumi-backend/database"
	"rumi-backend/handlers"

	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

func main() {
	// Initialize database
	database.InitDB()
	defer database.CloseDB()

	r := mux.NewRouter()

	// API routes
	api := r.PathPrefix("/api").Subrouter()
	
	// Health check
	api.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	}).Methods("GET")

	// Notes routes
	api.HandleFunc("/notes", handlers.GetNotes).Methods("GET")
	api.HandleFunc("/notes", handlers.CreateNote).Methods("POST")
	api.HandleFunc("/notes/{id}", handlers.GetNote).Methods("GET")
	api.HandleFunc("/notes/{id}", handlers.UpdateNote).Methods("PUT")
	api.HandleFunc("/notes/{id}", handlers.DeleteNote).Methods("DELETE")
	api.HandleFunc("/notes/date/{date}", handlers.GetNotesByDate).Methods("GET")
	api.HandleFunc("/search", handlers.SearchNotes).Methods("GET")

	// Setup CORS
	c := cors.New(cors.Options{
		AllowedOrigins: []string{"*"},
		AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders: []string{"*"},
	})

	handler := c.Handler(r)

	log.Println("Server starting on :8080")
	log.Fatal(http.ListenAndServe(":8080", handler))
}