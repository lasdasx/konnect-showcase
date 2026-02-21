package services

import (
	"backend/models"
	"backend/repository"
	"context"

	"golang.org/x/sync/errgroup"
)

var SwipeService = &swipeService{}

type swipeService struct{}

func (s *swipeService) AddOpinion(opinion models.Opinion) error {

	exists, err := repository.OpinionRepo.AlreadyExisting(opinion.ReceiverID, opinion.SenderID)
	if err != nil {
		return err // or handle it properly
	}

	if exists {
		// condition when it already exists
		matchId, err := repository.MatchRepo.Create(models.Match{
			UserId1: opinion.ReceiverID,
			UserId2: opinion.SenderID,
		})

		sender, err := UserService.GetSummaryByID(opinion.SenderID)

		receiver, err := UserService.GetSummaryByID(opinion.ReceiverID)
		if err != nil {
			return err
		}

		WsService.SendToClient(sender.ID, models.WsMessage{
			Type: "matchesUpdate",
			Data: models.MatchSummary{
				ID:         matchId,
				UserID:     receiver.ID,
				Name:       receiver.Name,
				ProfileURL: receiver.ProfileURL,
			},
		})

		WsService.SendToClient(receiver.ID, models.WsMessage{
			Type: "matchesUpdate",
			Data: models.MatchSummary{
				ID:         matchId,
				UserID:     sender.ID,
				Name:       sender.Name,
				ProfileURL: sender.ProfileURL,
			},
		})

		err = NotificationService.SendNotification(opinion.ReceiverID, "New Match!", "Chat with "+sender.Name, map[string]string{"screen": "chat"}, false)
	} else {
		err = NotificationService.SendNotification(opinion.ReceiverID, "New First Message!", "See what they had to say", map[string]string{"screen": "opinions"}, false)
	}

	opinionSummary, err := repository.OpinionRepo.Create(opinion)
	if err != nil {
		return err
	}
	if opinionSummary.ProfileURL != "" {
		signed, err := UserService.GetImageUrl(context.Background(), opinionSummary.ProfileURL)
		if err == nil {
			opinionSummary.ProfileURL = signed
		}

	}

	WsService.SendToClient(opinion.ReceiverID, models.WsMessage{
		Type: "opinionsUpdate",
		Data: opinionSummary,
	})

	return nil
}

func (s *swipeService) GetOpinionsByUser(userID int) ([]models.OpinionSummary, error) {
	opinions, err := repository.OpinionRepo.GetReceivedByUserID(userID)
	if err != nil {
		return nil, err
	}

	var g errgroup.Group
	opinionSummaries := make([]models.OpinionSummary, len(opinions))

	for i, opinion := range opinions {
		i := i
		opinion := opinion // capture loop variables

		g.Go(func() error {
			senderId := opinion.SenderID
			u, err := UserService.GetSummaryByID(senderId)
			if err != nil {
				return err
			}

			opinionSummaries[i] = models.OpinionSummary{
				ID:         opinion.ID,
				SenderID:   opinion.SenderID,
				Opinion:    opinion.Opinion,
				Name:       u.Name,
				ProfileURL: u.ProfileURL,
				CreatedAt:  opinion.CreatedAt,
			}
			return nil
		})

	}
	if err := g.Wait(); err != nil {
		return nil, err
	}
	return opinionSummaries, nil

}
