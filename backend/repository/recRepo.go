package repository

import (
	"backend/models"
	"backend/utils"
	"context"
	"log"
	"time"
)

var RecRepo = &recRepo{}

type recRepo struct{}

func (r *recRepo) HasLeftOpinion(userId int, profileId int) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM opinions WHERE sender_id = $1 AND receiver_id = $2)`

	var exists bool
	err := DB.QueryRow(context.Background(), query, userId, profileId).Scan(&exists)
	if err != nil {
		return false, err
	}
	return exists, nil
}

func (r *recRepo) GetExploreSummariesByIDs(ids []int) ([]models.UserExploreSummary, error) {

	query := `SELECT  id, name, profile_url, birthday, images_url, bio, country
              FROM users
              WHERE id = ANY($1)`

	rows, err := DB.Query(context.Background(), query, ids)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	users := make([]models.UserExploreSummary, 0, len(ids))

	for rows.Next() {
		var user models.UserExploreSummary
		var birthday time.Time

		err := rows.Scan(
			&user.ID,
			&user.Name,
			&user.ProfileURL,
			&birthday,
			&user.ImagesUrl,
			&user.Bio,
			&user.Country,
		)
		if err != nil {
			return []models.UserExploreSummary{}, err
		}
		user.Age = utils.AgeFromBirthday(birthday)
		users = append(users, user)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return users, nil

}

func (r *recRepo) GetCandidates(userId int, candidatePoolSize int) ([]int, error) {

	//also change the query when this changes

	query := `SELECT u.id
FROM users u
WHERE u.id != $1 -- exclude self
  AND u.id NOT IN (
      SELECT skipped FROM skips WHERE skipper = $1
  )
  AND u.id NOT IN (
      SELECT receiver_id FROM opinions WHERE sender_id = $1
  ) AND deleted_at IS NULL
ORDER BY u.last_login DESC
LIMIT 300;
`
	var num int
	log.Println("before query")
	rows, err := DB.Query(context.Background(), query, userId)
	if err != nil {
		return []int{}, err
	}
	log.Println("after query")

	ids := make([]int, 0, candidatePoolSize)
	for rows.Next() {
		err := rows.Scan(&num)
		if err != nil {
			return []int{}, err
		}
		ids = append(ids, num)
	}
	log.Println("after scan")

	return ids, nil
}

func (r *recRepo) GetNumberOfReceivedOpinions(userId int) (int, error) {
	query := `SELECT count(*) FROM opinions WHERE receiver_id = $1`
	var num int
	err := DB.QueryRow(context.Background(), query, userId).Scan(&num)
	if err != nil {
		return 0, err
	}
	return num, nil
}

func (r *recRepo) GetNumberOfSentOpinions(userId int) (int, error) {
	query := `SELECT count(*) FROM opinions WHERE sender_id = $1`
	var num int
	err := DB.QueryRow(context.Background(), query, userId).Scan(&num)
	if err != nil {
		return 0, err
	}
	return num, nil
}

func (r *recRepo) GetNumberOfMatches(userId int) (int, error) {
	query := `(SELECT count(*) FROM matches WHERE user1_id = $1 OR user2_id = $1 ) + (SELECT count(*) FROM chats WHERE user1_id = $1 OR user2_id = $1 )`
	var num int
	err := DB.QueryRow(context.Background(), query, userId).Scan(&num)
	if err != nil {
		return 0, err
	}
	return num, nil

}

func (r *recRepo) GetCreatedAt(userId int) (time.Time, error) {
	query := `SELECT created_at FROM users WHERE id = $1`
	var createdAt time.Time
	err := DB.QueryRow(context.Background(), query, userId).Scan(&createdAt)
	if err != nil {
		return time.Time{}, err
	}
	return createdAt, nil
}

func (r *recRepo) GetLastLogin(userId int) (time.Time, error) {
	query := `SELECT last_login FROM users WHERE id = $1`
	var createdAt time.Time
	err := DB.QueryRow(context.Background(), query, userId).Scan(&createdAt)
	if err != nil {
		return time.Time{}, err
	}
	return createdAt, nil
}
