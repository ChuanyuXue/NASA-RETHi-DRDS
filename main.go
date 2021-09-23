package main

import (
	// "datarepo/src/databasemanager"
	// "datarepo/src/utils"
	"datarepo/src/communicator"
	"datarepo/src/utils"
	"time"
	// "net"
)

// const (
// 	CONN_HOST = "127.0.0.1"
// 	CONN_PORT = "3333"
// 	CONN_TYPE = "udp"
// 	BUF_LEN   = 65536
// )

func main() {
	// addr := net.UDPAddr{
	// 	Port: 3333,
	// 	IP:   net.ParseIP("127.0.0.1"),
	// }
	// conn, err := net.ListenUDP("udp", &addr) // code does not block here
	// if err != nil {
	// 	panic(err)
	// }
	// defer conn.Close()

	// var buf [BUF_LEN]byte
	// for {
	// 	rlen, remote, err := conn.ReadFromUDP(buf[:])
	// 	fmt.Println(rlen, remote, err)

	// 	packet := utils.Packet{}
	// 	packet.FromBuf(buf[:])

	// 	handler := databasemanager.PacHandler(packet)

	// 	demoSqlServer := databasemanager.DemoManager{}
	// 	demoSqlServer.AccessDatabase()
	// 	demoSqlServer.InsertData(handler.Handle())

	// }

	var udpServer = communicator.UDPServer{}
	utils.LoadFromJson("config/client_configs.json", &udpServer)
	// var udpServer = communicator.UDPServer{Server: *server}
	signalChan := make(chan utils.CtrlSig, utils.CHANELLEN)
	packetChan := make(chan communicator.Packet, utils.CHANELLEN)

	udpServer.Init(signalChan, packetChan)
	go udpServer.Run()
	time.Sleep(10 * time.Second)
	udpServer.Terminate()
}
