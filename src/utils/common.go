package utils

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"strconv"
)

type Subsys struct {
	ID         int    `json:"id"`
	Name       string `json:"name"`
	LocalAddr  string `json:"local_addr"`
	RemoteAddr string `json:"remote_addr"`
}

// ----------- Common static functions ----------
func LoadFromJson(path string, server JsonStandard) {
	file, err := os.Open(path)
	if err != nil {
		panic("Fail to load configuration file.")
	}
	defer file.Close()

	byteValue, err := ioutil.ReadAll(file)
	if err != nil {
		panic("Fail to read content.")
	}

	if json.Unmarshal([]byte(byteValue), &server) != nil {
		panic("Fail to decode json content")
	}
}


func StringToInt(s string) int{
	i, err := strconv.Atoi(s)
    if err != nil {
        panic(err)
    }
	return i
}
