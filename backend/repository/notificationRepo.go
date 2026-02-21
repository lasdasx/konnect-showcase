package repository

import "context"

var NotificationRepo = &notificationRepo{}

type notificationRepo struct {
}

func (r *notificationRepo) AddDeviceToken(userId int, deviceToken string, deviceID string) error {
	query := `
        INSERT INTO device_tokens (user_id, device_id, device_token)
        VALUES ($1, $2, $3)
        ON CONFLICT (user_id, device_id)
        DO UPDATE SET device_token = EXCLUDED.device_token
    `
	_, err := DB.Exec(context.Background(), query, userId, deviceID, deviceToken)
	return err
}

func (r *notificationRepo) GetDeviceTokens(userId int) ([]string, error) {
	var deviceTokens []string
	rows, err := DB.Query(context.Background(), "SELECT device_token FROM device_tokens WHERE user_id = $1", userId)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var deviceToken string
		err := rows.Scan(&deviceToken)
		if err != nil {
			return nil, err
		}
		deviceTokens = append(deviceTokens, deviceToken)
	}
	return deviceTokens, err
}
