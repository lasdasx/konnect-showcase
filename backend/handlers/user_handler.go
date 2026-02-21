package handlers

import (
	"backend/models"
	"backend/repository"
	"backend/services"
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/mail"
	"strconv"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	"github.com/gorilla/mux"
)

func Logout(w http.ResponseWriter, r *http.Request) {
	id := r.Context().Value("userId").(int)
	var body map[string]interface{}
	err := json.NewDecoder(r.Body).Decode(&body)
	if err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}
	refreshToken := body["refresh_token"].(string)
	err = services.AuthService.Logout(id, refreshToken)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func RefreshTokenHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		http.Error(w, "Missing refresh token", http.StatusUnauthorized)
		return
	}

	parts := strings.SplitN(authHeader, " ", 2)
	if len(parts) != 2 || parts[0] != "Bearer" {
		http.Error(w, "Invalid token format", http.StatusUnauthorized)
		return
	}
	providedToken := parts[1]

	// Call service layer
	accessToken, refreshToken, err := services.AuthService.RefreshAccessToken(providedToken)
	if err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	json.NewEncoder(w).Encode(map[string]string{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
	})
}

func Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}

	// Authenticate user
	user, err := services.AuthService.Authenticate(req.Email, req.Password)
	if err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}
	if user.EmailVerified == false {

		passcode := req.Passcode

		if passcode == "" {
			w.WriteHeader(http.StatusPreconditionFailed)
			json.NewEncoder(w).Encode(map[string]string{"error": "Email not verified"})
			return
		}
		err = services.AuthService.VerifyEmail(user.ID, user.EmailVerificationPasscode, passcode, user.EmailPasscodeCreatedAt)
		if err != nil {

			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}

	}
	// Generate JWT
	token, err := services.AuthService.GenerateJWT(user.ID)
	if err != nil {
		http.Error(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	refreshToken := services.AuthService.GenerateRandomToken() // secure random string
	expiresAt := time.Now().UTC().Add(14 * 24 * time.Hour)     // 14 days

	err = repository.UserRepo.InsertRefreshToken(refreshToken, user.ID, expiresAt)
	if err != nil {
		http.Error(w, "Failed to save refresh token", http.StatusInternalServerError)
		return
	}

	// Return user info + token
	json.NewEncoder(w).Encode(map[string]interface{}{
		"user": map[string]interface{}{
			"id":        user.ID,
			"name":      user.Name,
			"email":     user.Email,
			"onboarded": user.Onboarded,
		},
		"token":         token,
		"refresh_token": refreshToken,
	})
}

func SendVerificationEmail(w http.ResponseWriter, r *http.Request) {

	body := map[string]interface{}{}
	err := json.NewDecoder(r.Body).Decode(&body)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid input"})
		return
	}
	email := body["email"].(string)

	EmailVerificationPasscode := services.AuthService.GenerateRandomPasscode()
	err = services.EmailService.UpdateEmailVerificationPasscode(email, EmailVerificationPasscode)
	err = services.EmailService.SendVerificationEmail(email, EmailVerificationPasscode)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Failed to send verification email"})
		return
	}

}
func RegisterUser(w http.ResponseWriter, r *http.Request) {
	var req models.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid input"})
		return
	}
	req.Email = strings.TrimSpace(req.Email)
	req.Password = strings.TrimSpace(req.Password)

	// Validate input
	if req.Password == "" || req.Email == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "All fields are required"})
		return
	}

	if _, err := mail.ParseAddress(req.Email); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid email address"})
		return
	}

	bytes, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	hash := string(bytes)
	if err != nil {
		http.Error(w, "Failed to hash password", http.StatusInternalServerError)
		return
	}

	// Map request to your User model
	user := models.User{
		Email:         req.Email,
		PasswordHash:  hash,
		Onboarded:     false,
		EmailVerified: false,
		
	}

	// Call service to insert into DB
	err = services.UserService.RegisterUser(&user)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{"error": err.Error()})
		return
	}
	// Never return the hash
	user.PasswordHash = ""
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{"user": user})
}

func GetUser(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r) // assuming you're using gorilla/mux
	userIDStr := vars["id"]

	id, err := strconv.Atoi(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	user, err := services.UserService.GetByID(id)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "User not found", http.StatusNotFound)
		} else {
			http.Error(w, "Server error", http.StatusInternalServerError)
		}
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

func GetUserMe(w http.ResponseWriter, r *http.Request) {


	id := r.Context().Value("userId").(int)
	user, err := services.UserService.GetByID(id)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "User not found", http.StatusNotFound)
		} else {
			http.Error(w, "Server error", http.StatusInternalServerError)
		}
		return
	}
	err = repository.UserRepo.UpdateLastLogin(id)
	if err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

func UpdateUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		http.Error(w, "Only PATCH allowed", http.StatusMethodNotAllowed)
		return
	}

	var updates map[string]interface{}
	err := json.NewDecoder(r.Body).Decode(&updates)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid input"})
		return
	}

	id := r.Context().Value("userId").(int)

	// Call a repository method that updates only the provided fields
	err = repository.UserRepo.UpdatePartial(id, updates)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Did not update user"})
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(updates)
}

func DeleteUser(w http.ResponseWriter, r *http.Request) {
	id := r.Context().Value("userId").(int)
	err := services.UserService.DeleteUser(id)
	if err != nil {
		http.Error(w, "Failed to Delete User", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode("User deleted successfully")

}

func GetPresignedUrl(w http.ResponseWriter, r *http.Request) {
	// TODO
	id := r.Context().Value("userId").(int)
	imageType := r.URL.Query().Get("type")
	contentType := r.URL.Query().Get("contentType") // "image/jpeg"

	if contentType == "" {
		contentType = "image/png" // Default
	}
	// Pass file to service
	url, key, err := services.UserService.GetPresignedUrl(id, imageType, contentType)

	if err != nil {
		// Return JSON response
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest) // or 409 Conflict
		json.NewEncoder(w).Encode(map[string]string{
			"error": err.Error(),
		})
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"url": url,
		"key": key,
	})
}

func UpdateImageUrl(w http.ResponseWriter, r *http.Request) {
	// TODO
	id := r.Context().Value("userId").(int)
	imageType := r.URL.Query().Get("type")
	// 2. Parse the request body to get the s3Key
	var requestBody struct {
		S3Key string `json:"s3_key"`
	}
	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if imageType != "profile" && imageType != "gallery" {
		http.Error(w, "Invalid image type", http.StatusBadRequest)
		return
	} else {
		url, err := services.UserService.UpdateImage(id, imageType, requestBody.S3Key)

		if err != nil {
			w.WriteHeader(http.StatusBadRequest) // or 404 / 500 depending on error
			json.NewEncoder(w).Encode(map[string]string{
				"error": err.Error(),
			})
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{
			"message": "Image URL updated successfully",
			"url":     url,
		})
	}
}

func DeleteImage(w http.ResponseWriter, r *http.Request) {
	// TODO
	id := r.Context().Value("userId").(int)
	var body map[string]interface{}
	err := json.NewDecoder(r.Body).Decode(&body)
	if err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}

	index := body["key_index"].(float64)
	key, err := services.UserService.DeleteImage(id, int(index))
	if err != nil {
		w.WriteHeader(http.StatusBadRequest) // or 404 / 500 depending on error
		json.NewEncoder(w).Encode(map[string]string{
			"error": err.Error(),
		})
		return

	}
	w.Header().Set("Content-Type", "application/json")

	// Success response
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "image with key " + key + " removed successfully",
	})
}

func GetImages(w http.ResponseWriter, r *http.Request) {
	// TODO
	id := r.Context().Value("userId").(int)
	key := r.URL.Query().Get("key")

	parts := strings.Split(key, "/")

	if parts[0] != strconv.Itoa(id) {
		http.Error(w, "Invalid key", http.StatusBadRequest)
		return
	}

	images, err := services.UserService.GetImageUrl(context.Background(), key)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(images)
}
