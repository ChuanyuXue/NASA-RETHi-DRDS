package main

import (
	// "datarepo/src/handler"
	"datarepo/src/server"
	"datarepo/src/utils"
	"fmt"
)

func main() {
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
	// err = handler.Write(5, 0, tempData)
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
	// data, err := handler.ReadSynt(5, 0)
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// fmt.Println(data)
	// --------------- Test for UDP server ---------------------
	// udpServer := server.UdpServer{}
	// err := utils.LoadFromJson("config/udpserver_configs.json", &udpServer)
	// if err != nil {
	// 	fmt.Println(nil)
	// }
	// err = udpServer.Init()
	// if err != nil{
	// 	fmt.Print(nil)
	// }
	// --------------- Test for Python API ------------------------
	udpServer := server.Server{}
	err := utils.LoadFromJson("config/udpserver_configs.json", &udpServer)
	if err != nil {
		fmt.Println(err)
	}
	err = udpServer.Init()
	if err != nil {
		fmt.Print(err)
	}
}
