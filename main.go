package main

import (
	"datarepo/src/handler"
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

	// // write in FDD0 table, time=2, index = 0, value = 1, loc = 2
	// err = handler.Write(0, 0, 0, 2, 2)
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

	// data, err := handler.ReadIndex(0, 0)
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// fmt.Println(data)

	// --------------Test for Handler time read--------------------
	// handler := handler.Handler{}
	// err := utils.LoadFromJson("config/database_configs.json", &handler)
	// if err != nil {
	// 	fmt.Println(err)
	// }

	// err = handler.Init()
	// if err != nil {
	// 	fmt.Println(err)
	// }

	// data, err := handler.ReadTime(0, 0, "value")
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// fmt.Println(data)
}
