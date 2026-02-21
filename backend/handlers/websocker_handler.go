package handlers

import (
	"log"
	"net/http"

	"backend/services"

	"github.com/gorilla/websocket"
)

var wsUpgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true }, /////allow any origin, mallon prepei na allaksei meta
}

func WebSocketHandler(w http.ResponseWriter, r *http.Request) {

	tokenStr := r.URL.Query().Get("token")
	if tokenStr == "" {
		http.Error(w, "missing token", http.StatusUnauthorized)
		return
	}

	userID, err := services.AuthService.VerifyToken(tokenStr)
	if err != nil {
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}

	conn, err := wsUpgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("WebSocket upgrade error:", err)
		return
	}
	defer conn.Close()

	services.WsService.RegisterClient(userID, conn)
	log.Println("New WebSocket client connected")

	for {
		_, _, err := conn.ReadMessage() // optional
		if err != nil {
			log.Println("WebSocket client disconnected")
			services.WsService.UnregisterClient(userID)
			break
		}
	}
}
