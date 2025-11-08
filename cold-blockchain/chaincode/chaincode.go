package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// DFIRChaincode - Public chaincode for evidence management
type DFIRChaincode struct {
	contractapi.Contract
}

// PRVConfig stores PRV verification keys and measurements
type PRVConfig struct {
	PublicKey  string `json:"public_key"`
	MREnclave  string `json:"mr_enclave"`
	MRSigner   string `json:"mr_signer"`
	UpdatedAt  int64  `json:"updated_at"`
}

// Evidence represents a piece of digital evidence
type Evidence struct {
	ID          string `json:"id"`
	CaseID      string `json:"case_id"`
	Type        string `json:"type"`
	Description string `json:"description"`
	Hash        string `json:"hash"`
	Location    string `json:"location"`
	Custodian   string `json:"custodian"`
	Timestamp   int64  `json:"timestamp"`
	Status      string `json:"status"`
	Metadata    string `json:"metadata"`
}

// CustodyTransfer records custody chain
type CustodyTransfer struct {
	EvidenceID    string `json:"evidence_id"`
	FromCustodian string `json:"from_custodian"`
	ToCustodian   string `json:"to_custodian"`
	Timestamp     int64  `json:"timestamp"`
	Reason        string `json:"reason"`
	Location      string `json:"location"`
	PermitHash    string `json:"permit_hash"`
}

// JWSPermit from PRV service
type JWSPermit struct {
	Header    string `json:"header"`
	Payload   string `json:"payload"`
	Signature string `json:"signature"`
}

// PermitPayload decoded from JWS
type PermitPayload struct {
	Sub       string `json:"sub"`
	Action    string `json:"action"`
	Resource  string `json:"resource"`
	Clearance int    `json:"clearance"`
	Decision  string `json:"decision"`
	Timestamp int64  `json:"timestamp"`
	Nonce     string `json:"nonce"`
	MREnclave string `json:"mrenclave"`
}

// InitLedger initializes the ledger with PRV configuration
func (cc *DFIRChaincode) InitLedger(ctx contractapi.TransactionContextInterface,
	publicKeyHex string, mrenclaveHex string, mrsignerHex string) error {

	config := PRVConfig{
		PublicKey: publicKeyHex,
		MREnclave: mrenclaveHex,
		MRSigner:  mrsignerHex,
		UpdatedAt: time.Now().Unix(),
	}

	configJSON, err := json.Marshal(config)
	if err != nil {
		return fmt.Errorf("failed to marshal config: %v", err)
	}

	err = ctx.GetStub().PutState("PRV_CONFIG", configJSON)
	if err != nil {
		return fmt.Errorf("failed to store config: %v", err)
	}

	fmt.Printf("✓ Ledger initialized with PRV config\n")
	return nil
}

// CreateEvidence creates new evidence without permit (simplified for testing)
func (cc *DFIRChaincode) CreateEvidenceSimple(ctx contractapi.TransactionContextInterface,
	id string, caseID string, evidenceType string, description string,
	hash string, location string, metadata string, timestamp int64) error {

	clientID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get client identity: %v", err)
	}

	existing, err := ctx.GetStub().GetState(id)
	if err != nil {
		return fmt.Errorf("failed to read evidence: %v", err)
	}
	if existing != nil {
		return fmt.Errorf("evidence %s already exists", id)
	}

	evidence := Evidence{
		ID:          id,
		CaseID:      caseID,
		Type:        evidenceType,
		Description: description,
		Hash:        hash,
		Location:    location,
		Custodian:   clientID,
		Timestamp:   timestamp,
		Status:      "collected",
		Metadata:    metadata,
	}

	evidenceJSON, err := json.Marshal(evidence)
	if err != nil {
		return fmt.Errorf("failed to marshal evidence: %v", err)
	}

	err = ctx.GetStub().PutState(id, evidenceJSON)
	if err != nil {
		return fmt.Errorf("failed to store evidence: %v", err)
	}

	ctx.GetStub().SetEvent("EvidenceCreated", evidenceJSON)
	fmt.Printf("✓ Evidence created: %s\n", id)
	return nil
}

// ReadEvidenceSimple reads evidence without permit (simplified for testing)
func (cc *DFIRChaincode) ReadEvidenceSimple(ctx contractapi.TransactionContextInterface,
	id string) (*Evidence, error) {

	evidenceJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read evidence: %v", err)
	}
	if evidenceJSON == nil {
		return nil, fmt.Errorf("evidence %s does not exist", id)
	}

	var evidence Evidence
	err = json.Unmarshal(evidenceJSON, &evidence)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal evidence: %v", err)
	}

	return &evidence, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&DFIRChaincode{})
	if err != nil {
		fmt.Printf("Error creating DFIR chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting DFIR chaincode: %v\n", err)
	}
}
