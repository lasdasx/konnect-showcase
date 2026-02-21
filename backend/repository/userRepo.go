package repository

import (
	"backend/models"
	"context"
	"fmt"
	"strings"
	"time"
)

var UserRepo = &userRepo{}

type userRepo struct{}

func (r *userRepo) UpdateEmailVerificationPasscode(email string, passcode string) error {
	query := `UPDATE users SET email_verification_passcode = $1, email_passcode_created_at = now() WHERE email = $2`
	_, err := DB.Exec(context.Background(), query, passcode, email)
	return err
}

func (r *userRepo) UpdateLastLogin(id int) error {
	_, err := DB.Exec(context.Background(), "UPDATE users SET last_login = now(), deleted_at = null WHERE id = $1", id)
	return err
}

func (r *userRepo) DeleteRefreshTokens(id int) error {
	_, err := DB.Exec(context.Background(), "DELETE FROM refresh_tokens WHERE user_id = $1", id)
	return err
}
func (r *userRepo) DeleteRefreshToken(id int, token string) error {
	_, err := DB.Exec(context.Background(), "DELETE FROM refresh_tokens WHERE user_id = $1 AND token = $2", id, token)
	return err
}

func (r *userRepo) MarkUserDeleted(id int) error {
	_, err := DB.Exec(context.Background(), "UPDATE users SET deleted_at = now() WHERE id = $1", id)
	return err
}

func (r *userRepo) GetRefreshToken(token string) (*models.RefreshToken, error) {
	var rt models.RefreshToken
	err := DB.QueryRow(context.Background(), "SELECT token, user_id, expires_at FROM refresh_tokens WHERE token = $1", token).
		Scan(&rt.Token, &rt.UserId, &rt.ExpiresAt)
	if err != nil {
		return nil, err
	}
	return &rt, nil
}

func (r *userRepo) UpdateRefreshToken(token string, newToken string, expiresAt time.Time) error {
	_, err := DB.Exec(context.Background(), "UPDATE refresh_tokens SET token = $1, expires_at = $2 WHERE token = $3", newToken, expiresAt, token)
	return err
}

func (r *userRepo) InsertRefreshToken(token string, userId int, expiresAt time.Time) error {
	_, err := DB.Exec(context.Background(), "INSERT INTO refresh_tokens (token, user_id, expires_at) VALUES ($1, $2, $3)", token, userId, expiresAt)
	return err
}

func (r *userRepo) Create(user *models.User) error {
	query := `
    INSERT INTO users 
    (name, gender, birthday, profile_url, images_url, bio, country, email, password_hash, email_verified, email_verification_passcode, email_passcode_created_at)
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
    RETURNING id
    `
	err := DB.QueryRow(
		context.Background(),
		query,
		user.Name,
		user.Gender,
		user.Birthday,
		user.ProfileURL,
		user.ImagesURL,
		user.Bio,
		user.Country,
		user.Email,
		user.PasswordHash, user.EmailVerified, user.EmailVerificationPasscode, user.EmailPasscodeCreatedAt,
	).Scan(&user.ID) // update struct ID
	return err
}

func (r *userRepo) GetByID(id int) (models.User, error) {
	var user models.User

	query := `SELECT id, name, gender, birthday, profile_url, images_url, bio, country,email, onboarded
              FROM users
              WHERE id = $1`

	err := DB.QueryRow(context.Background(), query, id).Scan(
		&user.ID,
		&user.Name,
		&user.Gender,
		&user.Birthday,
		&user.ProfileURL,
		&user.ImagesURL,
		&user.Bio,
		&user.Country,
		&user.Email,
		&user.Onboarded,
	)

	if err != nil {
		return models.User{}, err
	}

	return user, nil
}

func (r *userRepo) GetSummaryByID(id int) (models.UserSummary, error) {
	var user models.UserSummary

	query := `SELECT  id, name, profile_url
              FROM users
              WHERE id = $1`

	err := DB.QueryRow(context.Background(), query, id).Scan(
		&user.ID,

		&user.Name,

		&user.ProfileURL,
	)

	if err != nil {
		return models.UserSummary{}, err
	}

	return user, nil
}

func (r *userRepo) UpdatePartial(id int, updates map[string]interface{}) error {
	fields := []string{}
	args := []interface{}{}
	argPos := 1

	for key, value := range updates {
		switch key {
		case "name", "gender", "birthday", "bio", "country", "onboarded":
			fields = append(fields, fmt.Sprintf("%s = $%d", key, argPos))
			args = append(args, value)
			argPos++
		default:
			// Ignore unknown fields
		}
	}

	if len(fields) == 0 {
		return nil // nothing to update
	}

	// Add the ID as the last argument
	args = append(args, id)
	query := fmt.Sprintf("UPDATE users SET %s WHERE id = $%d", strings.Join(fields, ", "), argPos)

	fmt.Println("Executing query:", query)
	fmt.Println("With args:", args)

	// Make sure to spread the slice
	_, err := DB.Exec(context.Background(), query, args...)
	if err != nil {
		fmt.Println("UpdatePartial error:", err)
	}
	return err
}

func (r *userRepo) DeleteImage(id int, keyIndex int) (string, error) {
	// Prepare the SQL query to remove the image from the array
	sqlIndex := keyIndex + 1 //sql einai 1 indexed
	query := `
        WITH removed AS (
    SELECT images_url[$2] AS deleted_image
    FROM users
    WHERE id = $1
		)
	UPDATE users
	SET images_url = images_url[1:$2-1] || images_url[$2+1:array_length(images_url, 1)]
	WHERE id = $1
	RETURNING (SELECT deleted_image FROM removed);
    `
	var oldLen int
	err := DB.QueryRow(context.Background(), `
    SELECT coalesce(array_length(images_url,1),0) 
    FROM users WHERE id=$1
`, id).Scan(&oldLen)
	if err != nil {
		return "", err
	}
	var imageUrl string //actually s3 key
	err = DB.QueryRow(context.Background(), query, id, sqlIndex).Scan(&imageUrl)
	if err != nil {
		return "", err
	}

	var newLen int
	err = DB.QueryRow(context.Background(), `
    SELECT coalesce(array_length(images_url,1),0) 
    FROM users WHERE id=$1
`, id).Scan(&newLen)

	if err != nil {
		return "", err
	}

	if oldLen == newLen {
		return "", fmt.Errorf("image URL not found in user's images")
	}

	return imageUrl, nil

}

func (r *userRepo) AddImage(id int, imageURL string) error {
	// Prepare the SQL query to add the image to the array
	query := `
		UPDATE users
		SET images_url = array_append(images_url, $1)
		WHERE id = $2 AND coalesce(array_length(images_url, 1), 0) < 6
	`

	// Execute the query
	res, err := DB.Exec(context.Background(), query, imageURL, id)
	if err != nil {
		return err
	}

	// Check how many rows were affected
	rowsAffected := res.RowsAffected()

	if rowsAffected == 0 {
		return fmt.Errorf("cannot add image: maximum of 6 images reached")
	}

	return nil

}

func (r *userRepo) ChangeProfileImage(id int, imageURL string) error {
	// Prepare the SQL query to add the image to the array
	query := `
		UPDATE users
		SET profile_url = $1
		WHERE id = $2
	`

	// Execute the query
	_, err := DB.Exec(context.Background(), query, imageURL, id)
	if err != nil {
		return err
	}

	return nil
}

func (r *userRepo) GetByEmail(email string) (*models.User, error) {
	user := &models.User{}
	err := DB.QueryRow(
		context.Background(),
		`SELECT id, name, gender, birthday, profile_url, images_url, bio, country, email, password_hash , onboarded, email_verified, COALESCE(email_verification_passcode, ''), 
        COALESCE(email_passcode_created_at, '0001-01-01 00:00:00+00')
         FROM users WHERE email=$1`,
		email,
	).Scan(
		&user.ID,
		&user.Name,
		&user.Gender,
		&user.Birthday,
		&user.ProfileURL,
		&user.ImagesURL,
		&user.Bio,
		&user.Country,
		&user.Email,
		&user.PasswordHash,
		&user.Onboarded,
		&user.EmailVerified,
		&user.EmailVerificationPasscode,
		&user.EmailPasscodeCreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (r *userRepo) GetGalleryLength(id int) (int, error) {
	var length int
	// Using cardinality() is more idiomatic for 1D arrays
	query := `SELECT COALESCE(cardinality(images_url), 0) FROM users WHERE id=$1`

	// Use QueryRowContext instead of QueryRow to support cancellation
	err := DB.QueryRow(context.Background(), query, id).Scan(&length)
	if err != nil {
		return 0, err
	}
	return length, nil
}

func (r *userRepo) VerifyEmail(id int) error {
	_, err := DB.Exec(context.Background(), "UPDATE users SET email_verified = true WHERE id = $1", id)
	return err
}
