package services

import (
	"backend/models"
	"backend/repository"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log"
	"math/big"
	"strconv"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

var AuthService = &authService{}

type authService struct {
	jwtKey []byte
}

func (s *authService) InitJWT(key []byte) {
	s.jwtKey = key
}

func (s *authService) Logout(id int, refreshToken string) error {
	err := repository.UserRepo.DeleteRefreshToken(id, refreshToken)
	if err != nil {
		return err
	}
	return nil
}

func (s *authService) Authenticate(email, password string) (*models.User, error) {
	user, err := repository.UserRepo.GetByEmail(email)
	if err != nil {
		log.Println(err)
		return nil, err
	}

	log.Println(user.PasswordHash)
	log.Println(password)
	// Compare hashed password with the plain text
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		log.Println(err)
		return nil, fmt.Errorf("invalid password")
	}

	return user, nil
}



func (s *authService) GenerateJWT(userId int) (string, error) {
	claims := &jwt.RegisteredClaims{
		Subject:   fmt.Sprint(userId),
		ExpiresAt: jwt.NewNumericDate(time.Now().UTC().Add(24 * time.Hour)), // 1 year jwt gia convienience
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtKey)
}

func (s *authService) RefreshAccessToken(providedToken string) (string, string, error) {
	// 1️⃣ Lookup refresh token in DB
	storedToken, err := repository.UserRepo.GetRefreshToken(providedToken)
	if err != nil || storedToken == nil {
		log.Printf("Refresh token error: %v, token: %s\n", err, providedToken)

		return "", "", fmt.Errorf("invalid refresh token")
	}

	// 2️⃣ Check expiration
	if time.Now().UTC().After(storedToken.ExpiresAt) {
		return "", "", fmt.Errorf("refresh token expired")
	}

	userId := storedToken.UserId

	// 3️⃣ Generate new access token
	newAccessToken, err := s.GenerateJWT(userId)
	if err != nil {
		return "", "", fmt.Errorf("could not generate access token")
	}

	// 4️⃣ Rotate refresh token
	newRefreshToken := s.GenerateRandomToken()
	err = repository.UserRepo.UpdateRefreshToken(storedToken.Token, newRefreshToken, time.Now().Add(90*24*time.Hour))
	if err != nil {
		return "", "", fmt.Errorf("could not rotate refresh token")
	}

	return newAccessToken, newRefreshToken, nil
}

func (s *authService) GenerateRandomToken() string {
	b := make([]byte, 32)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}
func (s *authService) GenerateRandomPasscode() string {
	// Generate a random number between 0 and 999,999
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		// Fallback or panic; in production, crypto/rand failure is critical
		panic(err)
	}

	// %06d ensures leading zeros (e.g., 52 becomes "000052")
	return fmt.Sprintf("%06d", n)
}

func (s *authService) VerifyToken(tokenStr string) (int, error) {
	claims := &jwt.RegisteredClaims{}

	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (any, error) {
		// Enforce HS256
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return s.jwtKey, nil
	})

	if err != nil || !token.Valid {
		return 0, err // Return zero userID and the error
	}

	userID, err := strconv.Atoi(claims.Subject)
	if err != nil {
		return 0, err // Return error if claims.Subject is not a number
	}

	return userID, nil
}

func (s *authService) VerifyEmail(userId int, emailPasscode string, passcode string, passcodeDate time.Time) error {
	fmt.Printf("DEBUG: Received PasscodeDate: %v | IsZero: %v\n", passcodeDate, passcodeDate.IsZero())
	if emailPasscode != passcode {
		return fmt.Errorf("invalid passcode")
	} else if time.Now().UTC().After(passcodeDate.UTC().Add(time.Hour)) {
		return fmt.Errorf("passcode expired")

	}

	err := repository.UserRepo.VerifyEmail(userId)
	if err != nil {
		return err
	}

	return nil

}
