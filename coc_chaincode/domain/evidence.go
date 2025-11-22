package domain

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shim"
)

// EvidenceMeta holds metadata about evidence
type EvidenceMeta struct {
	Type      string `json:"type"`               // "disk image", "memory dump", "document", etc.
	SizeBytes int64  `json:"sizeBytes"`          // File size in bytes
	Notes     string `json:"notes,omitempty"`    // Optional notes
	FileName  string `json:"fileName,omitempty"` // Original filename
}

// Evidence represents a piece of digital evidence
type Evidence struct {
	ID               string       `json:"id"`
	InvestigationID  string       `json:"investigationId"`
	Hash             string       `json:"hash"`             // SHA256 hash
	IPFSCid          string       `json:"ipfsCid"`          // IPFS Content Identifier
	CreatedBy        string       `json:"createdBy"`        // User who added evidence
	CreatedAt        string       `json:"createdAt"`        // RFC3339 timestamp
	Channel          string       `json:"channel"`          // "hot" or "cold"
	Meta             EvidenceMeta `json:"meta"`             // Metadata
	ChainOfCustody   []Custody    `json:"chainOfCustody"`   // Custody trail
}

// Custody represents a chain of custody event
type Custody struct {
	Timestamp   string `json:"timestamp"` // RFC3339
	Action      string `json:"action"`    // "collected", "transferred", "analyzed", "stored"
	Custodian   string `json:"custodian"` // User performing action
	Location    string `json:"location,omitempty"`
	Description string `json:"description,omitempty"`
}

// AddEvidence creates a new evidence record
func AddEvidence(stub shim.ChaincodeStubInterface, id, investigationID, hash, ipfsCid, createdBy, channel string, meta EvidenceMeta) error {
	// Check if evidence already exists
	key := fmt.Sprintf("EVIDENCE:%s", id)
	existing, err := stub.GetState(key)
	if err != nil {
		return fmt.Errorf("failed to check evidence existence: %v", err)
	}
	if existing != nil {
		return fmt.Errorf("evidence with ID '%s' already exists", id)
	}

	// Verify investigation exists
	_, err = GetInvestigation(stub, investigationID)
	if err != nil {
		return fmt.Errorf("investigation not found: %v", err)
	}

	// Create initial custody event
	now := time.Now().UTC().Format(time.RFC3339)
	initialCustody := Custody{
		Timestamp:   now,
		Action:      "collected",
		Custodian:   createdBy,
		Description: "Evidence added to blockchain",
	}

	// Create evidence
	evidence := Evidence{
		ID:              id,
		InvestigationID: investigationID,
		Hash:            hash,
		IPFSCid:         ipfsCid,
		CreatedBy:       createdBy,
		CreatedAt:       now,
		Channel:         channel,
		Meta:            meta,
		ChainOfCustody:  []Custody{initialCustody},
	}

	// Marshal to JSON
	evidenceJSON, err := json.Marshal(evidence)
	if err != nil {
		return fmt.Errorf("failed to marshal evidence: %v", err)
	}

	// Save to state
	if err := stub.PutState(key, evidenceJSON); err != nil {
		return fmt.Errorf("failed to save evidence: %v", err)
	}

	return nil
}

// GetEvidence retrieves an evidence record by ID
func GetEvidence(stub shim.ChaincodeStubInterface, id string) (*Evidence, error) {
	key := fmt.Sprintf("EVIDENCE:%s", id)

	evidenceJSON, err := stub.GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to get evidence: %v", err)
	}

	if evidenceJSON == nil {
		return nil, fmt.Errorf("evidence not found: %s", id)
	}

	var evidence Evidence
	if err := json.Unmarshal(evidenceJSON, &evidence); err != nil {
		return nil, fmt.Errorf("failed to unmarshal evidence: %v", err)
	}

	return &evidence, nil
}

// AddCustodyEvent adds a chain of custody event to evidence
func AddCustodyEvent(stub shim.ChaincodeStubInterface, evidenceID, action, custodian, location, description string) error {
	// Get existing evidence
	evidence, err := GetEvidence(stub, evidenceID)
	if err != nil {
		return err
	}

	// Create custody event
	custodyEvent := Custody{
		Timestamp:   time.Now().UTC().Format(time.RFC3339),
		Action:      action,
		Custodian:   custodian,
		Location:    location,
		Description: description,
	}

	// Append to chain of custody
	evidence.ChainOfCustody = append(evidence.ChainOfCustody, custodyEvent)

	// Marshal to JSON
	evidenceJSON, err := json.Marshal(evidence)
	if err != nil {
		return fmt.Errorf("failed to marshal evidence: %v", err)
	}

	// Save to state
	key := fmt.Sprintf("EVIDENCE:%s", evidenceID)
	if err := stub.PutState(key, evidenceJSON); err != nil {
		return fmt.Errorf("failed to update evidence: %v", err)
	}

	return nil
}

// ListEvidence returns all evidence records
func ListEvidence(stub shim.ChaincodeStubInterface) ([]Evidence, error) {
	// Query by prefix
	iterator, err := stub.GetStateByRange("EVIDENCE:", "EVIDENCE:~")
	if err != nil {
		return nil, fmt.Errorf("failed to get evidence iterator: %v", err)
	}
	defer iterator.Close()

	var evidenceList []Evidence
	for iterator.HasNext() {
		kv, err := iterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate evidence: %v", err)
		}

		var evidence Evidence
		if err := json.Unmarshal(kv.Value, &evidence); err != nil {
			continue // Skip invalid records
		}

		evidenceList = append(evidenceList, evidence)
	}

	return evidenceList, nil
}

// ListEvidenceByInvestigation returns all evidence for an investigation
func ListEvidenceByInvestigation(stub shim.ChaincodeStubInterface, investigationID string) ([]Evidence, error) {
	// Get all evidence
	allEvidence, err := ListEvidence(stub)
	if err != nil {
		return nil, err
	}

	// Filter by investigation ID
	var filteredEvidence []Evidence
	for _, evidence := range allEvidence {
		if evidence.InvestigationID == investigationID {
			filteredEvidence = append(filteredEvidence, evidence)
		}
	}

	return filteredEvidence, nil
}

// DeleteEvidence deletes an evidence record (admin only)
func DeleteEvidence(stub shim.ChaincodeStubInterface, id string) error {
	key := fmt.Sprintf("EVIDENCE:%s", id)

	// Check if exists
	existing, err := stub.GetState(key)
	if err != nil {
		return fmt.Errorf("failed to check evidence: %v", err)
	}
	if existing == nil {
		return fmt.Errorf("evidence not found: %s", id)
	}

	// Delete
	if err := stub.DelState(key); err != nil {
		return fmt.Errorf("failed to delete evidence: %v", err)
	}

	return nil
}

// VerifyEvidenceHash verifies the hash of evidence against provided hash
func VerifyEvidenceHash(stub shim.ChaincodeStubInterface, evidenceID, providedHash string) (bool, error) {
	evidence, err := GetEvidence(stub, evidenceID)
	if err != nil {
		return false, err
	}

	return evidence.Hash == providedHash, nil
}
