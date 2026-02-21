package services

import (
	"backend/repository"
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"text/template"

	"github.com/joho/godotenv"
)

var EmailService = &emailService{
	apiKey: initBrevo(),
}

type emailService struct {
	apiKey string
}

func initBrevo() string {
	if err := godotenv.Load(); err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}

	apiKey := os.Getenv("BREVO_API_KEY")
	if apiKey == "" {
		log.Fatal("BREVO_API_KEY is not set")
	}

	return apiKey
}

// Send verification email using Brevo
func (s *emailService) SendVerificationEmail(email string, passcode string) error {
	// 1. Parse HTML template
	tmpl, err := template.ParseFiles("templates/verification.html")
	if err != nil {
		log.Println(err)
		return fmt.Errorf("failed to parse template: %w", err)
	}

	var bodyBuffer bytes.Buffer
	data := struct{ Passcode string }{Passcode: passcode}
	if err := tmpl.Execute(&bodyBuffer, data); err != nil {

		log.Println(err)
		return fmt.Errorf("failed to execute template: %w", err)
	}

	// 2. Build Brevo payload
	payload := map[string]interface{}{
		"sender": map[string]string{
			"email": os.Getenv("BREVO_SENDER_EMAIL"),
			"name":  os.Getenv("BREVO_SENDER_NAME"),
		},
		"to": []map[string]string{
			{"email": email},
		},
		"subject":     fmt.Sprintf("%s is your Konnect code", passcode),
		"htmlContent": bodyBuffer.String(),
		"textContent": fmt.Sprintf(
			"Your Konnect verification code is: %s",
			passcode,
		),
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {

		log.Println(err)
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	// 3. Send HTTP request
	req, err := http.NewRequest(
		"POST",
		"https://api.brevo.com/v3/smtp/email",
		bytes.NewBuffer(jsonData),
	)
	if err != nil {

		log.Println(err)
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("api-key", s.apiKey)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {

		log.Println(err)
		return err
	}
	defer resp.Body.Close()

	// 4. Handle errors
	if resp.StatusCode >= 300 {

		log.Println(err)
		return fmt.Errorf("brevo email failed with status %d", resp.StatusCode)
	}

	return nil
}

func (s *emailService) UpdateEmailVerificationPasscode(email string, passcode string) error {

	err := repository.UserRepo.UpdateEmailVerificationPasscode(email, passcode)
	return err
}
