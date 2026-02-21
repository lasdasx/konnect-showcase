package services

import (
	"backend/repository"
	"context"
	"log"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

func StartCleanupWorker() {
	// Run once immediately on startup
	performPermanentDeletion()

	// Then run every 24 hours
	ticker := time.NewTicker(24 * time.Hour)

	for range ticker.C {
		performPermanentDeletion()
	}
}

func performPermanentDeletion() {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	// 1️⃣ Select expired accounts with their S3 keys
	rows, err := repository.DB.Query(ctx, `
        SELECT id, images_url , profile_url
        FROM users
        WHERE deleted_at IS NOT NULL
          AND deleted_at < NOW() - INTERVAL '30 days'
    `)
	if err != nil {
		log.Printf("Cleanup worker error fetching expired accounts: %v", err)
		return
	}
	defer rows.Close()

	type userImages struct {
		ID         int
		ImageKeys  []string
		ProfileUrl string
	}

	var usersToDelete []userImages

	for rows.Next() {
		var u userImages
		err := rows.Scan(&u.ID, &u.ImageKeys, &u.ProfileUrl) // assuming images_url is a Postgres text[] column
		if err != nil {
			log.Printf("Error scanning user images: %v", err)
			continue
		}
		usersToDelete = append(usersToDelete, u)
	}

	// 2️⃣ Delete files from S3
	for _, user := range usersToDelete {
		for _, key := range user.ImageKeys {
			_, err := UserService.s3Client.DeleteObject(ctx, &s3.DeleteObjectInput{
				Bucket: aws.String(UserService.bucket),
				Key:    aws.String(key),
			})
			if err != nil {
				log.Printf("Failed to delete S3 object %s: %v", key, err)
			} else {
				log.Printf("Deleted S3 object: %s", key)
			}
		}
		_, err := UserService.s3Client.DeleteObject(ctx, &s3.DeleteObjectInput{
			Bucket: aws.String(UserService.bucket),
			Key:    aws.String(user.ProfileUrl),
		})
		if err != nil {
			log.Printf("Failed to delete S3 object %s: %v", user.ProfileUrl, err)
		} else {
			log.Printf("Deleted S3 object: %s", user.ProfileUrl)
		}

	}

	// 3️⃣ Delete rows from DB
	result, err := repository.DB.Exec(ctx, `
        DELETE FROM users 
        WHERE deleted_at IS NOT NULL 
          AND deleted_at < NOW() - INTERVAL '30 days'
    `)
	if err != nil {
		log.Printf("Cleanup worker error deleting DB rows: %v", err)
		return
	}

	rowsDeleted := result.RowsAffected()
	if rowsDeleted > 0 {
		log.Printf("Cleanup: Purged %d expired accounts from the database", rowsDeleted)
	}
}


