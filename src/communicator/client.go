package communicator

import (
	"datarepo/src/dbmanager"
	"datarepo/src/utils"
	"fmt"
	"net"
)

type Client struct {
	utils.JsonStandard
	utils.ClientStandard

	Local     string `json:"local"`
	Public    string `json:"public"`
	Port      string `json:"port"`
	BuffLen   int    `json:"buff_len"`
	Frequence int    `json:"frequence"`

	Headers struct {
		Src      string `json:"src"`
		Dst      string `json:"dst"`
		Type     string `json:"type"`
		Priority string `json:"priority"`
		Row      string `json:"row"`
		Col      string `json:"col"`
		Length   string `json:"length"`
	} `json:"headers"`
	Payload string `json:"payload"`
	Trailer string `json:"trailer"`

	OutConn *net.UDPConn

	InChanel  chan utils.CtrlSig
	OutChanel chan dbmanager.Message
}

func (userClient *Client) Init(inchan chan utils.CtrlSig, outchan chan dbmanager.Message) {
	userClient.InChanel = inchan
	userClient.OutChanel = outchan
	fmt.Println("User client is build up, chanels are settled.")
	userClient.Build()
}

func (userClient *Client) Run() {

	defer userClient.Close()
	for {

	}
}

func (userClient *Client) Terminate() {

}

func (userClient *Client) Build() {
	// Server standard
	var (
		addr net.UDPAddr
	)

	if userClient.Public == "NA" {
		addr.Port = utils.StringToInt(userClient.Port)
		addr.IP = net.ParseIP(userClient.Local)
	} else {
		addr.Port = utils.StringToInt(userClient.Port)
		addr.IP = net.ParseIP(userClient.Public)
	}

	conn, err := net.DialUDP("udp", nil, &addr)
	if err != nil {
		panic(err)
	}

	userClient.OutConn = conn
	fmt.Println("Connection has been built")
}

func (userClient *Client) Send(packet Packet) {
	userClient.OutConn.Write(packet.ToBuf())
}

func (userClient *Client) Close() {
	// Server standard
	if userClient.OutConn != nil {
		err := userClient.OutConn.Close()
		if err != nil {
			panic(err)
		}
	}
	fmt.Println("Connection has been closed")
}
