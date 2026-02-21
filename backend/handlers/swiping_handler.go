package handlers

import (
	"backend/models"
	"backend/repository"
	"backend/services"
	"encoding/json"
	"log"
	"net/http"
)

func AddSkip(w http.ResponseWriter, r *http.Request) {
	// TODO
	var body map[string]interface{}
	err := json.NewDecoder(r.Body).Decode(&body)
	if err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}
	var skip models.Skip = models.Skip{SkipperID: r.Context().Value("userId").(int), SkippedID: int(body["skipped_id"].(float64))}

	err = repository.SkipRepo.Create(skip)
	if err != nil {
		log.Println(err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(skip)
}

func AddOpinion(w http.ResponseWriter, r *http.Request) {
	// TODO
	var body map[string]interface{}

	err := json.NewDecoder(r.Body).Decode(&body)
	if err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}
	var opinion models.Opinion = models.Opinion{SenderID: r.Context().Value("userId").(int), ReceiverID: int(body["receiver_id"].(float64)), Opinion: body["opinion"].(string)}

	err = services.SwipeService.AddOpinion(opinion)
	if err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(opinion)
}

func GetOpinionsByUser(w http.ResponseWriter, r *http.Request) {
	// TODO

	id := r.Context().Value("userId").(int)

	opinions, err := services.SwipeService.GetOpinionsByUser(id)
	if err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(opinions)

}
