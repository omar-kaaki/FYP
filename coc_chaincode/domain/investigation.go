package domain

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shim"
)

// InvestigationStatus represents the status of an investigation
type InvestigationStatus string

const (
	StatusOpen     InvestigationStatus = "open"
	StatusArchived InvestigationStatus = "archived"
)

// Investigation represents a forensic investigation
type Investigation struct {
	ID          string              `json:"id"`
	Title       string              `json:"title"`
	Description string              `json:"description"`
	Status      InvestigationStatus `json:"status"`
	CreatedBy   string              `json:"createdBy"`
	CreatedAt   string              `json:"createdAt"`
	UpdatedAt   string              `json:"updatedAt"`
	Channel     string              `json:"channel"` // "hot" or "cold"
}

// CreateInvestigation creates a new investigation
func CreateInvestigation(stub shim.ChaincodeStubInterface, id, title, description, createdBy, channel string) error {
	// Check if investigation already exists
	key := fmt.Sprintf("INVESTIGATION:%s", id)
	existing, err := stub.GetState(key)
	if err != nil {
		return fmt.Errorf("failed to check investigation existence: %v", err)
	}
	if existing != nil {
		return fmt.Errorf("investigation with ID '%s' already exists", id)
	}

	// Create investigation
	now := time.Now().UTC().Format(time.RFC3339)
	investigation := Investigation{
		ID:          id,
		Title:       title,
		Description: description,
		Status:      StatusOpen,
		CreatedBy:   createdBy,
		CreatedAt:   now,
		UpdatedAt:   now,
		Channel:     channel,
	}

	// Marshal to JSON
	investigationJSON, err := json.Marshal(investigation)
	if err != nil {
		return fmt.Errorf("failed to marshal investigation: %v", err)
	}

	// Save to state
	if err := stub.PutState(key, investigationJSON); err != nil {
		return fmt.Errorf("failed to save investigation: %v", err)
	}

	return nil
}

// GetInvestigation retrieves an investigation by ID
func GetInvestigation(stub shim.ChaincodeStubInterface, id string) (*Investigation, error) {
	key := fmt.Sprintf("INVESTIGATION:%s", id)

	investigationJSON, err := stub.GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to get investigation: %v", err)
	}

	if investigationJSON == nil {
		return nil, fmt.Errorf("investigation not found: %s", id)
	}

	var investigation Investigation
	if err := json.Unmarshal(investigationJSON, &investigation); err != nil {
		return nil, fmt.Errorf("failed to unmarshal investigation: %v", err)
	}

	return &investigation, nil
}

// UpdateInvestigation updates an existing investigation
func UpdateInvestigation(stub shim.ChaincodeStubInterface, id, title, description string) error {
	// Get existing investigation
	investigation, err := GetInvestigation(stub, id)
	if err != nil {
		return err
	}

	// Update fields
	if title != "" {
		investigation.Title = title
	}
	if description != "" {
		investigation.Description = description
	}
	investigation.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

	// Marshal to JSON
	investigationJSON, err := json.Marshal(investigation)
	if err != nil {
		return fmt.Errorf("failed to marshal investigation: %v", err)
	}

	// Save to state
	key := fmt.Sprintf("INVESTIGATION:%s", id)
	if err := stub.PutState(key, investigationJSON); err != nil {
		return fmt.Errorf("failed to update investigation: %v", err)
	}

	return nil
}

// ArchiveInvestigation archives an investigation (cold-chain only)
func ArchiveInvestigation(stub shim.ChaincodeStubInterface, id string) error {
	// Get existing investigation
	investigation, err := GetInvestigation(stub, id)
	if err != nil {
		return err
	}

	// Check if already archived
	if investigation.Status == StatusArchived {
		return fmt.Errorf("investigation '%s' is already archived", id)
	}

	// Update status
	investigation.Status = StatusArchived
	investigation.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

	// Marshal to JSON
	investigationJSON, err := json.Marshal(investigation)
	if err != nil {
		return fmt.Errorf("failed to marshal investigation: %v", err)
	}

	// Save to state
	key := fmt.Sprintf("INVESTIGATION:%s", id)
	if err := stub.PutState(key, investigationJSON); err != nil {
		return fmt.Errorf("failed to archive investigation: %v", err)
	}

	return nil
}

// ReopenInvestigation reopens an archived investigation (cold-chain only)
func ReopenInvestigation(stub shim.ChaincodeStubInterface, id string) error {
	// Get existing investigation
	investigation, err := GetInvestigation(stub, id)
	if err != nil {
		return err
	}

	// Check if not archived
	if investigation.Status != StatusArchived {
		return fmt.Errorf("investigation '%s' is not archived (status: %s)", id, investigation.Status)
	}

	// Update status
	investigation.Status = StatusOpen
	investigation.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

	// Marshal to JSON
	investigationJSON, err := json.Marshal(investigation)
	if err != nil {
		return fmt.Errorf("failed to marshal investigation: %v", err)
	}

	// Save to state
	key := fmt.Sprintf("INVESTIGATION:%s", id)
	if err := stub.PutState(key, investigationJSON); err != nil {
		return fmt.Errorf("failed to reopen investigation: %v", err)
	}

	return nil
}

// ListInvestigations returns all investigations
func ListInvestigations(stub shim.ChaincodeStubInterface) ([]Investigation, error) {
	// Query by prefix
	iterator, err := stub.GetStateByRange("INVESTIGATION:", "INVESTIGATION:~")
	if err != nil {
		return nil, fmt.Errorf("failed to get investigations iterator: %v", err)
	}
	defer iterator.Close()

	var investigations []Investigation
	for iterator.HasNext() {
		kv, err := iterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate investigations: %v", err)
		}

		var investigation Investigation
		if err := json.Unmarshal(kv.Value, &investigation); err != nil {
			continue // Skip invalid records
		}

		investigations = append(investigations, investigation)
	}

	return investigations, nil
}

// DeleteInvestigation deletes an investigation (admin only)
func DeleteInvestigation(stub shim.ChaincodeStubInterface, id string) error {
	key := fmt.Sprintf("INVESTIGATION:%s", id)

	// Check if exists
	existing, err := stub.GetState(key)
	if err != nil {
		return fmt.Errorf("failed to check investigation: %v", err)
	}
	if existing == nil {
		return fmt.Errorf("investigation not found: %s", id)
	}

	// Delete
	if err := stub.DelState(key); err != nil {
		return fmt.Errorf("failed to delete investigation: %v", err)
	}

	return nil
}
