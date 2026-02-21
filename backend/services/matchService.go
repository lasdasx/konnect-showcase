package services

import (
	"backend/models"
	"backend/repository"
	"log"

	"golang.org/x/sync/errgroup"
)

var MatchService = &matchService{}

type matchService struct{}

func (s *matchService) GetMatchesForUser(userID int) ([]models.MatchSummary, error) {
	matches, err := repository.MatchRepo.GetByUserID(userID)
	if err != nil {
		return nil, err
	}

	summaries := make([]models.MatchSummary, len(matches))
	var g errgroup.Group

	for i, match := range matches {
		i := i
		match := match // capture loop variables

		g.Go(func() error {
			var otherID int
			if match.UserId1 == userID {
				otherID = match.UserId2
			} else {
				otherID = match.UserId1
			}

			user, err := UserService.GetSummaryByID(otherID)
			if err != nil {
				return err
			}

			summaries[i] = models.MatchSummary{
				ID:         match.ID,
				UserID:     otherID,
				Name:       user.Name,
				ProfileURL: user.ProfileURL,
			}

			return nil
		})

	}
	if err := g.Wait(); err != nil {
		return nil, err
	}
	return summaries, nil
}

func (s *matchService) GetMatchOpinions(user_id int, other_user_id int) ([]models.OpinionSummary, error) {
	opinions, err := repository.OpinionRepo.GetByUserIDs(user_id, other_user_id)
	if err != nil {
		return nil, err
	}
	opinion1 := opinions[0]
	opinion2 := opinions[1]

	user1, err := UserService.GetSummaryByID(user_id)
	user2, err := UserService.GetSummaryByID(other_user_id)

	opinion1Summary := models.OpinionSummary{
		ID:         opinion1.ID,
		SenderID:   opinion1.SenderID,
		Opinion:    opinion1.Opinion,
		Name:       user1.Name,
		ProfileURL: user1.ProfileURL,
		CreatedAt:  opinion1.CreatedAt,
	}
	opinion2Summary := models.OpinionSummary{
		ID:         opinion2.ID,
		SenderID:   opinion2.SenderID,
		Opinion:    opinion2.Opinion,
		Name:       user2.Name,
		ProfileURL: user2.ProfileURL,
		CreatedAt:  opinion2.CreatedAt,
	}
	if err != nil {
		return nil, err
	}

	if opinion1Summary.CreatedAt.After(opinion2Summary.CreatedAt) {
		return []models.OpinionSummary{opinion2Summary, opinion1Summary}, nil

	} else {
		return []models.OpinionSummary{opinion1Summary, opinion2Summary}, nil
	}
}

func (s *matchService) deleteMatch(id int) error {

	err := repository.MatchRepo.Delete(id)
	if err != nil {
		return err
	}

	log.Printf("Deleted match: ")
	return nil
}
