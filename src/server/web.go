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

// VisualData represents the data structure sent to clients for visualization.
type VisualData struct {
	Timestamp uint64  `json:"timestamp"`  // Simulation timestamp
	Phct      uint64  `json:"phct"`       // Physical time (custom physical_time)
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

// Init initializes the web server and binds it to the UDP server and HTTP handler.
func (server *WebServer) Init(id uint8, udpServer *Server, port string) error {
	server.LocalSystemID = id
	server.UDPServer = udpServer
	server.DBHandler = server.UDPServer.handler
	server.bufferOutput = make(chan *VisualData, utils.OUTPUT_BUFFER_LEN)

	err := server.initHttphandler(port)
	if err != nil {
		fmt.Println(err)
		return err
	}
	return nil
}

func (server *WebServer) initHttphandler(port string) error {
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

// RealtimeProcess handles real-time data streaming to the client via WebSocket.
func (server *WebServer) RealtimeProcess(ctx *sgo.Context) error {
	SubscribeCloseSig := false

	ws, err := server.upgrader.Upgrade(ctx.Resp, ctx.Req, nil)
	if err != nil {
		fmt.Println(err)
		return err
	}
	defer ws.Close()

	for _, dataID := range server.DBHandler.RecordTables {
		go server.Subscribe(dataID, &SubscribeCloseSig)
	}

	closeSig := make(chan bool)

	go func() {
		for {
			_, _, err := ws.ReadMessage()
			if err != nil {
				closeSig <- true
				return
			}
		}
	}()

	for {
		select {
		case data := <-server.bufferOutput:
			if err = ws.WriteJSON(data); err != nil {
				fmt.Println("[DEBUG] WebSocket send error:", err)
				continue
			}
		case <-closeSig:
			SubscribeCloseSig = true
			return nil
		}
	}
}

// Subscribe reads data from the database and sends it to the client in real time.
func (server *WebServer) Subscribe(id uint16, closeSig *bool) error {
	lastTime := server.DBHandler.QueryLastSynt(id)
	for {
		if *closeSig {
			return nil
		}
		currentTime := server.DBHandler.QueryLastSynt(id)
		simulationTime, physicalTime, dataMat, err := server.DBHandler.ReadRange(id, lastTime, currentTime)
		if err != nil {
			fmt.Println("[DEBUG] Error reading range:", err)
			return err
		}

		for i, t := range simulationTime {
			fmt.Printf("[DEBUG] Real-time Data - simulationTime: %d, physicalTime: %d\n", t, physicalTime[i])
			server.writeBufferOutput(id, uint64(t), uint64(physicalTime[i]), dataMat[i])
		}
		lastTime = currentTime
		time.Sleep(time.Second / time.Duration(utils.RT_STREAM_FREQ))
	}
}

// writeBufferOutput sends data to the visualization buffer with simulation and physical timestamps.
func (server *WebServer) writeBufferOutput(dataID uint16, timestamp uint64, phct uint64, data []float64) error {
	fmt.Printf("[DEBUG] Buffer Output - Timestamp: %d, Phct: %d\n", timestamp, phct)
	for i, col := range data {
		data := VisualData{
			Timestamp: timestamp,
			Phct:      phct,
			Value:     col,
			ID:        fmt.Sprintf("%d.%d", dataID, i),
		}
		server.bufferOutput <- &data
	}
	return nil
}

// HistoryProcess returns historical data as a JSON list of VisualData.
func (server *WebServer) HistoryProcess(ctx *sgo.Context) error {
	var dlist []VisualData

	reqs := strings.Split(ctx.Param("id"), ".")
	id, _ := strconv.ParseUint(reqs[0], 10, 16)
	col, _ := strconv.Atoi(reqs[1])

	simulationTime, physicalTime, vMat, err := server.RequestRange(uint16(id), 0, server.DBHandler.QueryLastSynt(uint16(id)))
	if err != nil {
		fmt.Println("[DEBUG] Error in RequestRange:", err)
		return err
	}
	for i, t := range simulationTime {
		fmt.Printf("[DEBUG] History Data - simulationTime: %d, physicalTime: %d\n", t, physicalTime[i])
		dlist = append(dlist, VisualData{
			Timestamp: t,
			Phct:      physicalTime[i],
			Value:     vMat[i][col],
			ID:        strconv.Itoa(int(id)) + "." + reqs[1],
		})
	}
	return ctx.JSON(200, 1, "success", dlist)
}

// RequestRange retrieves simulation and physical timestamps from the database.
func (server *WebServer) RequestRange(id uint16, timeStart uint32, timeEnd uint32) ([]uint64, []uint64, [][]float64, error) {
	simulationTime, physicalTime, values, err := server.DBHandler.ReadRange(id, timeStart, timeEnd)
	if err != nil {
		fmt.Println("[DEBUG] Error in RequestRange:", err)
		return nil, nil, nil, err
	}

	// Convert []uint32 to []uint64
	simTime64 := make([]uint64, len(simulationTime))
	phyTime64 := make([]uint64, len(physicalTime))
	for i := range simulationTime {
		simTime64[i] = uint64(simulationTime[i])
		phyTime64[i] = uint64(physicalTime[i])
	}

	fmt.Printf("[DEBUG] RequestRange - simulationTime: %+v\n", simTime64)
	fmt.Printf("[DEBUG] RequestRange - physicalTime: %+v\n", phyTime64)

	return simTime64, phyTime64, values, nil
}

// CommandProcess handles incoming commands from the frontend.
func (server *WebServer) CommandProcess(ctx *sgo.Context) error {
	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil {
		fmt.Println("[DEBUG] Invalid ID:", err)
		return err
	}
	body, err := ioutil.ReadAll(ctx.Req.Body)
	if err != nil {
		fmt.Println("[DEBUG] Error reading body:", err)
		return err
	}

	var msg struct {
		Dst         uint8     `json:"dst"`
		Phct        uint64    `json:"phct"`
		Synt        uint32    `json:"synt"`
		Values      []float64 `json:"values"`
	}
	if err = json.Unmarshal(body, &msg); err != nil {
		fmt.Println("[DEBUG] JSON unmarshal error:", err)
		return err
	}

	dataMat := [][]float64{msg.Values}
	err = server.UDPServer.sendPkt(msg.Dst, utils.PRIORITY_NORMAL, msg.Synt, utils.FLAG_SINGLE, uint16(id), dataMat, uint32(msg.Phct))
	if err != nil {
		fmt.Println("[DEBUG] Error sending packet:", err)
		return err
	}
	return ctx.Text(200, "command received and forwarded")
}
