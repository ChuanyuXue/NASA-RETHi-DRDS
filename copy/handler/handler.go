package handler

import (
	"datarepo/src/utils"
	"net"
)

type Handler struct{
	utils.JsonStandard

	Local  string `json:"local"`
	Public string `json:"public"`
	Port   string `json:"port"`

	Tables []string

	userName string
	passWord string
}