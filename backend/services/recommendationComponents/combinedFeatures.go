package components

var CombinedFeatures = &combinedFeatures{}

type combinedFeatures struct{}

// remove these

func (*combinedFeatures) CalculateBioSimilarityScore(userId int, profileID int) float64 {
	return 0
}

func (*combinedFeatures) CalculatePredictionScore(userId int, profileID int) float64 {
	return 0
}

//colaborative filtering
