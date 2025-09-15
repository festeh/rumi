package main

import (
	"log"
	"rumi-backend/database"
	"rumi-backend/routes"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/core"
)

func main() {
	app := pocketbase.New()

	app.OnServe().BindFunc(func(se *core.ServeEvent) error {
		log.Printf("Setting up PocketBase server on %s", se.Server.Addr)

		if err := database.EnsureNotesCollection(se.App); err != nil {
			log.Fatalf("Failed to ensure notes collection: %v", err)
		}
		log.Printf("Notes collection ensured successfully")

		routes.Setup(se, app)
		log.Printf("Custom routes setup completed")

		log.Printf("Server started on %s", se.Server.Addr)
		return se.Next()
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}