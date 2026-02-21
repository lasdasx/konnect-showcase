package repository

import (
	"backend/models"
	"context"
)

var SkipRepo = &skipRepo{}

type skipRepo struct{}

func (r *skipRepo) Create(skip models.Skip) error {
	_, err := DB.Exec(
		context.Background(),
		`INSERT INTO skips 
        (	skipper, skipped) 
        VALUES ($1, $2)`,
		skip.SkipperID,
		skip.SkippedID,
	)
	return err
}

