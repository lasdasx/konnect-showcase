package models

import "time"

type RefreshToken struct {
	ID        int       `json:"id"`
	Token     string    `json:"token"`
	UserId    int       `json:"user_id"`
	ExpiresAt time.Time `json:"expires_at"`
}

type WsMessage struct {
	Type string `json:"type"`
	Data any    `json:"data"`
}

type RegisterRequest struct {
	Name string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"` // plain password from client
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"` // plain text from client
	Passcode string `json:"passcode"`
}

type Message struct {
	ID         int       `json:"id"`        // id
	ChatID     int       `json:"chat_id"`   // chat id
	SenderID   int       `json:"sender_id"` // sender id
	ReceiverID int       `json:"receiver_id"`
	Content    string    `json:"content"` // message content
	Time       time.Time `json:"time"`    // timestamp
	IsRead     bool      `json:"is_read"` // read status
}

type Chat struct {
	ID      int `json:"id"`       // id
	UserId1 int `json:"user1_id"` // name
	UserId2 int `json:"user2_id"` // gender
}

type ChatSummary struct {
	ID          int       `json:"id"`
	UserID      int       `json:"user_id"`
	Name        string    `json:"name"`
	ProfileURL  string    `json:"profile_url"`
	LastMessage string    `json:"last_message"`
	Read        bool      `json:"read"`
	Time        time.Time `json:"time"`
}

type Match struct {
	ID      int `json:"id"`       // id
	UserId1 int `json:"user1_id"` // name
	UserId2 int `json:"user2_id"` // gender
}
type MatchSummary struct {
	ID         int    `json:"id"`
	UserID     int    `json:"user_id"`
	Name       string `json:"name"`
	ProfileURL string `json:"profile_url"`
}
type User struct {
	ID                        int       `json:"id"`          // id
	Name                      string    `json:"name"`        // name
	Gender                    string    `json:"gender"`      // gender
	Birthday                  time.Time `json:"birthday"`    // birthday (date)
	ProfileURL                string    `json:"profile_url"` // profile_url
	ImagesURL                 []string  `json:"images_url"`  // images_url (array of strings)
	Bio                       string    `json:"bio"`         // bio (max 500 chars)
	Country                   string    `json:"country"`     // country
	Email                     string    `json:"email"`       // email
	PasswordHash              string    `json:"password_hash"`
	Onboarded                 bool      `json:"onboarded"`
	EmailVerified             bool      `json:"email_verified"`
	EmailVerificationPasscode string    `json:"email_verification_passcode"`
	EmailPasscodeCreatedAt    time.Time `json:"email_passcode_created_at"`
}

type UserSummary struct {
	ID   int    `json:"id"`   // id
	Name string `json:"name"` // name

	ProfileURL string `json:"profile_url"` // profile_url

}

type UserExploreSummary struct {
	ID         int      `json:"id"`
	Name       string   `json:"name"`
	ProfileURL string   `json:"profile_url"`
	Age        int      `json:"age"`
	ImagesUrl  []string `json:"images_url"`
	Bio        string   `json:"bio"`
	Country    string   `json:"country"`
}

type Opinion struct {
	ID         int       `json:"id"`          // opinion ID
	SenderID   int       `json:"sender_id"`   // user who sends the opinion
	ReceiverID int       `json:"receiver_id"` // user who receives the opinion
	Opinion    string    `json:"opinion"`     // opinion text (max 500 chars)
	CreatedAt  time.Time `json:"created_at"`  // timestamp
}

type OpinionSummary struct {
	ID         int       `json:"id"`        // opinion ID
	SenderID   int       `json:"sender_id"` // user who sends the opinion
	Opinion    string    `json:"opinion"`   // opinion text (max 500 chars)
	Name       string    `json:"name"`
	ProfileURL string    `json:"profile_url"`
	CreatedAt  time.Time `json:"created_at"`
}

type Skip struct {
	ID        int `json:"id"`      // opinion ID
	SkipperID int `json:"skipper"` // user who sends the opinion
	SkippedID int `json:"skipped"` // user who receives the opinion
}
