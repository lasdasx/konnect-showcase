package utils

import "time"

func AgeFromBirthday(birthday time.Time) int {
	now := time.Now().UTC()
	age := now.Year() - birthday.Year()

	// Has birthday happened yet this year?
	if now.Month() < birthday.Month() ||
		(now.Month() == birthday.Month() && now.Day() < birthday.Day()) {
		age--
	}

	return age
}
