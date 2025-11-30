package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sort"
	"strings"
	"sync"
	"time"
)

type PlayerData struct {
	PlayerName  string    `json:"playername"`
	WorldVisits int       `json:"worldvisits"`
	Wins        int       `json:"wins"`
	Losses      int       `json:"losses"`
	LastPlayed  time.Time `json:"lastplayed"`
}

// Public version without sensitive data
type PublicPlayerData struct {
	PlayerName string `json:"playername"`
	Wins       int    `json:"wins"`
	Losses     int    `json:"losses"`
}

type Response struct {
	Message string `json:"message"`
}

type Top10Response struct {
	Players []PublicPlayerData `json:"players"`
}

type PlayersResponse struct {
	Players []PublicPlayerData `json:"players"`
}

type RegisterRequest struct {
	ClientKey  string `json:"clientkey"`
	PlayerName string `json:"playername"`
}

type PlayerActionRequest struct {
	ClientKey  string `json:"clientkey"`
	PlayerName string `json:"playername"`
}

type Top10Request struct {
	ClientKey string `json:"clientkey"`
}

// Hardcoded client key for authentication
const CLIENT_KEY = "VRC_DOTBOXES_SECRET_KEY_2025"

// In-memory storage with mutex for thread safety
var (
	playerDB = make(map[string]*PlayerData)
	dbMutex  = sync.RWMutex{}
)

// Helper function to decode base64 JSON and validate client key
func decodeAndValidate(path string, target interface{}) error {
	// Decode base64
	decodedBytes, err := base64.StdEncoding.DecodeString(path)
	if err != nil {
		return fmt.Errorf("invalid base64 encoding")
	}

	// Parse JSON
	err = json.Unmarshal(decodedBytes, target)
	if err != nil {
		return fmt.Errorf("invalid JSON")
	}

	return nil
}

// Helper function to validate client key from request struct
func validateClientKey(request interface{}) bool {
	switch req := request.(type) {
	case *RegisterRequest:
		return req.ClientKey == CLIENT_KEY
	case *PlayerActionRequest:
		return req.ClientKey == CLIENT_KEY
	case *Top10Request:
		return req.ClientKey == CLIENT_KEY
	default:
		return false
	}
}

// Helper function to convert internal PlayerData to public format
func toPublicPlayerData(player *PlayerData) PublicPlayerData {
	return PublicPlayerData{
		PlayerName: player.PlayerName,
		Wins:       player.Wins,
		Losses:     player.Losses,
	}
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	// Set content type to JSON
	w.Header().Set("Content-Type", "application/json")

	// Create response
	response := Response{
		Message: "Hello, World!",
	}

	// Encode to JSON and send
	json.NewEncoder(w).Encode(response)
}

func top10Handler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Extract base64 encoded request from URL path
	path := strings.TrimPrefix(r.URL.Path, "/data/top10/")
	if path == "" {
		http.Error(w, "Missing request data", http.StatusBadRequest)
		return
	}

	// Decode and validate request
	var request Top10Request
	err := decodeAndValidate(path, &request)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validate client key
	if !validateClientKey(&request) {
		http.Error(w, "Invalid client key", http.StatusUnauthorized)
		return
	}

	dbMutex.RLock()
	defer dbMutex.RUnlock()

	// Convert map to slice for sorting
	players := make([]PlayerData, 0, len(playerDB))
	for _, player := range playerDB {
		players = append(players, *player)
	}

	// Sort by wins (descending)
	sort.Slice(players, func(i, j int) bool {
		return players[i].Wins > players[j].Wins
	})

	// Take top 10 and convert to public format
	publicPlayers := make([]PublicPlayerData, 0, 10)
	limit := len(players)
	if limit > 10 {
		limit = 10
	}

	for i := 0; i < limit; i++ {
		publicPlayers = append(publicPlayers, toPublicPlayerData(&players[i]))
	}

	response := Top10Response{
		Players: publicPlayers,
	}

	json.NewEncoder(w).Encode(response)
}

type PlayersRequest struct {
	ClientKey   string   `json:"clientkey"`
	PlayerNames []string `json:"playernames"`
}

func playersHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Extract base64 encoded request from URL path
	path := strings.TrimPrefix(r.URL.Path, "/data/players/")
	if path == "" {
		http.Error(w, "Missing request data", http.StatusBadRequest)
		return
	}

	// Decode and validate request
	var request PlayersRequest
	err := decodeAndValidate(path, &request)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validate client key
	if request.ClientKey != CLIENT_KEY {
		http.Error(w, "Invalid client key", http.StatusUnauthorized)
		return
	}

	// Limit to 20 players
	playerNames := request.PlayerNames
	if len(playerNames) > 20 {
		playerNames = playerNames[:20]
	}

	dbMutex.RLock()
	defer dbMutex.RUnlock()

	// Get player data and convert to public format
	publicPlayers := make([]PublicPlayerData, 0, len(playerNames))
	for _, name := range playerNames {
		if player, exists := playerDB[name]; exists {
			publicPlayers = append(publicPlayers, toPublicPlayerData(player))
		} else {
			// Return player with 0 stats if not found
			publicPlayers = append(publicPlayers, PublicPlayerData{
				PlayerName: name,
				Wins:       0,
				Losses:     0,
			})
		}
	}

	response := PlayersResponse{
		Players: publicPlayers,
	}

	json.NewEncoder(w).Encode(response)
}

func registerHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Extract base64 encoded request from URL path
	path := strings.TrimPrefix(r.URL.Path, "/player/register/")
	if path == "" {
		http.Error(w, "Missing request data", http.StatusBadRequest)
		return
	}

	// Decode and validate request
	var request RegisterRequest
	err := decodeAndValidate(path, &request)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validate client key
	if !validateClientKey(&request) {
		http.Error(w, "Invalid client key", http.StatusUnauthorized)
		return
	}

	dbMutex.Lock()
	defer dbMutex.Unlock()

	// Get or create player
	player, exists := playerDB[request.PlayerName]
	if !exists {
		player = &PlayerData{
			PlayerName:  request.PlayerName,
			WorldVisits: 0,
			Wins:        0,
			Losses:      0,
			LastPlayed:  time.Now(),
		}
		playerDB[request.PlayerName] = player
	}

	// Increment visits and update last played
	player.WorldVisits++
	player.LastPlayed = time.Now()

	response := Response{
		Message: fmt.Sprintf("Player %s registered. Visits: %d", request.PlayerName, player.WorldVisits),
	}

	json.NewEncoder(w).Encode(response)
}

func addWinHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Extract base64 encoded request from URL path
	path := strings.TrimPrefix(r.URL.Path, "/player/addwin/")
	if path == "" {
		http.Error(w, "Missing request data", http.StatusBadRequest)
		return
	}

	// Decode and validate request
	var request PlayerActionRequest
	err := decodeAndValidate(path, &request)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validate client key
	if !validateClientKey(&request) {
		http.Error(w, "Invalid client key", http.StatusUnauthorized)
		return
	}

	dbMutex.Lock()
	defer dbMutex.Unlock()

	player, exists := playerDB[request.PlayerName]
	if !exists {
		http.Error(w, "Player not found", http.StatusNotFound)
		return
	}

	player.Wins++

	response := Response{
		Message: fmt.Sprintf("Win added for %s. Total wins: %d", request.PlayerName, player.Wins),
	}

	json.NewEncoder(w).Encode(response)
}

func addLossHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Extract base64 encoded request from URL path
	path := strings.TrimPrefix(r.URL.Path, "/player/addloss/")
	if path == "" {
		http.Error(w, "Missing request data", http.StatusBadRequest)
		return
	}

	// Decode and validate request
	var request PlayerActionRequest
	err := decodeAndValidate(path, &request)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validate client key
	if !validateClientKey(&request) {
		http.Error(w, "Invalid client key", http.StatusUnauthorized)
		return
	}

	dbMutex.Lock()
	defer dbMutex.Unlock()

	player, exists := playerDB[request.PlayerName]
	if !exists {
		http.Error(w, "Player not found", http.StatusNotFound)
		return
	}

	player.Losses++

	response := Response{
		Message: fmt.Sprintf("Loss added for %s. Total losses: %d", request.PlayerName, player.Losses),
	}

	json.NewEncoder(w).Encode(response)
}

// Helper function to initialize some sample data
func initSampleData() {
	dbMutex.Lock()
	defer dbMutex.Unlock()

	now := time.Now()
	samplePlayers := []PlayerData{
		{"Alice", 15, 8, 2, now.AddDate(0, 0, -1)},
		{"Bob", 12, 6, 4, now.AddDate(0, 0, -2)},
		{"Charlie", 20, 12, 3, now.AddDate(0, 0, -1)},
		{"Diana", 8, 4, 1, now.AddDate(0, 0, -3)},
		{"Eve", 25, 15, 5, now},
		{"Frank", 18, 9, 6, now.AddDate(0, 0, -1)},
		{"Grace", 10, 7, 2, now.AddDate(0, 0, -2)},
		{"Henry", 22, 11, 7, now.AddDate(0, 0, -1)},
		{"Ivy", 14, 5, 3, now.AddDate(0, 0, -4)},
		{"Jack", 16, 10, 4, now.AddDate(0, 0, -1)},
		{"Kate", 30, 18, 8, now},
		{"Liam", 9, 3, 2, now.AddDate(0, 0, -5)},
	}

	for _, player := range samplePlayers {
		playerDB[player.PlayerName] = &PlayerData{
			PlayerName:  player.PlayerName,
			WorldVisits: player.WorldVisits,
			Wins:        player.Wins,
			Losses:      player.Losses,
			LastPlayed:  player.LastPlayed,
		}
	}
}

func main() {
	// Initialize sample data
	initSampleData()

	// Register handlers
	http.HandleFunc("/", helloHandler)
	http.HandleFunc("/data/top10/", top10Handler)
	http.HandleFunc("/data/players/", playersHandler)
	http.HandleFunc("/player/register/", registerHandler)
	http.HandleFunc("/player/addwin/", addWinHandler)
	http.HandleFunc("/player/addloss/", addLossHandler)

	// Start server
	port := "8080"
	fmt.Printf("Server starting on http://localhost:%s\n", port)
	fmt.Printf("Client Key: %s\n", CLIENT_KEY)
	fmt.Println("Endpoints (all require base64 encoded JSON with clientkey):")
	fmt.Println("  GET / - Hello World (no auth required)")
	fmt.Println("  GET /data/top10/{base64_json} - Top 10 players by wins")
	fmt.Println("  GET /data/players/{base64_json} - Get specific players")
	fmt.Println("  GET /player/register/{base64_json} - Register/visit player")
	fmt.Println("  GET /player/addwin/{base64_json} - Add win to player")
	fmt.Println("  GET /player/addloss/{base64_json} - Add loss to player")
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
