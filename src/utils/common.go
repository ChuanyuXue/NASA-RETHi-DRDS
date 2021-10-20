package utils

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"strconv"
)

// ----------- Common static functions ----------
func LoadFromJson(path string, server JsonStandard) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()

	byteValue, err := ioutil.ReadAll(file)
	if err != nil {
		return err
	}

	err = json.Unmarshal([]byte(byteValue), &server)
	if err != nil {
		return err
	}

	return nil
}

func StringToInt(s string) (int, error) {
	i, err := strconv.Atoi(s)
	if err != nil {
		return -1, err
	}
	return i, nil
}
