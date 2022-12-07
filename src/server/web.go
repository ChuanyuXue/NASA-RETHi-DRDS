package server

import (
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
	Time  uint64  `json:"time"`
	Value float64 `json:"value"`
	ID    string  `json:"id"`
}

type VisualMsg struct {
	Time  uint64  `json:"time"`
	Value float64 `json:"value"`
	// other fields ...
}

type WebServer struct {
	utils.JsonStandard
	dataServer *Server

	upgrader   websocket.Upgrader
	wsDataChan chan *VisualData
	wsOpenSig  chan bool
}

func (server *WebServer) Init(dataServer *Server) error {
	server.dataServer = dataServer
	server.wsOpenSig = make(chan bool)
	server.wsDataChan = make(chan *VisualData, 65535)


	//------- init http communication


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

func (server *WebServer) Subscribe(id uint16, closeSig *bool) error {

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

func (server *WebServer) send(dataID uint16, timestamp uint64, data []float64) error {
	for i, col := range data {
		data := VisualData{
			Time: timestamp,
			Value:     col,
			ID:        fmt.Sprintf("%d.%d", dataID, i),
		}
		server.wsDataChan <- &data
	}
	return nil
}

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
		d = VisualData{Time: uint64(t), Value: vMat[i][col], ID: strconv.Itoa(int(id)) + "." + reqs[1]}
		dlist = append(dlist, d)
	}
	return ctx.JSON(200, 1, "success", dlist)
}


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

	go server.dataServer.send(
		utils.SRC_AGT,
		utils.PRIORITY_NORMAL,
		msg.Time,
		utils.FLAG_SINGLE,
		uint16(id),
		dataMat,
	)

	go server.dataServer.Send(
		uint16(id),
		msg.Time,
		uint32(time.Now().UnixMilli()/1e3),
		dataMat[0])

	fmt.Println(id, msg.Value)
	return ctx.Text(200, "biu")
}
