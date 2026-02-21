package repository

import (
	"backend/models"
	"context"
)

var ChatRepo = &chatRepo{}

type chatRepo struct{}

func (r *chatRepo) Create(chat models.Chat) (int, error) {
	var chatID int

	err := DB.QueryRow(
		context.Background(),
		`INSERT INTO chats (id, user1_id, user2_id)
		 VALUES ($1, $2, $3)
		 RETURNING id`,
		chat.ID,
		chat.UserId1,
		chat.UserId2,
	).Scan(&chatID)

	if err != nil {
		return 0, err
	}

	return chatID, nil
}

func (r *chatRepo) GetByID(id int) (bool, error) {
	var exists bool

	err := DB.QueryRow(
		context.Background(),
		`SELECT EXISTS (
			SELECT 1 FROM chats WHERE id = $1
		)`,
		id,
	).Scan(&exists)

	if err != nil {
		return false, err
	}

	return exists, nil
}

func (r *chatRepo) GetByUserID(id int) ([]models.Chat, error) {
	var chats []models.Chat

	query := `SELECT c.id, c.user1_id, c.user2_id
FROM chats c
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
		var chat models.Chat
		if err := rows.Scan(&chat.ID, &chat.UserId1, &chat.UserId2); err != nil {
			return nil, err
		}
		chats = append(chats, chat)
	}

	return chats, nil
}
