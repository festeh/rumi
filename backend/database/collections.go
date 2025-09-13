package database

import (
	"github.com/pocketbase/pocketbase/core"
)

func EnsureNotesCollection(app core.App) error {
	_, err := app.FindCollectionByNameOrId("notes")
	if err == nil {
		return nil
	}

	collection := core.NewBaseCollection("notes")

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

	collection.Fields.Add(titleField)
	collection.Fields.Add(contentField)
	collection.Fields.Add(dateField)

	if err := app.Save(collection); err != nil {
		return err
	}

	return nil
}