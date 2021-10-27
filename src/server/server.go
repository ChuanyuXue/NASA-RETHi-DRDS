package server

import (
	"datarepo/src/utils"
)

type Server struct {
	utils.JsonStandard
	utils.ServiceStandard

	Local       string   `json:"local"`
	Public      string   `json:"public"`
	Port        string   `json:"port"`
	Type        string   `json:"type"`
	Src         string   `json:"src"`
	Clients     []string `json:"clients"`
	ClientsPort []string `json:"clients_port"`
	ClientsSrc  []string `json:"clients_src"`
}
