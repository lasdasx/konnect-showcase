package config

import (
	"context"
	"log"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// InitS3Client initializes the AWS SDK v2 configuration
func InitS3Client() *s3.Client {
	// LoadDefaultConfig reads the environment variables mentioned above
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}

	// Create and return the S3 client
	return s3.NewFromConfig(cfg)
}
