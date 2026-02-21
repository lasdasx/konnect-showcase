package handlers

import (
	"backend/models"
	"backend/services"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"

	"strconv"

	"github.com/gorilla/mux"
)

func SetMessageRead(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r) // assuming you're using gorilla/mux
	chatIDStr := vars["chat_id"]

	chatId, err := strconv.Atoi(chatIDStr)
	if err != nil {
		http.Error(w, "Invalid message ID", http.StatusBadRequest)
		return
	}
	// Call the service instead of repository
	err = services.ChatService.SetRead(chatId)
	if err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
}
func GetChats(w http.ResponseWriter, r *http.Request) {
	id := r.Context().Value("userId").(int)

	// Call the service instead of repository
	chats, err := services.ChatService.GetChatsForUser(id)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "User not found", http.StatusNotFound)
		} else {
			http.Error(w, "Server error", http.StatusInternalServerError)
			log.Println(err)
		}
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(chats)
}

func GetChatMessages(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r) // assuming you're using gorilla/mux
	chatIDStr := vars["chat_id"]

	chatID, err := strconv.Atoi(chatIDStr)
	if err != nil {
		http.Error(w, "Invalid chat ID", http.StatusBadRequest)
		return
	}

	// Call the service instead of repository
	messages, err := services.ChatService.GetMessagesForChat(chatID)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "Chat not found", http.StatusNotFound)
		} else {
			http.Error(w, "Server error", http.StatusInternalServerError)
		}
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(messages)
}

func SendMessage(w http.ResponseWriter, r *http.Request) {
	var message models.Message

	err := json.NewDecoder(r.Body).Decode(&message)
	if err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}
	message.SenderID = r.Context().Value("userId").(int)
	err = services.ChatService.SendMessage(&message)
	if err != nil {
		http.Error(w, "Send Message error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(message)
}
