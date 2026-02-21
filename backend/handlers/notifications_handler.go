package handlers

import (
	"backend/services"
	"encoding/json"
	"log"
	"net/http"
)

func SendNotification(w http.ResponseWriter, r *http.Request) {
	// Implement your notification sending logic here
	var bodyReq = map[string]interface{}{}
	err := json.NewDecoder(r.Body).Decode(&bodyReq)
	if err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}
	user_id := int(bodyReq["user_id"].(float64))
	title := bodyReq["title"].(string)
	body := bodyReq["body"].(string)
	rawData := bodyReq["data"].(map[string]interface{})
	data := make(map[string]string)
	for k, v := range rawData {
		strVal, ok := v.(string)
		if !ok {
			http.Error(w, "Invalid data value", http.StatusBadRequest)
			return
		}
		data[k] = strVal
	}
	err = services.NotificationService.SendNotification(user_id, title, body, data, true)
	if err != nil {
		log.Println(err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func RegisterDeviceToken(w http.ResponseWriter, r *http.Request) {
	log.Println("register service")
	// Implement your notification registration logic here
	userId := r.Context().Value("userId").(int)
	var bodyReq = map[string]interface{}{}
	err := json.NewDecoder(r.Body).Decode(&bodyReq)
	if err != nil {
		log.Println(err)
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}
	deviceToken := bodyReq["device_token"].(string)
	device_id := bodyReq["device_id"].(string)
	log.Println(userId, deviceToken, device_id)
	err = services.NotificationService.RegisterDeviceToken(userId, deviceToken, device_id)
	if err != nil {
		log.Println(err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}
