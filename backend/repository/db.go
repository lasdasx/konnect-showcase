package repository

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

var DB *pgxpool.Pool

func InitDB() {
	err := godotenv.Load()
	if err != nil {
		// If it fails here, the path to the .env might be wrong relative to where you run the app
		log.Fatalf("Error loading .env file: %v", err)
	}

	connStr := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s&sslrootcert=%s",
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_NAME"),
		os.Getenv("SSL_MODE"), // verify-full
		os.Getenv("SSL_CERT"), // global-bundle.pem
	)
	DB, err = pgxpool.New(context.Background(), connStr)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}

	// Test connection
	err = DB.Ping(context.Background())
	if err != nil {
		log.Fatalf("Unable to ping database: %v\n", err)
	}

	log.Println("Connected to PostgreSQL via pgx!")

	stats := DB.Stat()
	fmt.Printf("Total Conns: %d, Acquired: %d, Idle: %d, Max: %d\n",
		stats.TotalConns(), stats.AcquiredConns(), stats.IdleConns(), stats.MaxConns())

	// Automatically run SQL scripts

	//clean and populate db
	// runSQLFile("../database/createTables.sql")
	// runSQLFile("../database/populateDb.sql")

	// runSQLFile("../database/insertRows.sql")
}

func runSQLFile(path string) {
	content, err := os.ReadFile(path)
	if err != nil {
		log.Fatalf("Failed to read SQL file %s: %v", path, err)
	}

	_, err = DB.Exec(context.Background(), string(content))
	if err != nil {
		log.Fatalf("Failed to execute SQL file %s: %v", path, err)
	}

	log.Printf("Executed %s successfully!", path)
}
