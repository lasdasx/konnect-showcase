package services

import (
	"backend/models"
	"backend/repository"
	"log"

	"golang.org/x/sync/errgroup"
)

var ChatService = &chatService{}

type chatService struct{}

func (s *chatService) SetRead(chatId int) error {

	message, err := repository.MessageRepo.GetLastMessage(chatId)

	if err != nil {
		return err
	}
	return repository.MessageRepo.SetRead(message.ID)
}

func (s *chatService) GetChatsForUser(userID int) ([]models.ChatSummary, error) {
	chats, err := repository.ChatRepo.GetByUserID(userID)
	if err != nil {
		log.Println(err.Error())

		return nil, err
	}

	summaries := make([]models.ChatSummary, len(chats))
	var g errgroup.Group

	for i, chat := range chats {
		i := i
		chat := chat // capture loop variables

		g.Go(func() error {
			// Determine the "other" user
			var otherID int
			if chat.UserId1 == userID {
				otherID = chat.UserId2
			} else {
				otherID = chat.UserId1
			}

			var user models.UserSummary
			var message models.Message
			var innerG errgroup.Group

			// Fetch user summary
			innerG.Go(func() error {
				u, err := UserService.GetSummaryByID(otherID)
				if err != nil {
					return err
				}
				user = u
				return nil
			})

			// Fetch last message
			innerG.Go(func() error {
				m, err := repository.MessageRepo.GetLastMessage(chat.ID)
				if err != nil {
					return err
				}
				message = m
				return nil
			})

			// Wait for both calls to finish
			if err := innerG.Wait(); err != nil {
				return err
			}

			// log.Log.printlnln("senderid: ", message.SenderID, " userID: ", userID, "message: ", message.Content)
			summaries[i] = models.ChatSummary{
				ID:          chat.ID,
				UserID:      otherID,
				Name:        user.Name,
				ProfileURL:  user.ProfileURL,
				LastMessage: message.Content,
				Read:        message.SenderID == userID || message.IsRead,
				Time:        message.Time,
			}
			return nil
		})
	}

	// Wait for all chats to finish
	if err := g.Wait(); err != nil {
		return nil, err
	}

	return summaries, nil
}

func (s *chatService) GetMessagesForChat(chatID int) ([]models.Message, error) {
	return repository.MessageRepo.GetByChatID(chatID)
}

func (s *chatService) SendMessage(message *models.Message) error {

	exists, err := repository.ChatRepo.GetByID(message.ChatID)
	if err != nil {
		log.Println("1111")
		log.Println(err.Error())
		return err
	}
	sender, err := UserService.GetSummaryByID(message.SenderID)
	if err != nil {
		log.Println(err.Error())
		return err
	}
	if !exists { //new chat

		//////////////////////also prepei na kanei remove to match kai me ws k me db
		chatId, err := repository.ChatRepo.Create(models.Chat{
			ID:      message.ChatID,
			UserId1: message.SenderID,
			UserId2: message.ReceiverID,
		})
		if err != nil {
			log.Println("2222")
			log.Println(err.Error())

			return err
		}

		err = repository.MatchRepo.Delete(message.ChatID)
		if err != nil {
			log.Println("3333")
			log.Println(err.Error())

			return err
		}

		log.Printf("Deleted match: %d ", message.ChatID)

		err = repository.MessageRepo.Create(message)
		if err != nil {
			log.Println(err.Error())

			return err
		}

		receiver, err := UserService.GetSummaryByID(message.ReceiverID)

		if err != nil {
			log.Println(err.Error())

			return err
		}
		WsService.SendToClient(message.ReceiverID, models.WsMessage{
			Type: "newConversationUpdate",
			Data: models.ChatSummary{
				ID:          chatId,
				UserID:      message.SenderID,
				Name:        sender.Name,
				ProfileURL:  sender.ProfileURL,
				LastMessage: message.Content,
				Read:        false,
				Time:        message.Time,
			},
		})

		WsService.SendToClient(message.ReceiverID, models.WsMessage{
			Type: "removeMatch",
			Data: map[string]interface{}{
				"match_id": message.ChatID,
			},
		})

		WsService.SendToClient(message.SenderID, models.WsMessage{ //////////////isos proairetiko
			Type: "removeMatch",
			Data: map[string]interface{}{
				"match_id": message.ChatID,
			},
		})
		WsService.SendToClient(message.SenderID, models.WsMessage{ //////////////////isos proairetiko
			Type: "newConversationUpdate",
			Data: models.ChatSummary{
				ID:          chatId,
				UserID:      message.ReceiverID,
				Name:        receiver.Name,
				ProfileURL:  receiver.ProfileURL,
				LastMessage: message.Content,
				Read:        true,
				Time:        message.Time,
			},
		})
	} else {

		err = repository.MessageRepo.Create(message)
		if err != nil {
			log.Println(err.Error())

			return err
		}

		WsService.SendToClient(message.ReceiverID, models.WsMessage{
			Type: "newMessageUpdate",
			Data: message,
		})

		///
	}
	err = NotificationService.SendNotification(message.ReceiverID, "New Message!", "New message from "+sender.Name, map[string]string{"screen": "chat"}, false)
	if err != nil {
		return err
	}
	return nil
}
