package server

import (
	"data-service/src/handler"
	"data-service/src/utils"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/AmyangXYZ/sgo"
	"github.com/AmyangXYZ/sgo/middlewares"
	"github.com/gorilla/websocket"
)

const (
	DATAPATH = "db_info.json"
)

type VisualData struct {
	Timestamp uint64  `json:"timestamp"`
	Value     float64 `json:"value"`
	ID        string  `json:"id"`
}

type C2Msg struct {
	Value float64 `json:"value"`
	Time  uint32  `json:"time"`
	// other fields ...
}

type WebServer struct {
	utils.JsonStandard
	utils.ServiceStandard

	Type string
	Src  string

	handler   *handler.Handler
	hmsServer *Server

	LocalSrc  uint8
	ClientSrc []uint8

	upgrader websocket.Upgrader

	wsDataChan chan *VisualData
	wsOpenSig  chan bool
}

func (server *WebServer) Init(src uint8, hmsServer *Server) error {
	server.LocalSrc = src
	server.Src = strconv.Itoa(int(src))

	server.hmsServer = hmsServer
	server.wsOpenSig = make(chan bool)
	server.wsDataChan = make(chan *VisualData, 65535)

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
	app.GET("/history/:id", server.httpHistory)

	app.POST("/api/c2/:id", server.msgHandler)
	app.OPTIONS("/api/c2/:id", sgo.PreflightHandler)

	app.Run(":9999")

	return nil
}

// Overwrite the function in ServiceStandard instead of using from server.go
// Args:
// 	- id: data id
// 	- timeStart: start time of the data
// 	- timeEnd: end time of the data
// Return:
// 	- timeSimuVec: simulation time vector
// 	- timePhyVec: physical time vector
// 	- dataMat: data matrix
// 	- err: error
func (server *WebServer) RequestRange(id uint16, timeStart uint32, timeEnd uint32) ([]uint32, []uint64, [][]float64, error) {
	// fmt.Println("[2] Debug: RequestRange")
	var dataMat [][]float64
	var timeSimuVec []uint32
	var timePhyVec []uint64
	var err error

	timeSimuVec, timePhyVec, dataMat, err = server.handler.ReadRange(id, timeStart, timeEnd)
	if err != nil {
		fmt.Println(err)
		return nil, nil, nil, err
	}

	return timeSimuVec, timePhyVec, dataMat, nil
}

// Overwrite the function in ServiceStandard instead of using from server.go
// The main loop to feed Visualization subsystem with real-time data
// Args:
// 	- id: data id
// 	- closeSig: close signal
// Return:
// 	- err: error
func (server *WebServer) Subscribe(id uint16, closeSig *bool) error {
	// fmt.Println("[1] Debug: Subscribe")

	/* 	------------ CHUANYU APR 19 2022 MODIFICATION-------------------------
	   	1. No history data for Visualization in the real time part anymore,
	   	History data are handled by Request function now
		2. No need to wrap the data into ServicePacket anymore, VisualData is defined for more flexible internal communication
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
				id,
				t,
				dataMat[i],
			)
		}
		lastTime = currentTime
	}

}

// A wrapper function to format the data into VisualData
// Args:
// 	- dataID: data id
// 	- timestamp: timestamp of the data
// 	- data: data vector
// Return:
// 	- err: error
func (server *WebServer) send(dataID uint16, timestamp uint64, data []float64) error {

	for i, col := range data {
		data := VisualData{
			Timestamp: timestamp,
			Value:     col,
			ID:        fmt.Sprintf("%d.%d", dataID, i),
		}
		server.wsDataChan <- &data
	}

	// fmt.Println("[3] Debug: send")
	// var pkt ServicePacket
	// pkt.Src = server.LocalSrc
	// pkt.Dst = dst
	// pkt.MessageType = utils.MSG_OUTER
	// pkt.Priority = priority
	// pkt.PhysicalTime = uint64(time.Now().UnixMilli())
	// pkt.SimulinkTime = synt

	// var subpkt SubPacket

	// subpkt.DataID = dataID
	// subpkt.Row = 1
	// subpkt.Col = uint8(len(dataMap))
	// subpkt.Length = uint16(subpkt.Row * subpkt.Col)

	// pkt.Service = utils.SER_SEND
	// pkt.Flag = utils.FLAG_SINGLE
	// pkt.Option1 = utils.RESERVED
	// pkt.Option2 = option2
	// pkt.Data = dataMap
	// pkt.Subpackets = make([]*SubPacket, 0)
	// pkt.Subpackets = append(pkt.Subpackets, &subpkt)

	// channel <- &pkt
	// server.wsPktChMap[int(subpkt.DataID)] <- &pkt
	return nil
}

// The event handler for websocket connection
// Args:
// 	- ctx: context
// Return:
// 	- err: error
func (server *WebServer) wsRealTime(ctx *sgo.Context) error {
	// fmt.Println("[4] Debug: wsReadTime")
	SubscribeCloseSig := false

	ws, err := server.upgrader.Upgrade(ctx.Resp, ctx.Req, nil)
	if err != nil {
		fmt.Println(err)
		return err
	}
	defer func() {
		ws.Close()
		fmt.Println("ws/Client closed")
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
		case data := <-server.wsDataChan:
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

// Feed the history data to the Visualization as a list of VisualData
// Args:
// 	- ctx: context
// Return:
// 	- err: error
func (server *WebServer) httpHistory(ctx *sgo.Context) error {
	var dlist []VisualData
	var d VisualData

	reqs := strings.Split(ctx.Param("id"), ".")
	id, _ := strconv.ParseUint(reqs[0], 10, 16)
	col, _ := strconv.Atoi(reqs[1])

	// start, _ := strconv.ParseUint(ctx.Param("start"), 10, 32)
	// end, _ := strconv.ParseUint(ctx.Param("end"), 10, 32)

	// fmt.Println("[5] Debug: wsHistory")

	_, tVec, vMat, err := server.RequestRange(uint16(id), 0, server.handler.QueryLastSynt(uint16(id)))
	// _, tVec, vMat, err := server.RequestRange(uint16(id), uint32(start), uint16(uint32(end)-uint32(start)))
	if err != nil {
		fmt.Println(err)
		return err
	}
	for i, t := range tVec {
		// fmt.Println(uint64(t)*1000, vMat[i][col], strconv.Itoa(int(id))+"."+reqs[1])
		d = VisualData{Timestamp: uint64(t), Value: vMat[i][col], ID: strconv.Itoa(int(id)) + "." + reqs[1]}
		dlist = append(dlist, d)
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

// MsgHandler handles the set-point command from the client
// Args:
// 	- ctx: context
// Return:
// 	- err: error
func (server *WebServer) msgHandler(ctx *sgo.Context) error {
	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil {
		fmt.Println(err)
		return err
	}
	body, err := ioutil.ReadAll(ctx.Req.Body)
	if err != nil {
		fmt.Println(err)
		return err
	}
	var msg C2Msg
	if err = json.Unmarshal(body, &msg); err != nil {
		return err
	}

	var dataMat [][]float64
	var rawData []float64
	rawData = append(rawData, msg.Value)
	dataMat = append(dataMat, rawData)

	go server.hmsServer.send(
		utils.SRC_AGT,
		utils.PRIORITY_NORMAL,
		msg.Time,
		utils.FLAG_SINGLE,
		uint16(id),
		dataMat,
	)

	go server.hmsServer.Send(
		uint16(id),
		msg.Time,
		uint32(time.Now().UnixMilli()),
		dataMat[0])

	fmt.Println(id, msg.Value)
	return ctx.Text(200, "command received and forwarded")
}
