package main

import (
	"fmt"

	"github.com/ChuanyuXue/NASA-RETHi-DRDS/src/handler"
	"github.com/ChuanyuXue/NASA-RETHi-DRDS/src/server"
	"github.com/ChuanyuXue/NASA-RETHi-DRDS/src/utils"
	// "time"
)

func init() {
	err := handler.DatabaseGenerator(utils.SYSTEM_ID["HMS"], "db_info_v6.json")
	if err != nil {
		fmt.Println(err)
	}
	err = handler.DatabaseGenerator(utils.SYSTEM_ID["GCC"], "db_info_v6.json")
	if err != nil {
		fmt.Println(err)
	}
}

// Usage: go run main.go
// NOTE: This program can only run in the docker container with correct docker-compose.yml file
func main() {
	// --------------------- Test for packet V6 --------------------------

	// b := [...]byte{0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x04, 0x00, 0x00}

	// pkt := server.Packet{1, 2, 3, 4, 5, 6, 3294967290, 3294967291, 65530, 65531, b[:], nil}

	// buf := pkt.ToBuf()
	// fmt.Println(server.FromBuf(buf))

	// test := [...]float64{1, 2, 3, 4}
	// testbuf := server.PayloadFloat2Buf(test[:])

	// test2 := [...]float64{1, 2, 3, 4, 5, 6}
	// testbuf2 := server.PayloadFloat2Buf(test2[:])

	// subpkt0 := server.SubPacket{1, 1000, 1, 4, 4, testbuf}
	// subpkt1 := server.SubPacket{1, 1000, 2, 3, 6, testbuf2}
	// subpkt2 := server.SubPacket{1, 1000, 3, 2, 6, testbuf2}
	// subpkt3 := server.SubPacket{1, 1000, 4, 1, 4, testbuf}

	// subpackets := make([]*server.SubPacket, 4)
	// subpackets[0] = &subpkt0
	// subpackets[1] = &subpkt1
	// subpackets[2] = &subpkt2
	// subpackets[3] = &subpkt3

	// pkt2 := server.ServicePacket{pkt, 11, 12, 13, 14, 4, subpackets}
	// buf2 := pkt2.ToServiceBuf()
	// fmt.Println(server.FromServiceBuf(buf2))
	// for _, v := range pkt2.Subpackets {
	// 	fmt.Println(v)
	// 	fmt.Println(server.PayloadBuf2Float(v.Payload))
	// }

	// id := [...]uint16{1, 2, 3, 4}
	// timed := [...]uint16{1000, 2000, 3000, 4000}
	// row := [...]uint8{1, 2, 3, 4}
	// col := [...]uint8{4, 3, 2, 1}
	// length := [...]uint16{4, 4, 4, 4}

	// multipayload = append(multipayload, testbuf)
	// multipayload = append(multipayload, testbuf)
	// multipayload = append(multipayload, testbuf)
	// multipayload = append(multipayload, testbuf)
	// pkt2 := server.ServicePacket{pkt, 11, 12, 13, 14, 4, id[:], timed[:], row[:], col[:], length[:], multipayload}
	// buf2 := pkt2.ToServiceBuf()
	// fmt.Println(server.FromServiceBuf(buf2))
	// fmt.Println(server.PayloadBuf2Float(server.FromServiceBuf(buf2).PayloadArr[0]))

	// --------------------- Test for packet --------------------------
	// b := [...]byte{0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x04, 0x00, 0x00}
	// pkt := server.Packet{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, b[:]}
	// buf := pkt.ToBuf()
	// fmt.Println(server.FromBuf(buf))

	// pkt2 := server.ServicePacket{pkt, 11, 12, 13, 14}
	// buf2 := pkt2.ToServiceBuf()
	// fmt.Println(server.FromServiceBuf(buf2))

	// ----------------------- Test for Handler Init -----------------------------
	// handler := handler.Handler{}
	// err := utils.LoadFromJson("config/database_configs.json", &handler)
	// if err != nil {
	// 	fmt.Println(err)
	// }

	// err = handler.Init()
	// if err != nil {
	// 	fmt.Println(err)
	// }

	// ----------------------- Test for Handler Write -----------------------------
	// handler := handler.Handler{}
	// err := utils.LoadFromJson("config/database_configs.json", &handler)
	// if err != nil {
	// 	fmt.Println(err)
	// }

	// err = handler.Init()
	// if err != nil {
	// 	fmt.Println(err)
	// }

	// // write in 5 table, time=0, value = xxxx
	// tempData := []float64{1.12312312, 123, 32, 1}
	// err = handler.WriteSynt(4, 0, tempData)
	// if err != nil {
	// 	fmt.Println(err)
	// }

	//-------------- Test for Hanlder Index Read ---------------------
	// handler := handler.Handler{}
	// err := utils.LoadFromJson("config/database_configs.json", &handler)
	// if err != nil {
	// 	fmt.Println(err)
	// }

	// err = handler.Init()
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// // READ from record5 table, time=0
	// data, err := handler.ReadSynt(4, 0)
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// fmt.Println(data)

	// --------------- Test for Data service server ---------------------
	// udpServer := server.Server{}
	// err := utils.LoadFromJson("config/udpserver_configs.json", &udpServer)
	// if err != nil {
	// 	fmt.Println(nil)
	// }
	// err = udpServer.Init()
	// if err != nil{
	// 	fmt.Print(nil)
	// }
	// --------------- Test for Ground <-- Habitat <--> Subsystem ------------------------

	habitatServer := server.Server{}                  // Start Habitat server
	err := habitatServer.Init(utils.SYSTEM_ID["HMS"]) // Init Habitat server
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println("Habitat Data-Service Started")

	// Start Habitat web service
	habitatWebServer := server.WebServer{}
	err = habitatWebServer.Init(utils.SYSTEM_ID["HMS"], &habitatServer)
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println("Habitat Web-Service Started")

	// // Start Ground server
	// groundServer := server.Server{}
	// go groundServer.Init(utils.SRC_GCC)
	// fmt.Println("Ground Server Started")
	// time.Sleep(2 * time.Second)

	// // Let Ground server subscribe Habitat server
	// habitatServer.Subscribe(8011, groundServer.LocalSrc, 0, 1000)
	// habitatServer.Subscribe(8012, groundServer.LocalSrc, 0, 1000)
	// habitatServer.Subscribe(8013, groundServer.LocalSrc, 0, 1000)
	// habitatServer.Subscribe(8014, groundServer.LocalSrc, 0, 1000)
	// habitatServer.Subscribe(8015, groundServer.LocalSrc, 0, 1000)
	// habitatServer.Subscribe(8016, groundServer.LocalSrc, 0, 1000)
	// fmt.Println("Ground Server subscribed Habitat server")

	// Let MCVT subscribe the data Murali asked
	habitatServer.Subscribe(65000, utils.SYSTEM_ID["STR"], 0, 1000)

	select {} // Keep the main thread alive

}
