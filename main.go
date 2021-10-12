package main

import (
	// "datarepo/src/databasemanager"
	// "datarepo/src/communicator"
	"datarepo/src/communicator"
	"datarepo/src/dbmanager"
	"datarepo/src/utils"
	// "fmt"
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
	// ------------------- Test for first demo --------------------
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

	// ---------------- Test for server ----------------------
	// var udpServer = communicator.UDPServer{}
	// utils.LoadFromJson("config/client_configs.json", &udpServer)
	// // var udpServer = communicator.UDPServer{Server: *server}
	// signalChan := make(chan utils.CtrlSig, utils.CHANELLEN)
	// packetChan := make(chan communicator.Packet, utils.CHANELLEN)

	// udpServer.Init(signalChan, packetChan)
	// go udpServer.Run()
	// time.Sleep(10 * time.Second)
	// udpServer.Terminate()

	// -------------------- Test for Packet ----------------
	// payload := []float64{1, 2, 3, 4, 5}
	// pct := communicator.Packet{1, 2, 3, 4, 5, 6, 30, payload}
	// buf := pct.ToBuf()
	// pct2 := communicator.FromBuf(buf)
	// fmt.Println(pct2)
	// --------------------- Test for Client and Server ------------
	var payload []float64
	var pct communicator.Packet

	//Start UDP server
	var udpServer = communicator.UDPServer{}
	utils.LoadFromJson("config/server_configs.json", &udpServer)
	serverSignalChan := make(chan utils.CtrlSig, utils.CHANELLEN)
	packetChan := make(chan communicator.Packet, utils.CHANELLEN)
	udpServer.Init(serverSignalChan, packetChan)
	go udpServer.Run()

	//Start Client
	var client = communicator.Client{}
	utils.LoadFromJson("config/client_configs.json", &client)
	clientSignalChan := make(chan utils.CtrlSig, utils.CHANELLEN)
	messageChan := make(chan dbmanager.Message, utils.CHANELLEN)
	client.Init(clientSignalChan, messageChan)

	//Send first time
	payload = []float64{1, 2, 3, 4, 5}
	pct = communicator.Packet{1, 2, 3, 4, 5, 6, 30, payload}
	client.Send(pct)

	// //Send second time
	payload = []float64{1, 5, 5, 1, 5}
	pct = communicator.Packet{1, 2, 3, 4, 5, 6, 30, payload}
	client.Send(pct)

	// //Stop after 10 secs
	time.Sleep(10 * time.Second)
	udpServer.Terminate()
}
