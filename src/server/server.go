package server

import (
	"datarepo/src/handler"
	"datarepo/src/utils"
	"time"

	// "errors"
	"fmt"
	"net"
	"strconv"
	"sync"
)

type Server struct {
	utils.JsonStandard
	utils.ServiceStandard

	Local       string   `json:"local"`
	Public      string   `json:"public"`
	Port        string   `json:"port"`
	Type        string   `json:"type"`
	Src         string   `json:"src"`
	Clients     []string `json:"clients"`
	ClientsPort []string `json:"clients_port"`
	ClientsSrc  []string `json:"clients_src"`

	handler *handler.Handler

	addr         net.UDPAddr
	clientSrc    []uint8
	clientSrcMap map[uint8]net.UDPAddr

	publisherRigister  map[uint8][]uint8 // publisherRigister[data_id] = [client_0, ....]
	subscriberRigister map[uint8][]uint8 // subscriberRigister[data_id] = [client_0, ....]
}

func (server *Server) Init() error {
	// Init data service server
	var (
		addr net.UDPAddr
		err  error
	)

	if server.Public == "NA" {
		addr.Port, err = utils.StringToInt(server.Port)
		addr.IP = net.ParseIP(server.Local)
	} else {
		addr.Port, err = utils.StringToInt(server.Port)
		addr.IP = net.ParseIP(server.Public)
	}
	if err != nil {
		fmt.Println(err)
		return err
	}
	server.addr = addr
	server.clientSrc = make([]uint8, len(server.ClientsSrc))
	server.clientSrcMap = make(map[uint8]net.UDPAddr)

	for i := range server.Clients {
		addr.Port, err = utils.StringToInt(server.ClientsPort[i])
		addr.IP = net.ParseIP(server.Clients[i])
		if err != nil {
			fmt.Println("Failed to load clients configuration")
			return err
		}
		if addr.IP == nil {
			fmt.Println("Failed to load clients configuration")
		}

		clientSrc, _ := strconv.Atoi(server.ClientsSrc[i])
		server.clientSrc[i] = uint8(clientSrc)
		server.clientSrcMap[uint8(clientSrc)] = addr
	}

	// Init data service handler
	server.handler = &handler.Handler{}
	utils.LoadFromJson("config/database_configs.json", server.handler)
	err = server.handler.Init()
	if err != nil {
		fmt.Println("Failed to init data handler")
		panic(err)
	}

	server.publisherRigister = make(map[uint8][]uint8)
	server.subscriberRigister = make(map[uint8][]uint8)

	// Start Service -- For single port
	server.listen(server.addr, nil)

	return nil
}

func (server *Server) Send(id uint16, time uint32, rawData []float64) error {
	err := server.handler.WriteSynt(id, time, rawData)
	if err != nil {
		return err
	}
	return nil
}

func (server *Server) Request(id uint16, synt uint32, dst uint8) error {
	data, err := server.handler.ReadSynt(id, synt)
	if err != nil {
		return err
	}
	data_type, err := server.handler.QueryInfo(id, "data_type")
	if err != nil {
		return err
	}
	var dataMat [][]float64
	dataMat = append(dataMat, data)
	// opt = 0, types = 0, priority = 7
	err = server.send(dst, uint8(data_type), 7, synt, 1, 0, id, 0, dataMat)
	if err != nil {
		return err
	}
	return nil
}

func (server *Server) RequestRange(id uint16, timeStart uint32, timeDiff uint16, dst uint8) error {
	var dataMat [][]float64

	for i := uint16(0); i < timeDiff; i++ {
		data, err := server.handler.ReadSynt(id, timeStart+uint32(i))
		if err != nil {
			return err
		}
		dataMat = append(dataMat, data)
	}

	data_type, err := server.handler.QueryInfo(id, "data_type")
	if err != nil {
		return err
	}

	err = server.send(dst, uint8(data_type), 7, timeStart, 1, 0, id, timeDiff, dataMat)
	if err != nil {
		return err
	}
	return nil
}

func (server *Server) Publish(id uint16, dst uint8, para1 uint8, para2 uint8, time uint32, rawData []float64) error {
	if utils.Uint8Contains(server.publisherRigister[id], dst) { // if publisher registered
		// if para2 is stop streaming
		lastSynt := server.handler.QueryLastSynt(id)
		if time != lastSynt+1 {
			// Send error back to dst
			return errors.New("published data not synchronous")
		}

		col := int(para2)
		for row := 0; row < int(para1); row++ {
			server.handler.WriteSynt(id,
				time+uint32(row),
				rawData[row*col:(row+1)*col],
			)
		}
	} else {
		rate, err := server.handler.QueryInfo(id, "data_rate")
		if err != nil {
			return err
		}
		server.publisherRigister[id] = append(server.publisherRigister[id], dst)
		server.sendOpt(dst, 2, id, uint8(rate), 0, 7, time)
	}

	return nil
}

// func (server *Server) Subscribe(id uint8, dst uint8, para1 uint8, para2 uint8, time uint32) error {
// 	if utils.Uint8Contains(server.subscriberRigister[id], dst) { // if subscriber registered
// 		lastSynt := server.handler.QueryLastSynt(id)
// 		if time <= lastSynt {
// 			for i := time; i <= lastSynt; i++ {
// 				row, _ := server.handler.ReadSynt(id, i)
// 				dataMap := make([][]float64, 0)
// 				dataMap = append(dataMap, row)
// 				server.send(dst, 3, id, 0, 7, i, dataMap)
// 			}
// 		}

// 	} else {
// 		server.subscriberRigister[id] = append(server.subscriberRigister[id], dst)
// 		server.sendOpt(dst, 3, id, 1, 0, 7, time)
// 	}
// 	return nil
// }

func (server *Server) send(dst uint8, types uint8, priority uint8, synt uint32, opt uint16, flag uint16, para uint16, para2 uint16, dataMap [][]float64) error {
	var pkt ServicePacket
	src, _ := utils.StringToInt(server.Src)
	pkt.Src = uint8(src)
	pkt.Dst = dst
	pkt.MessageType = 1
	pkt.DataType = types
	pkt.Priority = priority
	pkt.PhysicalTime = uint32(time.Now().Unix())
	pkt.SimulinkTime = synt

	pkt.Row = uint8(len(dataMap))
	pkt.Col = uint8(len(dataMap[0]))
	pkt.Length = uint16(pkt.Row * pkt.Col)

	pkt.Opt = uint16(opt)
	pkt.Flag = uint16(flag)
	pkt.Param = uint16(para)
	pkt.Subparam = uint16(para2)

	var dataFlatten []float64
	for _, row := range dataMap {
		dataFlatten = append(dataFlatten, row...)
	}

	pkt.Payload = PayloadFloat2Buf(dataFlatten)
	dstAddr := server.clientSrcMap[dst]
	conn, err := net.DialUDP("udp", nil, &dstAddr)
	if err != nil {
		fmt.Println("Failed to build connection to clients")
		return err
	}

	_, err = conn.Write(pkt.ToServiceBuf())
	if err != nil {
		fmt.Println("Failed to send data to clients")
		return err
	}
	return nil
}

func (server *Server) sendOpt(dst uint8, priority uint8, pt uint32, synt uint32, opt uint8, flag uint8, para uint8, para2 uint8) error {
	var pkt ServicePacket
	src, _ := utils.StringToInt(server.Src)
	pkt.Src = uint8(src)
	pkt.Dst = dst
	pkt.MessageType = 1
	pkt.DataType = 0
	pkt.Priority = priority
	pkt.PhysicalTime = pt
	pkt.SimulinkTime = synt

	pkt.Row = 0
	pkt.Col = 0
	pkt.Length = 0

	pkt.Opt = uint16(opt)
	pkt.Flag = uint16(flag)
	pkt.Param = uint16(para)
	pkt.Subparam = uint16(para2)

	dstAddr := server.clientSrcMap[dst]
	conn, err := net.DialUDP("udp", nil, &dstAddr)
	if err != nil {
		fmt.Println("Failed to build connection to clients")
		return err
	}

	_, err = conn.Write(pkt.ToServiceBuf())
	if err != nil {
		fmt.Println("Failed to send data to clients")
		return err
	}
	return nil
}

func (server *Server) listen(addr net.UDPAddr, wg *sync.WaitGroup) error {
	if wg != nil {
		defer wg.Done()
	}
	conn, err := net.ListenUDP("udp", &addr)
	if err != nil {
		fmt.Println("Failed to build connection to clients")
		return err
	}

	var buf [utils.BUFFLEN]byte
	for {
		_, _, err := conn.ReadFromUDP(buf[:])
		if err != nil {
			fmt.Println("Failed to listen packet from connection")
		}
		pkt := FromServiceBuf(buf[:])
		err = server.handle(pkt)
		if err != nil {
			fmt.Println(err)
		}
	}
}

func (server *Server) handle(pkt ServicePacket) error {
	switch pkt.Opt {
	case 0: //Send (data packet)
		rawData := PayloadBuf2Float(pkt.Payload)
		err := server.Send(pkt.Param, pkt.SimulinkTime, rawData)
		if err != nil {
			return err
		}

		// // forward incoming data
		// if utils.Uint8Contains(server.subscriberRigister[pkt.Param], pkt.Src) && (pkt.Length != 0) {
		// 	var dataMat [][]float64
		// 	for i := 0; i < int(pkt.Row); i++ {
		// 		dataMat = append(dataMat, rawData[i*int(pkt.Col):(i+1)*int(pkt.Col)])
		// 	}
		// 	server.send(pkt.Src, 3, pkt.Param, pkt.Type, pkt.Priority, pkt.Time, dataMat)
		// }

	case 1: //Request (operation packet)
		if pkt.Subparam == 1 {
			err := server.Request(pkt.Param, pkt.SimulinkTime, pkt.Src)
			if err != nil {
				return err
			}
		} else if pkt.Subparam > 1 {
			err := server.RequestRange(pkt.Param, pkt.SimulinkTime, pkt.Subparam, pkt.Src)
			if err != nil {
				return err
			}
		}

		case 2: // Publish (opeartion packet / data packet)
			rawData := PayloadBuf2Float(pkt.Payload)
			err := server.Publish(pkt.Param, pkt.Src, pkt.Row, pkt.Col, pkt.Time, rawData)
			if err != nil {
				return err
			}

		// 	// forward incoming data
		// 	if utils.Uint8Contains(server.subscriberRigister[pkt.Param], pkt.Src) && (pkt.Length != 0) {
		// 		var dataMat [][]float64
		// 		for i := 0; i < int(pkt.Row); i++ {
		// 			dataMat = append(dataMat, rawData[i*int(pkt.Col):(i+1)*int(pkt.Col)])
		// 		}
		// 		server.send(pkt.Src, 3, pkt.Param, pkt.Type, pkt.Priority, pkt.Time, dataMat)
		// 	}

		// case 3: // Subscribe (operation packet)
		// 	err := server.Subscribe(pkt.Param, pkt.Src, pkt.Row, pkt.Col, pkt.Time)
		// 	if err != nil {
		// 		return err
		// 	}
		//
	}

	return nil
}
