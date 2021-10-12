package communicator

import (
	"datarepo/src/utils"
	"fmt"
	"net"
)

type Server struct {
	utils.JsonStandard
	utils.ServerStandard

	Local  string `json:"local"`
	Public string `json:"public"`
	Port   string `json:"port"`
	Type   string `json:"type"`
}

type UDPServer struct {
	Server
	utils.JsonStandard
	utils.ComponentStandard

	InConn  *net.UDPConn
	OutConn *net.UDPConn

	InChanel  chan utils.CtrlSig
	OutChanel chan Packet
}

func (udpServer *UDPServer) Init(inchan chan utils.CtrlSig, outchan chan Packet) {
	udpServer.InChanel = inchan
	udpServer.OutChanel = outchan
	fmt.Println("UDPServer is build up, chanels are settled.")
}

func (udpServer *UDPServer) Run() {
	// The component standard Run
	fmt.Println("UDPServer is running.")
	defer fmt.Println("UDPServer is stoped.")
	udpServer.Build()
	defer udpServer.Close()
	var (
		packet Packet
		sig    utils.CtrlSig
	)
	for {
	mainloop:
		select {
		case sig = <-udpServer.InChanel:
			if sig == utils.CLOSE {
				udpServer.Close()
				break mainloop
			}
		default:
		}

		packet = udpServer.Listen()
		udpServer.OutChanel <- packet
	}
}

func (udpServer *UDPServer) Terminate() {
	udpServer.InChanel <- utils.CLOSE
	fmt.Println("Close signal is sending")
}

// Private functions following

func (udpServer *UDPServer) Build() {
	// Server standard
	var (
		addr net.UDPAddr
	)

	if udpServer.Public == "NA" {
		addr.Port = utils.StringToInt(udpServer.Port)
		addr.IP = net.ParseIP(udpServer.Local)
	} else {
		addr.Port = utils.StringToInt(udpServer.Port)
		addr.IP = net.ParseIP(udpServer.Public)
	}

	conn, err := net.ListenUDP("udp", &addr)
	if err != nil {
		panic(err)
	}

	udpServer.InConn = conn
	fmt.Println("Connection has been built")
}

func (udpServer *UDPServer) Close() {
	// Server standard
	if udpServer.InConn != nil {
		err := udpServer.InConn.Close()
		if err != nil {
			panic(err)
		}
	}
	if udpServer.OutConn != nil {
		err := udpServer.OutConn.Close()
		if err != nil {
			panic(err)
		}
	}
	fmt.Println("Connection has been closed")
}

func (udpServer *UDPServer) Listen() Packet {
	// Server standard
	var buf [utils.BUFFLEN]byte
	if udpServer.InConn == nil {
		panic("Connection is not built!")
	}
	_, _, err := udpServer.InConn.ReadFromUDP(buf[:])
	if err != nil {
		panic(err)
	}
	packet := FromBuf(buf[:])
	fmt.Println("Server is listenning from port")
	return packet
}

func (udpServer *UDPServer) Send() error {
	// Server standard
	// In the future use Message replace Packet to comminicate between Database and Server
	var e error
	return e
}

type TSNServer struct {
	Server
	utils.JsonStandard
}
