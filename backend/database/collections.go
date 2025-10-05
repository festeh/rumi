package database

import (
	"github.com/pocketbase/pocketbase/core"
)

func EnsureNotesCollection(app core.App) error {
	collection, err := app.FindCollectionByNameOrId("notes")

	// If collection doesn't exist, create it
	if err != nil {
		collection = core.NewBaseCollection("notes")
	}

	// Ensure all required fields exist
	titleField := &core.TextField{
		Name:     "title",
		Required: true,
		Max:      255,
	}

	contentField := &core.TextField{
		Name:     "content",
		Required: true,
		Max:      100000,
	}

	dateField := &core.DateField{
		Name:     "date",
		Required: true,
	}

	createdField := &core.AutodateField{
		Name:     "created",
		OnCreate: true,
	}

	updatedField := &core.AutodateField{
		Name:     "updated",
		OnCreate: true,
		OnUpdate: true,
	}

	// Add fields if they don't exist
	if collection.Fields.GetByName("title") == nil {
		collection.Fields.Add(titleField)
	}
	if collection.Fields.GetByName("content") == nil {
		collection.Fields.Add(contentField)
	}
	if collection.Fields.GetByName("date") == nil {
		collection.Fields.Add(dateField)
	}
	if collection.Fields.GetByName("created") == nil {
		collection.Fields.Add(createdField)
	}
	if collection.Fields.GetByName("updated") == nil {
		collection.Fields.Add(updatedField)
	}

	if err := app.Save(collection); err != nil {
		return err
	}

	return nil
}