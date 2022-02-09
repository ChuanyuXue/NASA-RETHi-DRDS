package server

import (
	"data-service/src/handler"
	"data-service/src/utils"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/AmyangXYZ/sgo"
	"github.com/gorilla/websocket"
)

const (
	DATAPATH = "db_info.json"
)

type Stream struct {
	utils.JsonStandard
	utils.ServiceStandard

	Type string
	Src  string

	handler *handler.Handler

	LocalSrc  uint8
	ClientSrc []uint8

	upgrader websocket.Upgrader

	wsPktChMap map[int]chan *ServicePacket
	wsOpenSig  chan bool
}

func (server *Stream) Init(src uint8) error {
	server.LocalSrc = src
	server.Src = strconv.Itoa(int(src))

	server.wsOpenSig = make(chan bool)
	server.wsPktChMap = make(map[int]chan *ServicePacket)

	//------ init data handler

	server.handler = &handler.Handler{}
	err := server.handler.Init(server.LocalSrc)
	if err != nil {
		fmt.Println("Failed to init data handler")
		fmt.Println(err)
		return err
	}

	//------- init http communication

	dataList, err := handler.ReadDataInfo(DATAPATH)
	if err != nil {
		fmt.Println("Streaming server unable to read data description")
		return err
	}
	for _, info := range dataList {
		server.wsPktChMap[int(info.Id)] = make(chan *ServicePacket, 1024)
	}

	server.upgrader = websocket.Upgrader{
		CheckOrigin:     func(r *http.Request) bool { return true },
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
	}

	app := sgo.New()
	app.GET("/ws/:dataID", server.wsHandler)
	app.Run(":8888")

	return nil
}

func (server *Stream) Publish(id uint16) error {
	lastTime := server.handler.QueryLastSynt(id)
	firstTime := server.handler.QueryFirstSynt(id)
	dataType, _ := server.handler.QueryInfo(id, "data_type")

	timeVec, dataMat, err := server.handler.ReadRange(id, firstTime, lastTime)
	if err != nil {
		fmt.Println(err)
		return err
	}

	for i, t := range timeVec {
		server.send(
			utils.SRC_HMS,
			uint8(dataType),
			utils.PRIORITY_HIGHT,
			t,
			utils.OPT_SEND,
			utils.FLAG_SINGLE,
			id,
			uint16(lastTime-firstTime),
			dataMat[i],
		)
	}

	for {
		time.Sleep(1 * time.Second)
		currentTime := server.handler.QueryLastSynt(id)
		timeVec, dataMat, err := server.handler.ReadRange(id, lastTime, currentTime)
		if err != nil {
			fmt.Println(err)
			return err
		}
		for i, t := range timeVec {
			server.send(
				utils.SRC_HMS,
				uint8(dataType),
				utils.PRIORITY_HIGHT,
				t,
				utils.OPT_SEND,
				utils.FLAG_SINGLE,
				id,
				uint16(lastTime-firstTime),
				dataMat[i],
			)
		}
		lastTime = currentTime
	}

}

func (server *Stream) send(dst uint8, types uint8, priority uint8, synt uint32, opt uint16, flag uint16, para uint16, para2 uint16, dataMap []float64) error {
	var pkt ServicePacket
	pkt.Src = server.LocalSrc
	pkt.Dst = dst
	pkt.MessageType = utils.MSG_OUTER
	pkt.DataType = types
	pkt.Priority = priority
	pkt.PhysicalTime = uint32(time.Now().Unix())
	pkt.SimulinkTime = synt

	pkt.Row = 1
	pkt.Col = uint8(len(dataMap))
	pkt.Length = uint16(pkt.Row * pkt.Col)

	pkt.Opt = uint16(opt)
	pkt.Flag = uint16(flag)
	pkt.Param = uint16(para)
	pkt.Subparam = uint16(para2)
	pkt.Data = dataMap
	server.wsPktChMap[int(pkt.Param)] <- &pkt
	return nil
}

func (server *Stream) wsHandler(ctx *sgo.Context) error {
	ws, err := server.upgrader.Upgrade(ctx.Resp, ctx.Req, nil)
	if err != nil {
		fmt.Println(err)
		return err
	}
	defer func() {
		ws.Close()
		fmt.Println("ws/client closed")
	}()
	dataID, err := strconv.Atoi(ctx.Param("dataID"))
	if err != nil {
		fmt.Println(err)
		return err
	}
	wsPktCh := server.wsPktChMap[dataID]
	// server.wsOpenSig <- true
	// <-server.wsOpenSig
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
	// 		pkt := new(Packet)
	// 		if err = pkt.FromJSON(buf); err != nil {
	// 			fmt.Println(err)
	// 			continue
	// 		}
	// 		fmt.Println("received from js:", pkt)
	// 	}
	// }()

	go server.Publish(uint16(dataID))

	// // send

	for {
		select {
		case pkt := <-wsPktCh:
			if err = ws.WriteJSON(pkt); err != nil {
				fmt.Println(err)
				continue
			}
		case <-closeSig:
			return nil
		}
	}
}
