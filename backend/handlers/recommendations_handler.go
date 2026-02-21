package handlers

import (
	"backend/models"
	"backend/services"
	"encoding/json"
	"log"
	"net/http"
)

func GetRecomendations(w http.ResponseWriter, r *http.Request) {

	id := r.Context().Value("userId").(int)
	log.Println("received recomendations request from user", id)
	////////////////a lot to be done
	var recs []models.UserExploreSummary
	// recs = append(recs, id)

	recs, err := services.RecommendationService.GetRecomendations(id)
	if err != nil {
		http.Error(w, "Recommendations Server error", http.StatusInternalServerError)
		log.Println(err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(recs)
	// TODO
}
