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

func Uint8Contains(s []uint8, i uint8) bool {
	for _, v := range s {
		if v == i {
			return true
		}
	}
	return false
}

func Uint16Contains(s []uint16, i uint16) bool {
	for _, v := range s {
		if v == i {
			return true
		}
	}
	return false
}

func Uint32Contains(s []uint32, i uint32) bool {
	for _, v := range s {
		if v == i {
			return true
		}
	}
	return false
}

func DoubleContains(s []float64, i float64) bool {
	for _, v := range s {
		if v == i {
			return true
		}
	}
	return false
}
