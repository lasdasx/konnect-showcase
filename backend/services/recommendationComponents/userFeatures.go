package components

import (
	"backend/repository"
	"math"
	"time"
)

var UserFeatures = &userFeatures{}

type userFeatures struct{}

func (u *userFeatures) HasLeftOpinion(userId int, profileId int) int {
	exists, err := repository.RecRepo.HasLeftOpinion(userId, profileId)
	if err != nil {
		return 0
	}
	if exists {
		return 1
	} else {
		return 0
	}
}

func (u *userFeatures) NumberOfReceivedOpinions(userId int) int {
	num, err := repository.RecRepo.GetNumberOfReceivedOpinions(userId)
	if err != nil {
		return 0
	}
	return num
}

func (u *userFeatures) NumberOfSentOpinions(userId int) int {
	num, err := repository.RecRepo.GetNumberOfSentOpinions(userId)
	if err != nil {
		return 0
	}
	return num
}

func (u *userFeatures) NumberOfMatches(userId int) int {
	num, err := repository.RecRepo.GetNumberOfMatches(userId)
	if err != nil {
		return 0
	}
	return num
}

func (u *userFeatures) DaysSinceRegistration(userId int) float64 {

	date, err := repository.RecRepo.GetCreatedAt(userId)
	if err != nil {
		return -math.Log1p(365)
	}
	days := math.Min(time.Since(date).Hours()/24, 365) // max 1 year
	return -math.Log1p(days)                           /// logarithmika oste na metrane ta recent changes pio poli apta makrina , na mi mazevontai ta prosfata konta sto 1 kata to normalization
}

func (u *userFeatures) HoursSinceLastLogin(userId int) float64 {

	date, err := repository.RecRepo.GetLastLogin(userId)
	if err != nil {
		return -math.Log1p(30 * 24)
	}
	hours := math.Min(time.Since(date).Hours(), 30*24) // max 1 month

	return -math.Log1p(hours)
}
