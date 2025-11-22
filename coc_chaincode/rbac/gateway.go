package rbac

import (
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"strings"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-protos-go/msp"
	"google.golang.org/protobuf/proto"
)

const (
	// TrustedGatewayMSPID is the MSP ID of the trusted gateway
	TrustedGatewayMSPID = "LabOrgMSP"

	// TrustedGatewayCN is the Common Name of the trusted gateway certificate
	TrustedGatewayCN = "lab-gw"
)

// UserContext holds the user information extracted from transient map
type UserContext struct {
	UserID string
	Role   string
}

// IdentityInfo holds parsed identity information
type IdentityInfo struct {
	MSPID       string
	CommonName  string
	IsAdmin     bool
	Certificate *x509.Certificate
}

// GetIdentityInfo extracts and parses the invoker's identity
func GetIdentityInfo(stub shim.ChaincodeStubInterface) (*IdentityInfo, error) {
	// Get creator (invoker) identity
	creatorBytes, err := stub.GetCreator()
	if err != nil {
		return nil, fmt.Errorf("failed to get transaction creator: %v", err)
	}

	// Unmarshal SerializedIdentity
	si := &msp.SerializedIdentity{}
	if err := proto.Unmarshal(creatorBytes, si); err != nil {
		return nil, fmt.Errorf("failed to unmarshal creator identity: %v", err)
	}

	// Parse certificate
	block, _ := pem.Decode(si.IdBytes)
	if block == nil {
		return nil, fmt.Errorf("failed to decode PEM certificate")
	}

	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("failed to parse X509 certificate: %v", err)
	}

	// Extract Common Name
	cn := cert.Subject.CommonName

	// Check if admin (by NodeOU in certificate)
	isAdmin := false
	for _, ou := range cert.Subject.OrganizationalUnit {
		if ou == "admin" {
			isAdmin = true
			break
		}
	}

	return &IdentityInfo{
		MSPID:       si.Mspid,
		CommonName:  cn,
		IsAdmin:     isAdmin,
		Certificate: cert,
	}, nil
}

// ValidateGatewayIdentity ensures the invoker is the trusted gateway
func ValidateGatewayIdentity(stub shim.ChaincodeStubInterface) error {
	identity, err := GetIdentityInfo(stub)
	if err != nil {
		return err
	}

	// Verify MSPID
	if identity.MSPID != TrustedGatewayMSPID {
		return fmt.Errorf("permission denied: invoker MSPID '%s' is not trusted gateway MSP '%s'",
			identity.MSPID, TrustedGatewayMSPID)
	}

	// Verify Common Name
	if identity.CommonName != TrustedGatewayCN {
		return fmt.Errorf("permission denied: invoker CN '%s' is not trusted gateway CN '%s'",
			identity.CommonName, TrustedGatewayCN)
	}

	return nil
}

// ValidateAdminIdentity ensures the invoker is an admin
func ValidateAdminIdentity(stub shim.ChaincodeStubInterface) (*IdentityInfo, error) {
	identity, err := GetIdentityInfo(stub)
	if err != nil {
		return nil, err
	}

	// Check if admin NodeOU
	if !identity.IsAdmin {
		return nil, fmt.Errorf("permission denied: admin identity required (NodeOU=admin)")
	}

	// Allow LabOrgMSP and CourtOrgMSP admins
	if identity.MSPID != "LabOrgMSP" && identity.MSPID != "CourtOrgMSP" {
		return nil, fmt.Errorf("permission denied: admin must be from LabOrgMSP or CourtOrgMSP")
	}

	return identity, nil
}

// GetUserContext extracts user context from transient map
func GetUserContext(stub shim.ChaincodeStubInterface) (*UserContext, error) {
	transientMap, err := stub.GetTransient()
	if err != nil {
		return nil, fmt.Errorf("failed to get transient map: %v", err)
	}

	// Extract userId
	userIDBytes, ok := transientMap["userId"]
	if !ok || len(userIDBytes) == 0 {
		return nil, fmt.Errorf("userId not found in transient map")
	}
	userID := string(userIDBytes)

	// Extract role
	roleBytes, ok := transientMap["role"]
	if !ok || len(roleBytes) == 0 {
		return nil, fmt.Errorf("role not found in transient map")
	}
	role := string(roleBytes)

	return &UserContext{
		UserID: userID,
		Role:   role,
	}, nil
}

// BuildPrincipalID constructs the principal ID for a user
// Format: <MSPID>|<gatewayCN>|user:<userId>
func BuildPrincipalID(mspid, gatewayCN, userID string) string {
	return fmt.Sprintf("%s|%s|user:%s", mspid, gatewayCN, userID)
}

// ParsePrincipalID parses a principal ID into components
func ParsePrincipalID(principalID string) (mspid, gatewayCN, userID string, err error) {
	parts := strings.Split(principalID, "|")
	if len(parts) != 3 {
		return "", "", "", fmt.Errorf("invalid principal ID format: %s", principalID)
	}

	mspid = parts[0]
	gatewayCN = parts[1]

	// Extract userID from "user:<userId>"
	userPart := parts[2]
	if !strings.HasPrefix(userPart, "user:") {
		return "", "", "", fmt.Errorf("invalid user part in principal ID: %s", userPart)
	}
	userID = strings.TrimPrefix(userPart, "user:")

	return mspid, gatewayCN, userID, nil
}
