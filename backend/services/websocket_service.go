package services

import (
	"backend/models"
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

type wsService struct {
	// Map userID (string) to their WebSocket connection
	clients map[int]*websocket.Conn
	mu      sync.Mutex
}

var WsService = &wsService{
	clients: make(map[int]*websocket.Conn),
}

// Keep track of connected clients

// Register a new WebSocket client
func (s *wsService) RegisterClient(userID int, conn *websocket.Conn) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.clients[userID] = conn
	// Start a heartbeat goroutine for this connection
	go func(c *websocket.Conn) {
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()

		for range ticker.C {
			// WriteControl sends a Ping frame (standard WS protocol)
			if err := c.WriteControl(websocket.PingMessage, []byte{}, time.Now().Add(10*time.Second)); err != nil {
				log.Println("Ping failed, closing connection for user", userID)
				s.UnregisterClient(userID)
				return
			}
		}
	}(conn)
}

func (s *wsService) UnregisterClient(userID int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if conn, ok := s.clients[userID]; ok {
		conn.Close()
		delete(s.clients, userID)
	}
}

func (s *wsService) SendToClient(userID int, update models.WsMessage) {
	s.mu.Lock()
	conn, exists := s.clients[userID]
	s.mu.Unlock() // Unlock early to avoid blocking other broadcasts during the write

	if !exists {
		log.Printf("User %d is not connected", userID)
		return
	}

	message, _ := json.Marshal(update)
	err := conn.WriteMessage(websocket.TextMessage, message)

	// Cast 'message' to string to see the actual JSON text
	log.Println("Sending private WS message to user", userID, "with message:", string(message))
	if err != nil {
		log.Println("Error sending private WS message:", err)
		s.UnregisterClient(userID)
	}
}
