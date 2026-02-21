package services

import (
	"backend/repository"
	"context"
	"fmt"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"

	"google.golang.org/api/option"
)

var NotificationService = &notificationService{}

type notificationService struct {
	notificationsClient *messaging.Client
}

func (s *notificationService) Initialize() error {
	opt := option.WithCredentialsFile("konnect-37d1e-firebase-adminsdk-fbsvc-32b39f2410.json")
	cfg := &firebase.Config{
		ProjectID: "konnect-37d1e", // replace with your Firebase project ID
	}
	app, err := firebase.NewApp(context.Background(), cfg, opt)
	if err != nil {
		return fmt.Errorf("error initializing app: %v", err)
	}
	client, err := app.Messaging(context.Background())
	if err != nil {
		return fmt.Errorf("error getting messaging client: %v", err)
	}

	s.notificationsClient = client
	return nil
}

func (s *notificationService) SendNotification(user_id int, title, body string, data map[string]string, highImportance bool) error {
	log.Println("reached service")
	log.Println(title, body, data)
	ctx := context.Background()

	// 1️⃣ Get all device tokens for the user
	deviceTokens, err := repository.NotificationRepo.GetDeviceTokens(user_id)
	if err != nil {
		log.Printf("Error getting device tokens for user %d: %v", user_id, err)
		return err
	}

	if len(deviceTokens) == 0 {
		return nil // no devices, nothing to send
	}

	log.Println("before message")
	log.Println(title, body, data)
	channelID := "low_importance_channel"
	if highImportance {
		channelID = "high_importance_channel"
	}
	// 2️⃣ Create the multicast message
	message := &messaging.MulticastMessage{
		Tokens: deviceTokens,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data, // optional extra key-value data
		Android: &messaging.AndroidConfig{
			Notification: &messaging.AndroidNotification{
				ChannelID: channelID, // <-- pick the channel here
			},
		},
	}
	log.Println("after message")
	log.Println(message)
	// 3️⃣ Send the message
	br, err := s.notificationsClient.SendEachForMulticast(ctx, message)
	if err != nil {
		log.Printf("Error sending multicast message: %v", err)
		return fmt.Errorf("error sending multicast message: %v", err)
	}

	log.Printf("Successfully sent %d messages, %d failures\n", br.SuccessCount, br.FailureCount)

	// 4️⃣ Optional: remove invalid tokens from DB
	for i, resp := range br.Responses {
		if !resp.Success {
			// Example: remove invalid tokens
			fmt.Printf("Failed token: %s, error: %v\n", deviceTokens[i], resp.Error)
			// repository.NotificationRepo.RemoveDeviceToken(deviceTokens[i])
		}
	}

	return nil
}

func (s *notificationService) RegisterDeviceToken(userId int, deviceToken, device_id string) error {

	err := repository.NotificationRepo.AddDeviceToken(userId, deviceToken, device_id)
	if err != nil {
		log.Println("error registering: ", err)
		return err
	}

	return nil
}
