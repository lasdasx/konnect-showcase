package repository

import (
	"backend/models"
	"context"
)

var OpinionRepo = &opinionRepo{}

type opinionRepo struct{}

func (r *opinionRepo) Create(opinion models.Opinion) (models.OpinionSummary, error) {
	opSum := models.OpinionSummary{}

	err := DB.QueryRow(
		context.Background(),
		`
		WITH inserted_opinion AS (
			INSERT INTO opinions (sender_id, receiver_id, opinion)
			VALUES ($1, $2, $3)
			RETURNING id, sender_id, opinion, created_at
		)
		SELECT 
			i.id,
			i.sender_id,
			i.opinion,
			i.created_at,
			u.profile_url,
			u.name
		FROM inserted_opinion i
		JOIN users u ON u.id = i.sender_id
		`,
		opinion.SenderID,
		opinion.ReceiverID,
		opinion.Opinion,
	).Scan(
		&opSum.ID,
		&opSum.SenderID,
		&opSum.Opinion,
		&opSum.CreatedAt,
		&opSum.ProfileURL,
		&opSum.Name,
	)

	if err != nil {
		return models.OpinionSummary{}, err
	}

	return opSum, nil
}

func (r *opinionRepo) GetReceivedByUserID(id int) ([]models.Opinion, error) {
	var opinions []models.Opinion

	query := `
        SELECT o.id, o.sender_id, o.receiver_id, o.opinion
        FROM opinions o
        JOIN users u ON o.sender_id = u.id
        WHERE o.receiver_id = $1 
          AND u.deleted_at IS NULL 
        ORDER BY o.created_at DESC`

	rows, err := DB.Query(context.Background(), query, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var opinion models.Opinion
		if err := rows.Scan(&opinion.ID, &opinion.SenderID, &opinion.ReceiverID, &opinion.Opinion); err != nil {
			return nil, err
		}
		opinions = append(opinions, opinion)
	}

	return opinions, nil
}

func (r *opinionRepo) AlreadyExisting(senderID int, receiverID int) (bool, error) {
	var exists bool
	err := DB.QueryRow(
		context.Background(),
		`SELECT EXISTS (
         SELECT 1 FROM opinions WHERE sender_id = $1 AND receiver_id = $2
     )`,
		senderID, receiverID,
	).Scan(&exists)

	if err != nil {
		return false, err
	}
	return exists, nil

}

func (r *opinionRepo) GetByUserIDs(user_id int, other_user_id int) ([]models.Opinion, error) {
	var opinion1, opinion2 models.Opinion
	err := DB.QueryRow(
		context.Background(),
		`SELECT * FROM opinions WHERE sender_id = $1 AND receiver_id = $2`,
		user_id, other_user_id,
	).Scan(&opinion1.ID, &opinion1.SenderID, &opinion1.ReceiverID, &opinion1.Opinion, &opinion1.CreatedAt)

	err = DB.QueryRow(
		context.Background(),
		`SELECT * FROM opinions WHERE sender_id = $1 AND receiver_id = $2`,
		other_user_id, user_id,
	).Scan(&opinion2.ID, &opinion2.SenderID, &opinion2.ReceiverID, &opinion2.Opinion, &opinion2.CreatedAt)

	if err != nil {
		return nil, err
	}
	return []models.Opinion{opinion1, opinion2}, nil

}
