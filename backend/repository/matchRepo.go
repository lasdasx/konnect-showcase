package repository

import (
	"backend/models"
	"context"
)

var MatchRepo = &matchRepo{}

type matchRepo struct{}

func (r *matchRepo) Create(match models.Match) (int, error) {
	var id int
	err := DB.QueryRow(
		context.Background(),
		`INSERT INTO matches (user1_id, user2_id) 
         VALUES ($1, $2) 
         RETURNING id`,
		match.UserId1,
		match.UserId2,
	).Scan(&id)
	if err != nil {
		return 0, err
	}
	return id, nil
}

func (r *matchRepo) GetByUserID(id int) ([]models.Match, error) {
	var matches []models.Match

	query :=

		`SELECT c.id, c.user1_id, c.user2_id
FROM matches c
-- Join for user1
LEFT JOIN users u1 ON c.user1_id = u1.id
-- Join for user2
LEFT JOIN users u2 ON c.user2_id = u2.id
WHERE (c.user1_id = $1 OR c.user2_id = $1)
  -- If I am User1, check if User2 is active. If I am User2, check if User1 is active.
  AND (
    (c.user1_id = $1 AND u2.deleted_at IS NULL) OR 
    (c.user2_id = $1 AND u1.deleted_at IS NULL)
  );`

	

	rows, err := DB.Query(context.Background(), query, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var match models.Match
		if err := rows.Scan(&match.ID, &match.UserId1, &match.UserId2); err != nil {
			return nil, err
		}
		matches = append(matches, match)
	}

	return matches, nil
}

func (r *matchRepo) Delete(id int) error {

	_, err := DB.Exec(
		context.Background(),
		`DELETE FROM matches WHERE id = $1`,
		id,
	)
	return err

}
