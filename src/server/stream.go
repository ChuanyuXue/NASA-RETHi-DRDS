package server

import (
	"data-service/src/handler"
	"data-service/src/utils"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/AmyangXYZ/sgo"
	"github.com/AmyangXYZ/sgo/middlewares"
	"github.com/gorilla/websocket"
)

const (
	DATAPATH = "db_info.json"
)

type Data struct {
	Timestamp uint32  `json:"timestamp"`
	Value     float64 `json:"value"`
	ID        string  `json:"id"`
}

type Stream struct {
	utils.JsonStandard
	utils.ServiceStandard

	Type string
	Src  string

	handler *handler.Handler

	LocalSrc  uint8
	ClientSrc []uint8

	upgrader websocket.Upgrader

	wsPktChMap   chan *ServicePacket
	wsPktChMapRT chan *ServicePacket
	wsOpenSig    chan bool
}

func (server *Stream) Init(src uint8) error {
	server.LocalSrc = src
	server.Src = strconv.Itoa(int(src))

	server.wsOpenSig = make(chan bool)
	server.wsPktChMap = make(chan *ServicePacket, 65535)
	server.wsPktChMapRT = make(chan *ServicePacket, 65535)

	//------ init data handler

	server.handler = &handler.Handler{}
	err := server.handler.Init(server.LocalSrc)
	if err != nil {
		fmt.Println("Failed to init data handler")
		fmt.Println(err)
		return err
	}

	//------- init http communication

	// dataList, err := handler.ReadDataInfo(DATAPATH)
	// if err != nil {
	// 	fmt.Println("Streaming server unable to read data description")
	// 	return err
	// }
	// for _, info := range dataList {
	// 	server.wsPktChMap[int(info.Id)] = make(chan *ServicePacket, 1024)
	// }

	server.upgrader = websocket.Upgrader{
		CheckOrigin:     func(r *http.Request) bool { return true },
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
	}

	app := sgo.New()
	app.USE(middlewares.CORS(middlewares.CORSOpt{}))
	app.GET("/ws", server.wsRealTime)
	app.GET("/history", server.wsHistory)
	app.Run(":8888")

	return nil
}

func (server *Stream) RequestRange(id uint16, timeStart uint32, timeDiff uint16) ([]uint32, []uint32, [][]float64, error) {
	fmt.Println("[2] Debug: RequestRange")
	var dataMat [][]float64
	var timeSimuVec []uint32
	var timePhyVec []uint32
	var err error

	if timeDiff == utils.PARAMTER_REQUEST_LAST {
		timeSimuVec, timePhyVec, dataMat, err = server.handler.ReadRange(id, timeStart, server.handler.QueryLastSynt(id))
		if err != nil {
			fmt.Println(err)
			return nil, nil, nil, err
		}
	} else {
		timeSimuVec, timePhyVec, dataMat, err = server.handler.ReadRange(id, timeStart, timeStart+uint32(timeDiff))
		if err != nil {
			fmt.Println(err)
			return nil, nil, nil, err
		}
	}

	return timeSimuVec, timePhyVec, dataMat, nil
}

func (server *Stream) Subscribe(id uint16, closeSig *bool) error {
	fmt.Println("[1] Debug: Subscribe")
	/* 	------------ CHUANYU APR 19 2022 MODIFICATION-------------------------
	   	No history data for Visualization in the real time part anymore,
	   	History data are handled by Request function now
	*/

	// lastTime := server.handler.QueryLastSynt(id)
	// firstTime := server.handler.QueryFirstSynt(id)

	// timeVec, dataMat, err := server.handler.ReadRange(id, firstTime, lastTime)
	// if err != nil {
	// 	fmt.Println(err)
	// 	return err
	// }

	// for i, t := range timeVec {
	// 	server.send(
	// 		utils.SRC_HMS,
	// 		id,
	// 		utils.PRIORITY_HIGHT,
	// 		t,
	// 		255,
	// 		dataMat[i],
	// 	)
	// }

	lastTime := server.handler.QueryLastSynt(id)
	for {
		if *closeSig {
			return nil
		}
		time.Sleep(1 * time.Second)
		currentTime := server.handler.QueryLastSynt(id)
		_, timeVec, dataMat, err := server.handler.ReadRange(id, lastTime, currentTime)
		if err != nil {
			fmt.Println(err)
			return err
		}
		for i, t := range timeVec {
			server.send(
				utils.SRC_HMS,
				id,
				utils.PRIORITY_HIGHT,
				t,
				utils.RESERVED,
				dataMat[i],
				server.wsPktChMapRT,
			)
		}
		lastTime = currentTime
	}

}

func (server *Stream) send(dst uint8, dataID uint16, priority uint8, synt uint32, option2 uint8, dataMap []float64, channel chan *ServicePacket) error {
	fmt.Println("[3] Debug: send")
	var pkt ServicePacket
	pkt.Src = server.LocalSrc
	pkt.Dst = dst
	pkt.MessageType = utils.MSG_OUTER
	pkt.Priority = priority
	pkt.PhysicalTime = uint32(time.Now().Unix())
	pkt.SimulinkTime = synt

	var subpkt SubPacket

	subpkt.DataID = dataID
	subpkt.Row = 1
	subpkt.Col = uint8(len(dataMap))
	subpkt.Length = uint16(subpkt.Row * subpkt.Col)

	pkt.Service = utils.SER_SEND
	pkt.Flag = utils.FLAG_SINGLE
	pkt.Option1 = utils.RESERVED
	pkt.Option2 = option2
	pkt.Data = dataMap

	channel <- &pkt
	// server.wsPktChMap[int(subpkt.DataID)] <- &pkt
	return nil
}

func (server *Stream) wsRealTime(ctx *sgo.Context) error {
	fmt.Println("[4] Debug: wsReadTime")
	SubscribeCloseSig := false

	ws, err := server.upgrader.Upgrade(ctx.Resp, ctx.Req, nil)
	if err != nil {
		fmt.Println(err)
		return err
	}
	defer func() {
		ws.Close()
		fmt.Println("ws/client closed")
	}()

	// Subscribe all of the data
	for _, dataID := range server.handler.RecordTables {
		go server.Subscribe(dataID, &SubscribeCloseSig)
	}

	closeSig := make(chan bool)

	// receive
	go func() {
		for {
			_, _, err := ws.ReadMessage()
			if err != nil {
				closeSig <- true
			}
		}
	}()

	for {
		select {
		case pkt := <-server.wsPktChMapRT:
			data := Data{Timestamp: pkt.SimulinkTime, Value: pkt.Data[0], ID: strconv.Itoa(int(pkt.Subpackets[0].DataID))}
			fmt.Println("[6] Debug: WriteJson")
			if err = ws.WriteJSON(data); err != nil {
				fmt.Println(err)
				continue
			}
		case <-closeSig:
			SubscribeCloseSig = true
			return nil
		}
	}
}

func (server *Stream) wsHistory(ctx *sgo.Context) error {
	var dlist []Data
	fmt.Println("[5] Debug: wsHistory")

	for _, dataID := range server.handler.RecordTables {
		_, tVec, vMat, err := server.RequestRange(dataID, 0, utils.PARAMTER_REQUEST_LAST)
		if err != nil {
			fmt.Println(err)
			return err
		}
		for i, t := range tVec {
			d := Data{Timestamp: t, Value: vMat[i][0], ID: strconv.Itoa(int(dataID))}
			dlist = append(dlist, d)
		}
	}
	return ctx.JSON(200, 1, "success", dlist)
}

// func (server *Stream) wsHandler(ctx *sgo.Context) error {
// 	ws, err := server.upgrader.Upgrade(ctx.Resp, ctx.Req, nil)
// 	if err != nil {
// 		fmt.Println(err)
// 		return err
// 	}
// 	defer func() {
// 		ws.Close()
// 		fmt.Println("ws/client closed")
// 	}()
// 	dataID, err := strconv.Atoi(ctx.Param("dataID"))
// 	if err != nil {
// 		fmt.Println(err)
// 		return err
// 	}
// 	wsPktCh := server.wsPktChMap[dataID]
// 	// server.wsOpenSig <- true
// 	// <-server.wsOpenSig
// 	closeSig := make(chan bool)

// 	// receive
// 	go func() {
// 		for {
// 			_, _, err := ws.ReadMessage()
// 			if err != nil {
// 				closeSig <- true
// 			}
// 		}
// 	}()
// 	// 		pkt := new(Packet)
// 	// 		if err = pkt.FromJSON(buf); err != nil {
// 	// 			fmt.Println(err)
// 	// 			continue
// 	// 		}
// 	// 		fmt.Println("received from js:", pkt)
// 	// 	}
// 	// }()
// 	SubscribeCloseSig := false
// 	go server.Subscribe(uint16(dataID), &SubscribeCloseSig)

// 	// send

// 	for {
// 		select {
// 		case pkt := <-wsPktCh:
// 			if err = ws.WriteJSON(pkt); err != nil {
// 				fmt.Println(err)
// 				continue
// 			}
// 		case <-closeSig:
// 			SubscribeCloseSig = true
// 			return nil
// 		}
// 	}
// }
