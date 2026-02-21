package main

import (
	"backend/config"
	"backend/handlers"
	"backend/middlewares"
	"backend/repository"
	"backend/services"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/websocket"

	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

// Map of connected clients
var wsClients = make(map[*websocket.Conn]bool)

func main() {
	repository.InitDB()
	defer repository.DB.Close()

	s3Client := config.InitS3Client()

	services.AuthService.InitJWT([]byte(os.Getenv("JWT_SECRET")))

	if err := services.NotificationService.Initialize(); err != nil {
		panic(err)
	}
	services.UserService.InitS3(s3Client, "konnect839799794038")

	go services.StartCleanupWorker()

	s := mux.NewRouter()
	s.Use(middlewares.JSONMiddleware)

	api := s.PathPrefix("/api").Subrouter()

	api.HandleFunc("/sendNotification", handlers.SendNotification).Methods("POST")

	api.HandleFunc("/ws", handlers.WebSocketHandler).Methods("GET")

	api.HandleFunc("/auth/login", handlers.Login).Methods("POST")
	api.HandleFunc("/auth/register", handlers.RegisterUser).Methods("POST")
	api.HandleFunc("/auth/refresh", handlers.RefreshTokenHandler).Methods("POST")
	api.HandleFunc("/auth/verificationEmail", handlers.SendVerificationEmail).Methods("POST")

	// Enable CORS for your Flutter Web frontend
	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"}, // ⚡ allow any origin
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: false, // cannot be true with "*" origin
	})

	auth := api.PathPrefix("/").Subrouter()
	auth.Use(middlewares.AuthMiddleware)
	auth.HandleFunc("/auth/logout", handlers.Logout).Methods("POST")
	auth.HandleFunc("/user", handlers.UpdateUser).Methods("PATCH")
	auth.HandleFunc("/user", handlers.DeleteUser).Methods("DELETE")

	auth.HandleFunc("/register-device-token", handlers.RegisterDeviceToken).Methods("POST")
	auth.HandleFunc("/user/me", handlers.GetUserMe).Methods("GET")

	auth.HandleFunc("/user/{id}", handlers.GetUser).Methods("GET")

	auth.HandleFunc("/chats", handlers.GetChats).Methods("GET")

	auth.HandleFunc("/matches", handlers.GetMatches).Methods("GET")

	auth.HandleFunc("/opinion", handlers.AddOpinion).Methods("POST")

	auth.HandleFunc("/skip", handlers.AddSkip).Methods("POST") //need to add it in the db

	auth.HandleFunc("/opinions", handlers.GetOpinionsByUser).Methods("GET")

	auth.HandleFunc("/matchOpinions/{other_user_id}", handlers.GetMatchOpinions).Methods("GET")
	auth.HandleFunc("/messages/{chat_id}", handlers.GetChatMessages).Methods("GET")
	auth.HandleFunc("/message", handlers.SendMessage).Methods("POST")

	auth.HandleFunc("/recomendations", handlers.GetRecomendations).Methods("GET")

	auth.HandleFunc("/setReadMessage/{chat_id}", handlers.SetMessageRead).Methods("POST")

	//handle images
	auth.HandleFunc("/images/presigned", handlers.GetPresignedUrl).Methods("GET")
	auth.HandleFunc("/images", handlers.UpdateImageUrl).Methods("POST")
	auth.HandleFunc("/images", handlers.DeleteImage).Methods("DELETE")
	auth.HandleFunc("/images", handlers.GetImages).Methods("GET")
	log.Println("API running on :8080")
	handler := c.Handler(s)
	handler = logRequests(handler)

	log.Fatal(http.ListenAndServe(":8080", handler))
}
func logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf(
			"REQ %s %s from %s",
			r.Method,
			r.URL.Path,
			r.RemoteAddr,
		)
		next.ServeHTTP(w, r)
	})
}
