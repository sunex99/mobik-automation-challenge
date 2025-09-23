package main

import (
	"database/sql"
	"fmt"
	"net/http"
	"os"

	_ "github.com/lib/pq" // PostgreSQL driver
)

var db *sql.DB

// getenv retrieves the value of an environment variable or returns a fallback value if the variable is not set.
func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func init() {
	// Retrieve database connection details from environment variables with fallbacks.
	dbHost := getenv("DB_HOST", "db")
	dbPort := getenv("DB_PORT", "5432")
	dbUser := getenv("DB_USER", "postgres")
	dbPass := getenv("DB_PASS", "example")
	dbName := getenv("DB_NAME", "exampledb")

	// Construct the PostgreSQL connection string.
	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPass, dbName)

	var err error
	// Open a connection to the PostgreSQL database.
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		panic(fmt.Sprintf("Failed to connect to database: %v", err))
	}
}

// healthCheckHandler responds with a 200 OK status for health checks.
func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "OK")
}

// helloHandler responds to requests to the /api/hello endpoint.
func helloHandler(w http.ResponseWriter, r *http.Request) {
	// Check if the database connection is alive.
	if err := db.Ping(); err != nil {
		http.Error(w, fmt.Sprintf("Database error: %v", err), http.StatusInternalServerError)
		return
	}
	fmt.Fprintln(w, "Hello from Go backend (DB OK)")
}

func main() {
	// Define HTTP handlers for different endpoints.
	http.HandleFunc("/api/hello", helloHandler)
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Backend root. Try /api/hello")
	})
	http.HandleFunc("/health", healthCheckHandler)

	// Start the HTTP server on port 5000.
	http.ListenAndServe(":5000", nil)
}
