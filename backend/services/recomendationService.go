package services

import (
	"context"
	"math/rand"

	"backend/models"
	"backend/repository"
	components "backend/services/recommendationComponents"
	"log"
	"sort"

	"golang.org/x/sync/errgroup"
)

var RecommendationService = &recommendationService{}

type recommendationService struct{}

type CandidateScore struct {
	ProfileID int
	Score     [6]float64
}

type CandidateFinalScore struct {
	ProfileID int
	Score     float64
}

func (r *recommendationService) GetRecomendations(userId int) ([]models.UserExploreSummary, error) {

	ids := r.GetRecomendationsIds(userId)

	log.Println("ids: ", ids)

	summaries, err := repository.RecRepo.GetExploreSummariesByIDs(ids)

	if err != nil {
		log.Println(err)

		return nil, err

	}
	var g errgroup.Group

	// 2. Iterate through each profile
	for i := range summaries {

		g.Go(func() error {
			i := i
			// Transform the single Profile Image
			if summaries[i].ProfileURL != "" {
				signedURL, _ := UserService.GetImageUrl(context.Background(), summaries[i].ProfileURL)
				summaries[i].ProfileURL = signedURL
			}

			// Transform the Gallery Array
			for j, key := range summaries[i].ImagesUrl {
				// We replace the key in the slice with the actual signed URL
				signedURL, err := UserService.GetImageUrl(context.Background(), key)
				if err == nil {
					summaries[i].ImagesUrl[j] = signedURL

				}
			}
			return nil
		})

	}

	if err := g.Wait(); err != nil {
		log.Println("warning: some images failed to fetch:", err)
	}

	return summaries, nil
}

func (r *recommendationService) GetRecomendationsIds(userId int) []int {

	log.Println("GetRecomendationsIds called")
	candidates, err := r.GetCandidates(userId, 300)
	if err != nil {
		log.Println(err)
		return []int{}
	}
	// log.Println("candidates: ", candidates)
	numWorkers := 10 // number of goroutines
	batchSize := (len(candidates) + numWorkers - 1) / numWorkers

	candidatesWithScores := make([]CandidateScore, len(candidates))
	var group errgroup.Group

	for w := 0; w < numWorkers; w++ {
		start := w * batchSize
		end := start + batchSize
		if start >= len(candidates) {
			break // No more work to distribute
		}
		if end > len(candidates) {
			end = len(candidates)
		}
		batch := candidates[start:end]

		group.Go(func() error {
			for i, candidate := range batch {
				idx := start + i
				candidatesWithScores[idx] = CandidateScore{
					ProfileID: candidate,
					Score:     r.CalculateScore(userId, candidate),
				}
			}
			return nil
		})
	}

	if err := group.Wait(); err != nil {
		log.Println(err)
	}

	normalizeScores(&candidatesWithScores)

	candidatesWithFinalScores := calculateFinalScores(&candidatesWithScores)

	sort.Slice(candidatesWithFinalScores, func(i, j int) bool {
		return candidatesWithFinalScores[i].Score > candidatesWithFinalScores[j].Score // descending
	})

	topN := 10 //////number of ids returned
	if topN > len(candidatesWithFinalScores) {
		topN = len(candidatesWithFinalScores)
	}

	topCandidates := make([]int, topN)

	for i := 0; i < topN; i++ {
		topCandidates[i] = candidatesWithFinalScores[i].ProfileID
	}

	////add some random candidates for novelty from the original candidate set////
	log.Println("topCandidates: ", topCandidates)

	return topCandidates //maybe like a wheel with probabilities instead of top
}

func (r *recommendationService) GetCandidates(userId int, candidatePoolSize int) ([]int, error) {
	///access the db to fetch profiles the user hasnt interacted with
	log.Println("GetCandidates called")
	candidates, err := repository.RecRepo.GetCandidates(userId, candidatePoolSize)
	if err != nil {
		return []int{}, err
	}

	return candidates, nil
}

func (r *recommendationService) CalculateScore(userId int, profileId int) [6]float64 {

	v1 := components.UserFeatures.NumberOfMatches(profileId)
	v2 := components.UserFeatures.NumberOfSentOpinions(profileId)
	v3 := components.UserFeatures.NumberOfReceivedOpinions(profileId)
	v4 := components.UserFeatures.DaysSinceRegistration(profileId)
	v5 := components.UserFeatures.HoursSinceLastLogin(profileId)
	v6 := components.UserFeatures.HasLeftOpinion(profileId, userId)
	return [6]float64{float64(v1), float64(v2), float64(v3), float64(v4), float64(v5), float64(v6)}
}

func normalizeScores(candidatesWithScores *[]CandidateScore) {
	// Initialize min and max arrays
	minVals := [5]float64{1e9, 1e9, 1e9, 1e9, 1e9}
	maxVals := [5]float64{-1e9, -1e9, -1e9, -1e9, -1e9}

	// Find min/max across all candidates
	for _, c := range *candidatesWithScores {
		for j := 0; j < 5; j++ { // first 5 columns
			val := c.Score[j]
			if val < minVals[j] {
				minVals[j] = val
			}
			if val > maxVals[j] {
				maxVals[j] = val
			}
		}
	}
	for i := range *candidatesWithScores {
		for j := 0; j < 5; j++ {
			min := minVals[j]
			max := maxVals[j]
			val := (*candidatesWithScores)[i].Score[j]

			if max != min {
				(*candidatesWithScores)[i].Score[j] = (val - min) / (max - min) // min-max normalization
			} else {
				(*candidatesWithScores)[i].Score[j] = 0 // all values are the same
			}
		}
	}

}

func calculateFinalScores(candidatesWithScores *[]CandidateScore) []CandidateFinalScore {

	///modify the weights or tune them using a model
	w1 := 0.1 //number of matches of other user
	w2 := 0.1 //number of sent opinions of other user
	w3 := 0.1 //number of received opinions of other user
	w4 := 0.1 //days since registration of other user
	w5 := 0.1 //hours since last login of other user
	w6 := 0.3 //other profile has left opinion
	w7 := 0.2 //random factor
	finalScores := make([]CandidateFinalScore, len(*candidatesWithScores))
	for i, c := range *candidatesWithScores {
		finalScores[i] = CandidateFinalScore{
			ProfileID: c.ProfileID,
			Score:     w1*c.Score[0] + w2*c.Score[1] + w3*c.Score[2] + w4*c.Score[3] + w5*c.Score[4] + w6*c.Score[5] + w7*rand.Float64(),
		}
	}
	return finalScores
}
