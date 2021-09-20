package units

import (
	"os"
	"encoder	"
)

type Subsys struct {
	ID         int    `json:"id"`
	Name       string `json:"name"`
	LocalAddr  string `json:"local_addr"`
	RemoteAddr string `json:"remote_addr"`
}

//All configures are flattend in Config struct

type Config struct{
	//communicator

	//database

	//subsystems
}

func LoadFromJson(path string) *Config{
	string
}