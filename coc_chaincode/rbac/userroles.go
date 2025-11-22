package rbac

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shim"
)

// UserRole represents the on-chain user role mapping
type UserRole struct {
	PrincipalID string   `json:"principalId"`
	Roles       []string `json:"roles"`
	UpdatedBy   string   `json:"updatedBy"`
	UpdatedAt   string   `json:"updatedAt"`
}

// SetUserRoles sets the roles for a principal (admin function)
func SetUserRoles(stub shim.ChaincodeStubInterface, principalID string, rolesCsv string) error {
	// Validate admin identity
	identity, err := ValidateAdminIdentity(stub)
	if err != nil {
		return err
	}

	// Parse roles from CSV
	roles := parseRolesCsv(rolesCsv)
	if len(roles) == 0 {
		return fmt.Errorf("at least one role must be specified")
	}

	// Validate roles
	validRoles := map[string]bool{
		"BlockchainInvestigator": true,
		"BlockchainAuditor":      true,
		"BlockchainCourt":        true,
		"SystemAdmin":            true,
	}

	for _, role := range roles {
		if !validRoles[role] {
			return fmt.Errorf("invalid role: %s", role)
		}
	}

	// Create UserRole record
	userRole := UserRole{
		PrincipalID: principalID,
		Roles:       roles,
		UpdatedBy:   identity.CommonName,
		UpdatedAt:   time.Now().UTC().Format(time.RFC3339),
	}

	// Marshal to JSON
	userRoleJSON, err := json.Marshal(userRole)
	if err != nil {
		return fmt.Errorf("failed to marshal user role: %v", err)
	}

	// Save to state
	key := fmt.Sprintf("USERROLE:%s", principalID)
	if err := stub.PutState(key, userRoleJSON); err != nil {
		return fmt.Errorf("failed to save user role: %v", err)
	}

	return nil
}

// GetUserRoles retrieves the roles for a principal
func GetUserRoles(stub shim.ChaincodeStubInterface, principalID string) (*UserRole, error) {
	key := fmt.Sprintf("USERROLE:%s", principalID)

	userRoleJSON, err := stub.GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to get user role: %v", err)
	}

	if userRoleJSON == nil {
		return nil, fmt.Errorf("user role not found for principal: %s", principalID)
	}

	var userRole UserRole
	if err := json.Unmarshal(userRoleJSON, &userRole); err != nil {
		return nil, fmt.Errorf("failed to unmarshal user role: %v", err)
	}

	return &userRole, nil
}

// ValidateUserRole checks if a user has the claimed role
func ValidateUserRole(stub shim.ChaincodeStubInterface, principalID, claimedRole string) error {
	userRole, err := GetUserRoles(stub, principalID)
	if err != nil {
		return fmt.Errorf("user not registered in on-chain RBAC: %v", err)
	}

	// Check if claimed role is in user's roles
	hasRole := false
	for _, role := range userRole.Roles {
		if role == claimedRole {
			hasRole = true
			break
		}
	}

	if !hasRole {
		return fmt.Errorf("role '%s' not allowed for user (has roles: %v)", claimedRole, userRole.Roles)
	}

	return nil
}

// ListUserRoles returns all user role mappings (admin function)
func ListUserRoles(stub shim.ChaincodeStubInterface) ([]UserRole, error) {
	// Validate admin identity
	if _, err := ValidateAdminIdentity(stub); err != nil {
		return nil, err
	}

	// Query by prefix
	iterator, err := stub.GetStateByRange("USERROLE:", "USERROLE:~")
	if err != nil {
		return nil, fmt.Errorf("failed to get user roles iterator: %v", err)
	}
	defer iterator.Close()

	var userRoles []UserRole
	for iterator.HasNext() {
		kv, err := iterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate user roles: %v", err)
		}

		var userRole UserRole
		if err := json.Unmarshal(kv.Value, &userRole); err != nil {
			continue // Skip invalid records
		}

		userRoles = append(userRoles, userRole)
	}

	return userRoles, nil
}

// DeleteUserRole removes a user role mapping (admin function)
func DeleteUserRole(stub shim.ChaincodeStubInterface, principalID string) error {
	// Validate admin identity
	if _, err := ValidateAdminIdentity(stub); err != nil {
		return err
	}

	key := fmt.Sprintf("USERROLE:%s", principalID)

	// Check if exists
	existing, err := stub.GetState(key)
	if err != nil {
		return fmt.Errorf("failed to check user role: %v", err)
	}
	if existing == nil {
		return fmt.Errorf("user role not found for principal: %s", principalID)
	}

	// Delete
	if err := stub.DelState(key); err != nil {
		return fmt.Errorf("failed to delete user role: %v", err)
	}

	return nil
}

// parseRolesCsv parses a comma-separated list of roles
func parseRolesCsv(rolesCsv string) []string {
	if rolesCsv == "" {
		return []string{}
	}

	parts := strings.Split(rolesCsv, ",")
	roles := make([]string, 0, len(parts))

	for _, part := range parts {
		role := strings.TrimSpace(part)
		if role != "" {
			roles = append(roles, role)
		}
	}

	return roles
}
