package server

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/AmyangXYZ/sgo"
	"github.com/AmyangXYZ/sgo/middlewares"
	"github.com/ChuanyuXue/NASA-RETHi-DRDS/src/handler"
	"github.com/ChuanyuXue/NASA-RETHi-DRDS/src/utils"
	"github.com/gorilla/websocket"
)

type VisualData struct {
	Timestamp uint64  `json:"timestamp"`
	Value     float64 `json:"value"`
	ID        string  `json:"id"`
}

type WebServer struct {
	utils.JsonStandard
	utils.ServiceStandard

	LocalSystemID     uint8
	AllClientSystemID []uint8

	bufferOutput chan *VisualData

	upgrader  websocket.Upgrader
	DBHandler *handler.Handler
	UDPServer *Server
}

// Init function initializes the web server
// Args:
//
//	src: the source of the web server
//	hmsServer: the pointer to the hms server
//
// Returns:
//
//	err: the error message
func (server *WebServer) Init(id uint8, udpServer *Server, port string) error {
	server.LocalSystemID = id
	server.UDPServer = udpServer
	// WebServe shared the same handler with the udp server
	server.DBHandler = server.UDPServer.handler
	server.bufferOutput = make(chan *VisualData, utils.OUTPUT_BUFFER_LEN)

	//------ init http handler
	err := server.initHttphandler(port)
	if err != nil {
		fmt.Println(err)
		return err
	}

	return nil
}

func (server *WebServer) initHttphandler(port string) error {
	// Init Http service: Please contact Jiachen if any questions
	server.upgrader = websocket.Upgrader{
		CheckOrigin:     func(r *http.Request) bool { return true },
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
	}

	app := sgo.New()
	app.USE(middlewares.CORS(middlewares.CORSOpt{}))
	app.GET("/ws", server.RealtimeProcess)
	app.GET("/history/:id", server.HistoryProcess)
	app.POST("/api/c2/:id", server.CommandProcess)
	app.OPTIONS("/api/c2/:id", sgo.PreflightHandler)

	go app.Run(port)
	return nil
}

// The event handler for websocket connection
// Args:
//   - ctx: context
//
// Return:
//   - err: error
func (server *WebServer) RealtimeProcess(ctx *sgo.Context) error {
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
	for _, dataID := range server.DBHandler.RecordTables {
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

	// send
	for {
		select {
		case data := <-server.bufferOutput:
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

// Subscribe function reads data from database and send it to the visualization. Unlike the UDP-Server
// here subscribe is not to directly forward the data from clients to visualization but to read data from database
//
// Args:
//   - id: data id
//   - closeSig: close signal
//
// Return:
//   - err: error
func (server *WebServer) Subscribe(id uint16, closeSig *bool) error {
	/* 	------------ CHUANYU APR 19 2022 MODIFICATION----------
	   	1. No history data for Visualization in the real time part anymore,
	   	History data are handled by Request function now
		2. No need to wrap the data into ServicePacket anymore, VisualData is defined for more flexible internal communication
	*/

	lastTime := server.DBHandler.QueryLastSynt(id)
	for {
		if *closeSig {
			return nil
		}
		currentTime := server.DBHandler.QueryLastSynt(id)
		_, timeVec, dataMat, err := server.DBHandler.ReadRange(id, lastTime, currentTime)
		if err != nil {
			fmt.Println(err)
			return err
		}
		for i, t := range timeVec {
			server.writeBufferOutput(
				id,
				t,
				dataMat[i],
			)
		}
		lastTime = currentTime

		time.Sleep(time.Second / time.Duration(utils.RT_STREAM_FREQ))
	}

}

// Append data to the Visualization subsystem output buffer
// Args:
//   - dataID: data id
//   - timestamp: timestamp of the data
//   - data: data vector
//
// Return:
//   - err: error
func (server *WebServer) writeBufferOutput(dataID uint16, timestamp uint64, data []float64) error {

	for i, col := range data {
		data := VisualData{
			Timestamp: timestamp,
			Value:     col,
			ID:        fmt.Sprintf("%d.%d", dataID, i),
		}
		server.bufferOutput <- &data
	}
	return nil
}

// Feed the history data to the Visualization as a list of VisualData
// Args:
//   - ctx: context
//
// Return:
//   - err: error
func (server *WebServer) HistoryProcess(ctx *sgo.Context) error {
	var dlist []VisualData
	var d VisualData

	reqs := strings.Split(ctx.Param("id"), ".")
	id, _ := strconv.ParseUint(reqs[0], 10, 16)
	col, _ := strconv.Atoi(reqs[1])

	// fmt.Println("[DEBUG]:", uint16(id), server.DBHandler.QueryLastSynt(uint16(id)))
	_, tVec, vMat, err := server.RequestRange(uint16(id), 0, server.DBHandler.QueryLastSynt(uint16(id)))

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

// Overwrite the function in ServiceStandard instead of using from server.go
//
// Args:
//   - id: data id
//   - timeStart: start time of the data
//   - timeEnd: end time of the data
//
// Return:
//   - timeSimuVec: simulation time vector
//   - timePhyVec: physical time vector
//   - dataMat: data matrix
//   - err: error
func (server *WebServer) RequestRange(id uint16, timeStart uint32, timeEnd uint32) ([]uint32, []uint64, [][]float64, error) {
	simulationTime, physicalTime, values, err := server.DBHandler.ReadRange(id, timeStart, timeEnd)
	if err != nil {
		fmt.Println(err)
		return nil, nil, nil, err
	}

	return simulationTime, physicalTime, values, nil
}

// MsgHandler handles the set-point command from the client
// Args:
//   - ctx: context
//
// Return:
//   - err: error
func (server *WebServer) CommandProcess(ctx *sgo.Context) error {
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

	var msg struct {
		Dst         uint8     `json:"dst"`
		Values      []float64 `json:"values"`
	}
	if err = json.Unmarshal(body, &msg); err != nil {
		return err
	}

	// Check if the destination is valid
	if !utils.IsValidSystemID(msg.Dst) {
		return fmt.Errorf("invalid destination: %d", msg.Dst)
	}

	dataMat := [][]float64{msg.Values}

	err = server.UDPServer.sendPkt(
		msg.Dst,
		utils.PRIORITY_NORMAL,
		uint32(utils.RESERVED),
		utils.FLAG_SINGLE,
		uint16(id),
		dataMat,
	)
	if err != nil {
		fmt.Println(err)
		return err
	}

	err = server.UDPServer.Send(
		uint16(id),
		uint32(utils.RESERVED),
		uint32(time.Now().UnixMilli()/1e3),
		dataMat[0],
	)
	if err != nil {
		fmt.Println(err)
		return err
	}

	return ctx.Text(200, "command received and forwarded")
}
