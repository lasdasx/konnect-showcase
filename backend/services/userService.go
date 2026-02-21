package services

import (
	"backend/models"
	"context"
	"fmt"
	"log"
	"strings"
	"time"

	"backend/repository"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

var UserService = &userService{}

type userService struct {
	s3Client *s3.Client // Add these fields to the struct
	bucket   string
}

func (s *userService) InitS3(client *s3.Client, bucket string) {
	s.s3Client = client
	s.bucket = bucket
}

// ////TODOOOOO
func (s *userService) RegisterUser(user *models.User) error {

	// 1️⃣ Create user FIRST
	if err := repository.UserRepo.Create(user); err != nil {
		return err
	}


	return nil
}


func (s *userService) DeleteUser(id int) error {

	err := repository.UserRepo.MarkUserDeleted(id)
	err = repository.UserRepo.DeleteRefreshTokens(id)

	return err
}

func (s *userService) GetPresignedUrl(userId int, imageType string, contentType string) (string, string, error) {
	// 1. Generate a unique key (path) for the image
	// Using unix nano ensures filename uniqueness even if a user uploads twice in one second
	ext := ".png"
	switch contentType {
	case "image/jpeg", "image/jpg":
		ext = ".jpg"
	case "image/webp":
		ext = ".webp"
	}

	// 2. Build the key
	filename := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)
	s3Key := fmt.Sprintf("users/%d/%s/%s", userId, imageType, filename)

	if imageType == "gallery" {
		length, err := repository.UserRepo.GetGalleryLength(userId)
		if err != nil {
			return "", "", err
		}
		if length >= 6 {
			return "", "", fmt.Errorf("cannot upload more than 6 images")
		}
	}

	//maybe delete the old profile pic if its a profile type

	// 2. Initialize the Presign Client (assuming s.s3Client is your *s3.Client)
	presignClient := s3.NewPresignClient(s.s3Client)

	// 3. Create the presigned PUT request
	// We use PutObject because the client will do an HTTP PUT to S3
	presignedReq, err := presignClient.PresignPutObject(context.Background(), &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(s3Key),
		ContentType: aws.String(contentType),
	}, s3.WithPresignExpires(5*time.Minute))

	if err != nil {
		return "", "", fmt.Errorf("could not generate presigned url: %v", err)
	}

	// We return both the URL (for the frontend to use)
	// and the s3Key (for the frontend to send back to us in the POST/Confirm step)
	return presignedReq.URL, s3Key, nil
}

func (s *userService) UpdateImage(id int, imageType string, s3Key string) (string, error) {
	////maybe delete the old profile image
	if imageType == "profile" {

		err := repository.UserRepo.ChangeProfileImage(id, s3Key)
		if err != nil {
			return "", err
		}

		url, err := s.GetImageUrl(context.Background(), s3Key)

		return url, err

	} else {

		err := repository.UserRepo.AddImage(id, s3Key)

		if err != nil {
			return "", err
		}

		url, err := s.GetImageUrl(context.Background(), s3Key)

		return url, err
	}

}

func (s *userService) DeleteImage(id int, keyIndex int) (string, error) {

	s3Key, err := repository.UserRepo.DeleteImage(id, keyIndex)
	if err != nil {
		log.Printf("Non-critical error: failed to delete DB image at index %d: %v", keyIndex, err)
		return "", fmt.Errorf("failed to delete image from DB: %w", err)
	}

	_, err = s.s3Client.DeleteObject(context.Background(), &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(s3Key),
	})

	if err != nil {
		// We log the error but might not return it to the user
		// because the DB part is already done.
		log.Printf("Non-critical error: failed to delete S3 object %s: %v", s3Key, err)
	}

	return s3Key, nil
}

func (s *userService) GetByID(id int) (models.User, error) {
	user, err := repository.UserRepo.GetByID(id)
	if err != nil {
		return models.User{}, err
	}

	if user.ProfileURL != "" {
		signed, err := s.GetImageUrl(context.Background(), user.ProfileURL)
		if err == nil {
			user.ProfileURL = signed
		}

	}

	for i := range user.ImagesURL {
		signed, err := s.GetImageUrl(context.Background(), user.ImagesURL[i])
		if err == nil {
			user.ImagesURL[i] = signed
		}
	}

	return user, nil
}

func (s *userService) GetSummaryByID(id int) (models.UserSummary, error) {
	user, err := repository.UserRepo.GetSummaryByID(id)
	if err != nil {
		return models.UserSummary{}, err
	}

	if user.ProfileURL != "" {
		user.ProfileURL, err = s.GetImageUrl(context.Background(), user.ProfileURL)

	}

	return user, nil
}

func (s *userService) GetImageUrl(ctx context.Context, s3Key string) (string, error) {

	if strings.HasPrefix(s3Key, "http://") || strings.HasPrefix(s3Key, "https://") {
		return s3Key, nil
	} /////this in order to work with the old db

	presignClient := s3.NewPresignClient(s.s3Client)

	// We use PresignGetObject to let the app VIEW/DOWNLOAD the file
	request, err := presignClient.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(s3Key),
	}, s3.WithPresignExpires(60*time.Minute)) // Link lasts 1 hour

	if err != nil {
		return "", err
	}
	return request.URL, nil
}
