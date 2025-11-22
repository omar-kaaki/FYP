package utils

import (
	"encoding/json"
	"fmt"
)

// MarshalJSON marshals a struct to JSON bytes
func MarshalJSON(v interface{}) ([]byte, error) {
	jsonBytes, err := json.Marshal(v)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal JSON: %v", err)
	}
	return jsonBytes, nil
}

// UnmarshalJSON unmarshals JSON bytes to a struct
func UnmarshalJSON(data []byte, v interface{}) error {
	if err := json.Unmarshal(data, v); err != nil {
		return fmt.Errorf("failed to unmarshal JSON: %v", err)
	}
	return nil
}

// PrettyJSON returns pretty-printed JSON string
func PrettyJSON(v interface{}) (string, error) {
	jsonBytes, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return "", fmt.Errorf("failed to pretty print JSON: %v", err)
	}
	return string(jsonBytes), nil
}
