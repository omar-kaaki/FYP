package main

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/casbin/casbin/v2"
	"github.com/casbin/casbin/v2/model"
	fileadapter "github.com/casbin/casbin/v2/persist/file-adapter"
	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-protos-go/peer"
	"github.com/rae81/FYPBcoc/coc_chaincode/domain"
	"github.com/rae81/FYPBcoc/coc_chaincode/rbac"
)

//go:embed access/casbin_model.conf
var casbinModelConf string

//go:embed access/casbin_policy.csv
var casbinPolicyCSV string

// CoCChaincode implements the Chain of Custody chaincode
type CoCChaincode struct {
	enforcer *casbin.Enforcer
}

// Init initializes the chaincode
func (cc *CoCChaincode) Init(stub shim.ChaincodeStubInterface) peer.Response {
	// Initialize Casbin enforcer
	if err := cc.initCasbin(); err != nil {
		return shim.Error(fmt.Sprintf("Failed to initialize Casbin: %v", err))
	}

	return shim.Success([]byte("Chaincode initialized successfully"))
}

// Invoke is the entry point for all chaincode invocations
func (cc *CoCChaincode) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
	// Get function name and arguments
	function, args := stub.GetFunctionAndParameters()

	// Get channel ID and map to domain
	channelID := stub.GetChannelID()
	domain := cc.mapChannelToDomain(channelID)

	// Route based on function
	switch function {
	// ====================
	// Admin Functions
	// ====================
	case "SetUserRoles":
		return cc.setUserRoles(stub, args)
	case "GetUserRoles":
		return cc.getUserRoles(stub, args)
	case "ListUserRoles":
		return cc.listUserRoles(stub)
	case "DeleteUserRole":
		return cc.deleteUserRole(stub, args)

	// ====================
	// Investigation Functions (Gateway)
	// ====================
	case "CreateInvestigation":
		return cc.createInvestigation(stub, args, domain)
	case "GetInvestigation":
		return cc.getInvestigation(stub, args, domain)
	case "UpdateInvestigation":
		return cc.updateInvestigation(stub, args, domain)
	case "ListInvestigations":
		return cc.listInvestigations(stub, domain)
	case "ArchiveInvestigation":
		return cc.archiveInvestigation(stub, args, domain)
	case "ReopenInvestigation":
		return cc.reopenInvestigation(stub, args, domain)

	// ====================
	// Evidence Functions (Gateway)
	// ====================
	case "AddEvidence":
		return cc.addEvidence(stub, args, domain)
	case "GetEvidence":
		return cc.getEvidence(stub, args, domain)
	case "ListEvidence":
		return cc.listEvidence(stub, domain)
	case "ListEvidenceByInvestigation":
		return cc.listEvidenceByInvestigation(stub, args, domain)
	case "AddCustodyEvent":
		return cc.addCustodyEvent(stub, args, domain)
	case "VerifyEvidenceHash":
		return cc.verifyEvidenceHash(stub, args, domain)

	// ====================
	// GUID Mapping Functions (Gateway - Cold Chain Only)
	// ====================
	case "CreateGUIDMapping":
		return cc.createGUIDMapping(stub, args, domain)
	case "ResolveGUID":
		return cc.resolveGUID(stub, args, domain)
	case "GetEvidenceByGUID":
		return cc.getEvidenceByGUID(stub, args, domain)
	case "ListGUIDMappings":
		return cc.listGUIDMappings(stub, domain)

	default:
		return shim.Error(fmt.Sprintf("Unknown function: %s", function))
	}
}

// ====================
// Helper Functions
// ====================

// initCasbin initializes the Casbin enforcer
func (cc *CoCChaincode) initCasbin() error {
	// Load model from embedded string
	m, err := model.NewModelFromString(casbinModelConf)
	if err != nil {
		return fmt.Errorf("failed to create Casbin model: %v", err)
	}

	// Create temporary adapter from embedded CSV
	adapter := fileadapter.NewAdapterFromString(casbinPolicyCSV)

	// Create enforcer
	enforcer, err := casbin.NewEnforcer(m, adapter)
	if err != nil {
		return fmt.Errorf("failed to create Casbin enforcer: %v", err)
	}

	cc.enforcer = enforcer
	return nil
}

// mapChannelToDomain maps channel ID to domain for Casbin
func (cc *CoCChaincode) mapChannelToDomain(channelID string) string {
	switch channelID {
	case "hot-chain":
		return "hot"
	case "cold-chain":
		return "cold"
	default:
		return "unknown"
	}
}

// enforceAccess checks access control using Casbin
func (cc *CoCChaincode) enforceAccess(role, domain, obj, act string) error {
	allowed, err := cc.enforcer.Enforce(role, domain, obj, act)
	if err != nil {
		return fmt.Errorf("Casbin enforcement error: %v", err)
	}

	if !allowed {
		return fmt.Errorf("permission denied: role '%s' cannot '%s' on '%s' in domain '%s'",
			role, act, obj, domain)
	}

	return nil
}

// validateAndGetUserContext validates gateway identity and extracts user context
func (cc *CoCChaincode) validateAndGetUserContext(stub shim.ChaincodeStubInterface) (*rbac.UserContext, error) {
	// Validate gateway identity
	if err := rbac.ValidateGatewayIdentity(stub); err != nil {
		return nil, err
	}

	// Get user context from transient
	userContext, err := rbac.GetUserContext(stub)
	if err != nil {
		return nil, err
	}

	// Build principal ID
	principalID := rbac.BuildPrincipalID(rbac.TrustedGatewayMSPID, rbac.TrustedGatewayCN, userContext.UserID)

	// Validate user has the claimed role
	if err := rbac.ValidateUserRole(stub, principalID, userContext.Role); err != nil {
		return nil, err
	}

	return userContext, nil
}

// ====================
// Admin Functions Implementation
// ====================

func (cc *CoCChaincode) setUserRoles(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting: principalID, rolesCsv")
	}

	principalID := args[0]
	rolesCsv := args[1]

	if err := rbac.SetUserRoles(stub, principalID, rolesCsv); err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte(fmt.Sprintf("Roles set for principal: %s", principalID)))
}

func (cc *CoCChaincode) getUserRoles(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting: principalID")
	}

	principalID := args[0]

	userRole, err := rbac.GetUserRoles(stub, principalID)
	if err != nil {
		return shim.Error(err.Error())
	}

	userRoleJSON, err := json.Marshal(userRole)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal user role: %v", err))
	}

	return shim.Success(userRoleJSON)
}

func (cc *CoCChaincode) listUserRoles(stub shim.ChaincodeStubInterface) peer.Response {
	userRoles, err := rbac.ListUserRoles(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	userRolesJSON, err := json.Marshal(userRoles)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal user roles: %v", err))
	}

	return shim.Success(userRolesJSON)
}

func (cc *CoCChaincode) deleteUserRole(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting: principalID")
	}

	principalID := args[0]

	if err := rbac.DeleteUserRole(stub, principalID); err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte(fmt.Sprintf("User role deleted for principal: %s", principalID)))
}

// ====================
// Investigation Functions Implementation
// ====================

func (cc *CoCChaincode) createInvestigation(stub shim.ChaincodeStubInterface, args []string, domain string) peer.Response {
	if len(args) != 3 {
		return shim.Error("Incorrect number of arguments. Expecting: id, title, description")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Enforce access control
	if err := cc.enforceAccess(userContext.Role, domain, "investigation:*", "create"); err != nil {
		return shim.Error(err.Error())
	}

	id := args[0]
	title := args[1]
	description := args[2]

	if err := domain.CreateInvestigation(stub, id, title, description, userContext.UserID, domain); err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte(fmt.Sprintf("Investigation created: %s", id)))
}

func (cc *CoCChaincode) getInvestigation(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting: id")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	id := args[0]

	// Enforce access control
	obj := fmt.Sprintf("investigation:%s", id)
	if err := cc.enforceAccess(userContext.Role, dom, obj, "view"); err != nil {
		return shim.Error(err.Error())
	}

	investigation, err := domain.GetInvestigation(stub, id)
	if err != nil {
		return shim.Error(err.Error())
	}

	investigationJSON, err := json.Marshal(investigation)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal investigation: %v", err))
	}

	return shim.Success(investigationJSON)
}

func (cc *CoCChaincode) updateInvestigation(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) != 3 {
		return shim.Error("Incorrect number of arguments. Expecting: id, title, description")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	id := args[0]

	// Enforce access control
	obj := fmt.Sprintf("investigation:%s", id)
	if err := cc.enforceAccess(userContext.Role, dom, obj, "update"); err != nil {
		return shim.Error(err.Error())
	}

	title := args[1]
	description := args[2]

	if err := domain.UpdateInvestigation(stub, id, title, description); err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte(fmt.Sprintf("Investigation updated: %s", id)))
}

func (cc *CoCChaincode) listInvestigations(stub shim.ChaincodeStubInterface, dom string) peer.Response {
	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Enforce access control
	if err := cc.enforceAccess(userContext.Role, dom, "investigation:*", "view"); err != nil {
		return shim.Error(err.Error())
	}

	investigations, err := domain.ListInvestigations(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	investigationsJSON, err := json.Marshal(investigations)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal investigations: %v", err))
	}

	return shim.Success(investigationsJSON)
}

func (cc *CoCChaincode) archiveInvestigation(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting: id")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	id := args[0]

	// Enforce access control
	obj := fmt.Sprintf("investigation:%s", id)
	if err := cc.enforceAccess(userContext.Role, dom, obj, "archive"); err != nil {
		return shim.Error(err.Error())
	}

	if err := domain.ArchiveInvestigation(stub, id); err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte(fmt.Sprintf("Investigation archived: %s", id)))
}

func (cc *CoCChaincode) reopenInvestigation(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting: id")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	id := args[0]

	// Enforce access control
	obj := fmt.Sprintf("investigation:%s", id)
	if err := cc.enforceAccess(userContext.Role, dom, obj, "reopen"); err != nil {
		return shim.Error(err.Error())
	}

	if err := domain.ReopenInvestigation(stub, id); err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte(fmt.Sprintf("Investigation reopened: %s", id)))
}

// ====================
// Evidence Functions Implementation
// ====================

func (cc *CoCChaincode) addEvidence(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) < 5 {
		return shim.Error("Incorrect number of arguments. Expecting: id, investigationId, hash, ipfsCid, metaJSON")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Enforce access control
	if err := cc.enforceAccess(userContext.Role, dom, "evidence:*", "create"); err != nil {
		return shim.Error(err.Error())
	}

	id := args[0]
	investigationID := args[1]
	hash := args[2]
	ipfsCid := args[3]
	metaJSON := args[4]

	// Parse metadata
	var meta domain.EvidenceMeta
	if err := json.Unmarshal([]byte(metaJSON), &meta); err != nil {
		return shim.Error(fmt.Sprintf("Failed to parse metadata: %v", err))
	}

	if err := domain.AddEvidence(stub, id, investigationID, hash, ipfsCid, userContext.UserID, dom, meta); err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte(fmt.Sprintf("Evidence added: %s", id)))
}

func (cc *CoCChaincode) getEvidence(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting: id")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	id := args[0]

	// Enforce access control
	obj := fmt.Sprintf("evidence:%s", id)
	if err := cc.enforceAccess(userContext.Role, dom, obj, "view"); err != nil {
		return shim.Error(err.Error())
	}

	evidence, err := domain.GetEvidence(stub, id)
	if err != nil {
		return shim.Error(err.Error())
	}

	evidenceJSON, err := json.Marshal(evidence)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal evidence: %v", err))
	}

	return shim.Success(evidenceJSON)
}

func (cc *CoCChaincode) listEvidence(stub shim.ChaincodeStubInterface, dom string) peer.Response {
	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Enforce access control
	if err := cc.enforceAccess(userContext.Role, dom, "evidence:*", "view"); err != nil {
		return shim.Error(err.Error())
	}

	evidenceList, err := domain.ListEvidence(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	evidenceJSON, err := json.Marshal(evidenceList)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal evidence list: %v", err))
	}

	return shim.Success(evidenceJSON)
}

func (cc *CoCChaincode) listEvidenceByInvestigation(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting: investigationId")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Enforce access control
	if err := cc.enforceAccess(userContext.Role, dom, "evidence:*", "view"); err != nil {
		return shim.Error(err.Error())
	}

	investigationID := args[0]

	evidenceList, err := domain.ListEvidenceByInvestigation(stub, investigationID)
	if err != nil {
		return shim.Error(err.Error())
	}

	evidenceJSON, err := json.Marshal(evidenceList)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal evidence list: %v", err))
	}

	return shim.Success(evidenceJSON)
}

func (cc *CoCChaincode) addCustodyEvent(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) != 5 {
		return shim.Error("Incorrect number of arguments. Expecting: evidenceId, action, custodian, location, description")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	evidenceID := args[0]

	// Enforce access control
	obj := fmt.Sprintf("evidence:%s", evidenceID)
	if err := cc.enforceAccess(userContext.Role, dom, obj, "append"); err != nil {
		return shim.Error(err.Error())
	}

	action := args[1]
	custodian := args[2]
	location := args[3]
	description := args[4]

	if err := domain.AddCustodyEvent(stub, evidenceID, action, custodian, location, description); err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte(fmt.Sprintf("Custody event added to evidence: %s", evidenceID)))
}

func (cc *CoCChaincode) verifyEvidenceHash(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting: evidenceId, hash")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	evidenceID := args[0]

	// Enforce access control
	obj := fmt.Sprintf("evidence:%s", evidenceID)
	if err := cc.enforceAccess(userContext.Role, dom, obj, "view"); err != nil {
		return shim.Error(err.Error())
	}

	providedHash := args[1]

	valid, err := domain.VerifyEvidenceHash(stub, evidenceID, providedHash)
	if err != nil {
		return shim.Error(err.Error())
	}

	result := map[string]interface{}{
		"evidenceId": evidenceID,
		"valid":      valid,
	}

	resultJSON, err := json.Marshal(result)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal result: %v", err))
	}

	return shim.Success(resultJSON)
}

// ====================
// GUID Mapping Functions Implementation
// ====================

func (cc *CoCChaincode) createGUIDMapping(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) != 3 {
		return shim.Error("Incorrect number of arguments. Expecting: guid, internalEvidenceId, description")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Enforce access control
	if err := cc.enforceAccess(userContext.Role, dom, "guid_mapping", "create"); err != nil {
		return shim.Error(err.Error())
	}

	guid := args[0]
	internalEvidenceID := args[1]
	description := args[2]

	if err := domain.CreateGUIDMapping(stub, guid, internalEvidenceID, userContext.UserID, description); err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte(fmt.Sprintf("GUID mapping created: %s", guid)))
}

func (cc *CoCChaincode) resolveGUID(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting: guid")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Enforce access control
	if err := cc.enforceAccess(userContext.Role, dom, "guid_mapping", "resolve_guid"); err != nil {
		return shim.Error(err.Error())
	}

	guid := args[0]

	guidMapping, err := domain.ResolveGUID(stub, guid)
	if err != nil {
		return shim.Error(err.Error())
	}

	guidMappingJSON, err := json.Marshal(guidMapping)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal GUID mapping: %v", err))
	}

	return shim.Success(guidMappingJSON)
}

func (cc *CoCChaincode) getEvidenceByGUID(stub shim.ChaincodeStubInterface, args []string, dom string) peer.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting: guid")
	}

	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Enforce access control (requires both resolve_guid and view evidence)
	if err := cc.enforceAccess(userContext.Role, dom, "guid_mapping", "resolve_guid"); err != nil {
		return shim.Error(err.Error())
	}
	if err := cc.enforceAccess(userContext.Role, dom, "evidence:*", "view"); err != nil {
		return shim.Error(err.Error())
	}

	guid := args[0]

	evidence, err := domain.GetEvidenceByGUID(stub, guid)
	if err != nil {
		return shim.Error(err.Error())
	}

	evidenceJSON, err := json.Marshal(evidence)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal evidence: %v", err))
	}

	return shim.Success(evidenceJSON)
}

func (cc *CoCChaincode) listGUIDMappings(stub shim.ChaincodeStubInterface, dom string) peer.Response {
	// Validate and get user context
	userContext, err := cc.validateAndGetUserContext(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Enforce access control
	if err := cc.enforceAccess(userContext.Role, dom, "guid_mapping", "view"); err != nil {
		return shim.Error(err.Error())
	}

	guidMappings, err := domain.ListGUIDMappings(stub)
	if err != nil {
		return shim.Error(err.Error())
	}

	guidMappingsJSON, err := json.Marshal(guidMappings)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal GUID mappings: %v", err))
	}

	return shim.Success(guidMappingsJSON)
}

// ====================
// Main Function
// ====================

func main() {
	chaincode := &CoCChaincode{}

	// Initialize Casbin on startup
	if err := chaincode.initCasbin(); err != nil {
		fmt.Printf("Error initializing Casbin: %v\n", err)
		return
	}

	if err := shim.Start(chaincode); err != nil {
		fmt.Printf("Error starting chaincode: %v\n", err)
	}
}
