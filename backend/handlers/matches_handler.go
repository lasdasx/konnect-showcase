package handlers

import (
	"backend/services"
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
)

func GetMatches(w http.ResponseWriter, r *http.Request) {
	id := r.Context().Value("userId").(int)

	// Call the service instead of repository
	matches, err := services.MatchService.GetMatchesForUser(id)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "User not found", http.StatusNotFound)
		} else {
			http.Error(w, "Server error", http.StatusInternalServerError)
		}
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(matches)
}

func GetMatchOpinions(w http.ResponseWriter, r *http.Request) {
	// TODO
	userId := r.Context().Value("userId").(int)
	// other_user_id := r.URL.Query().Get("other_user_id")

	vars := mux.Vars(r) // assuming you're using gorilla/mux
	other_id_string := vars["other_user_id"]

	other_user_id, err := strconv.Atoi(other_id_string)
	if err != nil {
		http.Error(w, "Invalid chat ID", http.StatusBadRequest)
		return
	}
	opinions, err := services.MatchService.GetMatchOpinions(userId, other_user_id)
	if err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(opinions)
}
