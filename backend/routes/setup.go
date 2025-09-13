package routes

import (
	"rumi-backend/handlers"

	"github.com/pocketbase/pocketbase/core"
)

func SetCORSHeaders(re *core.RequestEvent) {
	re.Response.Header().Set("Access-Control-Allow-Origin", "*")
	re.Response.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	re.Response.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
}

func Setup(se *core.ServeEvent, app core.App) {
	se.Router.GET("/api/notes", func(re *core.RequestEvent) error {
		SetCORSHeaders(re)
		return handlers.GetNotes(re, app)
	})

	se.Router.POST("/api/notes", func(re *core.RequestEvent) error {
		SetCORSHeaders(re)
		return handlers.CreateNote(re, app)
	})

	se.Router.GET("/api/notes/{id}", func(re *core.RequestEvent) error {
		SetCORSHeaders(re)
		return handlers.GetNote(re, app)
	})

	se.Router.PUT("/api/notes/{id}", func(re *core.RequestEvent) error {
		SetCORSHeaders(re)
		return handlers.UpdateNote(re, app)
	})

	se.Router.DELETE("/api/notes/{id}", func(re *core.RequestEvent) error {
		SetCORSHeaders(re)
		return handlers.DeleteNote(re, app)
	})

	se.Router.GET("/api/notes/date/{date}", func(re *core.RequestEvent) error {
		SetCORSHeaders(re)
		return handlers.GetNotesByDate(re, app)
	})

	se.Router.GET("/api/search", func(re *core.RequestEvent) error {
		SetCORSHeaders(re)
		return handlers.SearchNotes(re, app)
	})

	se.Router.OPTIONS("/*", func(re *core.RequestEvent) error {
		SetCORSHeaders(re)
		return re.NoContent(200)
	})
}