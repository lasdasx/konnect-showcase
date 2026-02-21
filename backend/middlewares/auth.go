package middlewares

import (
	"backend/services"
	"context"
	"log"
	"net/http"
	"os"
	"strings"
)

func AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		log.Println("reached auth")
		////////edo apenergopoio to middleware gia dev mode kai theto uid 1////////
		if os.Getenv("DEV_MODE") == "true" {
			// Attach fake user
			ctx := context.WithValue(r.Context(), "userId", 1)
			next.ServeHTTP(w, r.WithContext(ctx))
			return
		}

		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			log.Printf("Missing Authorization header\n")
			http.Error(w, "Missing Authorization header", http.StatusUnauthorized)
			return
		}

		// 2️⃣ Check format: "Bearer <token>"
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			log.Printf("Invalid Authorization header format\n")
			http.Error(w, "Invalid Authorization header format", http.StatusUnauthorized)
			return
		}

		tokenStr := parts[1]

		userID, err := services.AuthService.VerifyToken(tokenStr)
		if err != nil {
			log.Printf("Invalid token: %v\n", err)
			http.Error(w, "Invalid user ID in token", http.StatusUnauthorized)
		}
		log.Println("exited auth")
		ctx := context.WithValue(r.Context(), "userId", userID) // store as int
		// 5️⃣ Call the next handler
		next.ServeHTTP(w, r.WithContext(ctx))
	})

}
