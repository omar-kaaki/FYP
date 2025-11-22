package domain

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shim"
)

// GUIDMapping represents a mapping between external GUID and internal evidence ID
// Used on cold-chain for court anonymization
type GUIDMapping struct {
	GUID               string `json:"guid"`               // External GUID for court use
	InternalEvidenceID string `json:"internalEvidenceId"` // Internal evidence ID
	CreatedBy          string `json:"createdBy"`          // User who created mapping
	CreatedAt          string `json:"createdAt"`          // RFC3339 timestamp
	Description        string `json:"description,omitempty"`
}

// CreateGUIDMapping creates a new GUID mapping (cold-chain only)
func CreateGUIDMapping(stub shim.ChaincodeStubInterface, guid, internalEvidenceID, createdBy, description string) error {
	// Check if GUID already exists
	key := fmt.Sprintf("GUIDMAP:%s", guid)
	existing, err := stub.GetState(key)
	if err != nil {
		return fmt.Errorf("failed to check GUID mapping existence: %v", err)
	}
	if existing != nil {
		return fmt.Errorf("GUID mapping with GUID '%s' already exists", guid)
	}

	// Verify evidence exists
	_, err = GetEvidence(stub, internalEvidenceID)
	if err != nil {
		return fmt.Errorf("evidence not found: %v", err)
	}

	// Create GUID mapping
	now := time.Now().UTC().Format(time.RFC3339)
	guidMapping := GUIDMapping{
		GUID:               guid,
		InternalEvidenceID: internalEvidenceID,
		CreatedBy:          createdBy,
		CreatedAt:          now,
		Description:        description,
	}

	// Marshal to JSON
	guidMappingJSON, err := json.Marshal(guidMapping)
	if err != nil {
		return fmt.Errorf("failed to marshal GUID mapping: %v", err)
	}

	// Save to state
	if err := stub.PutState(key, guidMappingJSON); err != nil {
		return fmt.Errorf("failed to save GUID mapping: %v", err)
	}

	return nil
}

// ResolveGUID resolves a GUID to internal evidence ID (cold-chain only)
func ResolveGUID(stub shim.ChaincodeStubInterface, guid string) (*GUIDMapping, error) {
	key := fmt.Sprintf("GUIDMAP:%s", guid)

	guidMappingJSON, err := stub.GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to get GUID mapping: %v", err)
	}

	if guidMappingJSON == nil {
		return nil, fmt.Errorf("GUID mapping not found: %s", guid)
	}

	var guidMapping GUIDMapping
	if err := json.Unmarshal(guidMappingJSON, &guidMapping); err != nil {
		return nil, fmt.Errorf("failed to unmarshal GUID mapping: %v", err)
	}

	return &guidMapping, nil
}

// GetEvidenceByGUID retrieves evidence using external GUID (cold-chain only)
func GetEvidenceByGUID(stub shim.ChaincodeStubInterface, guid string) (*Evidence, error) {
	// Resolve GUID to evidence ID
	guidMapping, err := ResolveGUID(stub, guid)
	if err != nil {
		return nil, err
	}

	// Get evidence
	evidence, err := GetEvidence(stub, guidMapping.InternalEvidenceID)
	if err != nil {
		return nil, err
	}

	return evidence, nil
}

// ListGUIDMappings returns all GUID mappings (cold-chain only)
func ListGUIDMappings(stub shim.ChaincodeStubInterface) ([]GUIDMapping, error) {
	// Query by prefix
	iterator, err := stub.GetStateByRange("GUIDMAP:", "GUIDMAP:~")
	if err != nil {
		return nil, fmt.Errorf("failed to get GUID mappings iterator: %v", err)
	}
	defer iterator.Close()

	var guidMappings []GUIDMapping
	for iterator.HasNext() {
		kv, err := iterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate GUID mappings: %v", err)
		}

		var guidMapping GUIDMapping
		if err := json.Unmarshal(kv.Value, &guidMapping); err != nil {
			continue // Skip invalid records
		}

		guidMappings = append(guidMappings, guidMapping)
	}

	return guidMappings, nil
}

// DeleteGUIDMapping deletes a GUID mapping (admin only)
func DeleteGUIDMapping(stub shim.ChaincodeStubInterface, guid string) error {
	key := fmt.Sprintf("GUIDMAP:%s", guid)

	// Check if exists
	existing, err := stub.GetState(key)
	if err != nil {
		return fmt.Errorf("failed to check GUID mapping: %v", err)
	}
	if existing == nil {
		return fmt.Errorf("GUID mapping not found: %s", guid)
	}

	// Delete
	if err := stub.DelState(key); err != nil {
		return fmt.Errorf("failed to delete GUID mapping: %v", err)
	}

	return nil
}

// UpdateGUIDMapping updates the description of a GUID mapping
func UpdateGUIDMapping(stub shim.ChaincodeStubInterface, guid, description string) error {
	// Get existing mapping
	guidMapping, err := ResolveGUID(stub, guid)
	if err != nil {
		return err
	}

	// Update description
	guidMapping.Description = description

	// Marshal to JSON
	guidMappingJSON, err := json.Marshal(guidMapping)
	if err != nil {
		return fmt.Errorf("failed to marshal GUID mapping: %v", err)
	}

	// Save to state
	key := fmt.Sprintf("GUIDMAP:%s", guid)
	if err := stub.PutState(key, guidMappingJSON); err != nil {
		return fmt.Errorf("failed to update GUID mapping: %v", err)
	}

	return nil
}
