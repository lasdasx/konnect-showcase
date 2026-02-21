package repository

//////fix websockets communication
import (
	"backend/models"
	"context"
)

var MessageRepo = &messageRepo{}

type messageRepo struct{}

func (r *messageRepo) SetRead(messageID int) error {
	_, err := DB.Exec(context.Background(), `UPDATE messages SET is_read = true WHERE id = $1`, messageID)
	return err
}

func (r *messageRepo) Create(message *models.Message) error {

	err := DB.QueryRow(
		context.Background(),
		`INSERT INTO messages (chat_id, sender_id,receiver_id, content)
		 VALUES ($1, $2, $3, $4)
		 RETURNING id,   time`,
		message.ChatID,
		message.SenderID,
		message.ReceiverID,
		message.Content,
	).Scan(
		&message.ID,

		&message.Time,
	)

	if err != nil {
		return err
	}

	return nil
}

// /add from when to start loading and how many to fetch so that not everything is fetched
func (r *messageRepo) GetByChatID(chatID int) ([]models.Message, error) {
	var messages []models.Message

	query := `SELECT id, chat_id, sender_id, content, time, is_read
			  FROM messages
			  WHERE chat_id = $1 ORDER BY time DESC`

	rows, err := DB.Query(context.Background(), query, chatID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var message models.Message
		if err := rows.Scan(&message.ID, &message.ChatID, &message.SenderID, &message.Content, &message.Time, &message.IsRead); err != nil {
			return nil, err
		}
		messages = append(messages, message)
	}

	return messages, nil
}

func (r *messageRepo) GetLastMessage(chatID int) (models.Message, error) {
	var message models.Message
	query := `SELECT *
			  FROM messages
			  WHERE chat_id = $1
			  ORDER BY time DESC
			  LIMIT 1`

	err := DB.QueryRow(context.Background(), query, chatID).Scan(
		&message.ID,
		&message.ChatID,
		&message.SenderID,
		&message.ReceiverID,
		&message.Content,
		&message.Time,
		&message.IsRead,
	)

	if err != nil {
		return models.Message{}, err
	}

	return message, nil
}
