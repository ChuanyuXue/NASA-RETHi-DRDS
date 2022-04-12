package server

import (
	"data-service/src/handler"
	"data-service/src/utils"
	"errors"
	"os"
	"sync"
	"time"

	// "errors"
	"fmt"
	"net"
)

type Server struct {
	utils.JsonStandard
	utils.ServiceStandard

	Type string
	Src  string

	handler *handler.Handler

	LocalSrc     uint8
	ClientSrc    []uint8
	ClientSrcMap map[uint8]net.UDPAddr

	inboundQueue chan *ServicePacket
	Sequence     uint16
	mu           sync.Mutex

	publisherRegister  map[uint16][]uint8 // publisherRegister[data_id] = [client_0, ....]
	subscriberRegister map[uint16][]uint8 // subscriberRegister[data_id] = [client_0, ....]
}

func (server *Server) Init(src uint8) error {
	// -------------------------- Fix the paramter for docker envirioment
	if src == utils.SRC_GCC {
		server.Type = "GROUND"
		server.ClientSrc = []uint8{
			utils.SRC_AGT,
			utils.SRC_ECLSS,
			utils.SRC_EXT,
			utils.SRC_HMS,
			utils.SRC_ING,
			utils.SRC_PWR,
			utils.SRC_STR}

	} else if src == utils.SRC_HMS {
		server.Type = "HABITAT"
		server.ClientSrc = []uint8{
			utils.SRC_AGT,
			utils.SRC_ECLSS,
			utils.SRC_EXT,
			utils.SRC_GCC,
			utils.SRC_ING,
			utils.SRC_PWR,
			utils.SRC_STR}
	}
	server.Src = string(src)
	server.LocalSrc = uint8(src)
	server.ClientSrcMap = make(map[uint8]net.UDPAddr)

	server.inboundQueue = make(chan *ServicePacket, utils.BUFFLEN)
	server.Sequence = 0

	localAddr, err := net.ResolveUDPAddr("udp", os.Getenv("DS_LOCAL_ADDR_"+server.Type))
	if err != nil {
		return errors.New(fmt.Sprintf("unable to resolve local address for %s", server.Type))
	}
	remoteAddr, err := net.ResolveUDPAddr("udp", os.Getenv("DS_REMOTE_ADDR_"+server.Type))
	if err != nil {
		return errors.New(fmt.Sprintf("unable to resolve remote address for %s", server.Type))
	}
	loopAddr, err := net.ResolveUDPAddr("udp", os.Getenv("DS_LOCAL_LOOP_"+server.Type))
	if err != nil {
		return errors.New("unable to resolve local loop")
	}

	for key := range server.ClientSrc {
		server.ClientSrcMap[uint8(key)] = *remoteAddr
	}

	remoteAddr, err = net.ResolveUDPAddr("udp", os.Getenv("DS_REMOTE_LOOP_"+server.Type))
	if err != nil {
		return errors.New("unable to resolve remote loop")
	}
	server.ClientSrcMap[uint8(src)] = *remoteAddr

	// -------------------------- Fix the paramter for docker envirioment
	// Init data service handler
	server.handler = &handler.Handler{}
	err = server.handler.Init(server.LocalSrc)
	if err != nil {
		fmt.Println("Failed to init data handler")
		fmt.Println(err)
		return err
	}

	server.publisherRegister = make(map[uint16][]uint8)
	server.subscriberRegister = make(map[uint16][]uint8)

	go server.listen(localAddr, int(utils.PROCNUMS))
	go server.listen(loopAddr, int(utils.PROCNUMS))

	return nil
}

func (server *Server) Send(id uint16, time uint32, physical_time uint32, rawData []float64) error {
	err := server.handler.WriteSynt(id, time, physical_time, rawData)
	if err != nil {
		return err
	}
	return nil
}

func (server *Server) Request(id uint16, synt uint32, dst uint8, priority uint8) error {
	// for request last data
	// fmt.Println("[2]Test: Last time stamp", synt, utils.TIME_SIMU_LAST)
	if synt == utils.TIME_SIMU_LAST {
		// fmt.Println("[1]Test: Last time stamp", synt, utils.TIME_SIMU_LAST)
		synt = server.handler.QueryLastSynt(id)
		// fmt.Println("[3]Test: Last time stamp", synt, utils.TIME_SIMU_LAST)
	}

	data, err := server.handler.ReadSynt(id, synt)
	if err != nil {
		return err
	}
	if err != nil {

		return err
	}
	var dataMat [][]float64
	dataMat = append(dataMat, data)
	err = server.send(dst, priority, synt, utils.FLAG_SINGLE, id, dataMat)
	if err != nil {
		return err
	}
	return nil
}

func (server *Server) RequestRange(id uint16, timeStart uint32, timeDiff uint16, dst uint8, priority uint8) error {
	var dataMat [][]float64
	var err error

	if timeDiff == utils.PARAMTER_REQUEST_LAST {
		_, dataMat, err = server.handler.ReadRange(id, timeStart, server.handler.QueryLastSynt(id))
		if err != nil {
			fmt.Println(err)
			return err
		}
	} else {
		_, dataMat, err = server.handler.ReadRange(id, timeStart, timeStart+uint32(timeDiff))
		if err != nil {
			fmt.Println(err)
			return err
		}
	}

	err = server.send(dst, utils.PRIORITY_HIGHT,
		timeStart, utils.FLAG_SINGLE, id, dataMat)

	if err != nil {
		return err
	}
	return nil
}

func (server *Server) Publish(id uint16, dst uint8, rows uint8, cols uint8, synt uint32, physical_time uint32, rawData []float64) error {
	if utils.Uint8Contains(server.publisherRegister[id], dst) { // if publisher registered
		// if para2 is stop streaming
		lastSynt := server.handler.QueryLastSynt(id)
		if synt < lastSynt {
			// Send error back to dst
			server.sendOpt(dst, utils.PRIORITY_HIGHT, synt, utils.SER_RESPONSE, utils.FLAG_ERROR, utils.RESERVED, utils.RESERVED)
			return errors.New("Published data are not synchronized with current DataBase")
		}

		col := int(cols)
		for row := 0; row < int(rows); row++ {
			server.handler.WriteSynt(id,
				synt+uint32(row),
				physical_time,
				rawData[row*col:(row+1)*col],
			)
		}
	} else {
		server.publisherRegister[id] = append(server.publisherRegister[id], dst)

		server.sendOpt(dst, utils.PRIORITY_HIGHT, synt, utils.SER_RESPONSE,
			utils.FLAG_SINGLE, utils.RESERVED, utils.RESERVED)
	}

	return nil
}

func (server *Server) Subscribe(id uint16, dst uint8, synt uint32, rate uint16) error {
	if utils.Uint8Contains(server.subscriberRegister[id], dst) { // if subscriber registered
		lastSynt := server.handler.QueryLastSynt(id)
		if synt <= lastSynt {
			dataMap := make([][]float64, 0)
			for i := synt; i <= lastSynt; i++ {
				row, _ := server.handler.ReadSynt(id, i)
				dataMap = append(dataMap, row)
			}
			server.send(dst, utils.PRIORITY_MEDIUM, synt, utils.FLAG_SINGLE, id, dataMap)
		}

	} else {
		server.subscriberRegister[id] = append(server.subscriberRegister[id], dst)
		server.sendOpt(dst, utils.PRIORITY_HIGHT, synt,
			utils.SER_RESPONSE, utils.FLAG_SINGLE, utils.RESERVED, utils.RESERVED)
	}
	return nil
}

func (server *Server) send(dst uint8, priority uint8, synt uint32, flag uint8, data_id uint16, dataMap [][]float64) error {
	var pkt ServicePacket
	pkt.Src = server.LocalSrc
	pkt.Dst = dst
	pkt.MessageType = utils.MSG_OUTER
	pkt.Priority = priority
	pkt.Version = utils.VERSION_V0
	pkt.Reserved = utils.RESERVED
	pkt.PhysicalTime = uint32(time.Now().Unix())
	pkt.SimulinkTime = synt
	server.mu.Lock()
	pkt.Sequence = server.Sequence
	server.Sequence += 1
	server.mu.Unlock()

	// calculate ROW and COL
	var row uint8
	var col uint8
	row = uint8(len(dataMap))
	if len(dataMap) == 0 {
		col = uint8(0)
	} else {
		col = uint8(len(dataMap[0]))
	}
	pkt.Length = uint16(utils.SERVICE_HEADER_LEN) + uint16(utils.SUB_HEADER_LEN) + uint16(row)*uint16(col)*8

	pkt.Service = utils.SER_SEND
	pkt.Flag = flag
	pkt.Option1 = utils.RESERVED
	pkt.Option2 = utils.RESERVED
	pkt.SubframeNum = 1

	var subpkt = SubPacket{}
	subpkt.DataID = data_id
	subpkt.TimeDiff = uint16(utils.RESERVED)
	subpkt.Row = row
	subpkt.Col = col
	subpkt.Length = uint16(row) * uint16(col)

	var dataFlatten []float64
	for _, row := range dataMap {
		dataFlatten = append(dataFlatten, row...)
	}

	subpkt.Payload = PayloadFloat2Buf(dataFlatten)
	pkt.Subpackets = append(pkt.Subpackets, &subpkt)

	dstAddr := server.ClientSrcMap[dst]
	conn, err := net.DialUDP("udp", nil, &dstAddr)

	if err != nil {
		fmt.Println("Failed to dial clients")
		return err
	}
	defer conn.Close()
	_, err = conn.Write(pkt.ToServiceBuf())
	if err != nil {
		fmt.Println("Failed to send data to clients")
		return err
	}

	return nil
}

func (server *Server) sendOpt(dst uint8, priority uint8, synt uint32, service uint8, flag uint8, opt1 uint8, opt2 uint8) error {
	var pkt ServicePacket
	pkt.Src = server.LocalSrc
	pkt.Dst = dst
	pkt.MessageType = utils.MSG_OUTER
	pkt.Priority = priority
	pkt.Version = utils.VERSION_V0
	pkt.Reserved = utils.RESERVED
	pkt.PhysicalTime = uint32(time.Now().Unix())
	pkt.SimulinkTime = synt
	server.mu.Lock()
	pkt.Sequence = server.Sequence
	server.Sequence += 1
	server.mu.Unlock()
	pkt.Length = uint16(utils.SERVICE_HEADER_LEN)

	pkt.Service = service
	pkt.Flag = flag
	pkt.Option1 = opt1
	pkt.Option2 = opt2
	pkt.SubframeNum = 0

	dstAddr := server.ClientSrcMap[dst]
	conn, err := net.DialUDP("udp", nil, &dstAddr)
	if err != nil {
		fmt.Println("Failed to dial clients")
		return err
	}
	defer conn.Close()

	_, err = conn.Write(pkt.ToServiceBuf())
	if err != nil {
		fmt.Println("Failed to send data to clients")
		return err
	}

	server.mu.Lock()
	server.Sequence++
	server.mu.Unlock()

	return nil
}

func (server *Server) listen(addr *net.UDPAddr, procnums int) error {
	conn, err := net.ListenUDP("udp", addr)
	if err != nil {
		fmt.Println("Failed to bind client", addr, err)
		return err
	}

	// consumer
	for i := 0; i < procnums; i++ {
		go func() {
			for {
				pkt := <-server.inboundQueue
				err = server.handle(pkt)
				if err != nil {
					fmt.Println(err)
				}
			}
		}()
	}

	// producer

	for {
		var buf [utils.BUFFLEN]byte
		_, _, err := conn.ReadFromUDP(buf[:])
		if err != nil {
			fmt.Println("Failed to listen packet from connection")
		}
		pkt := FromServiceBuf(buf[:])
		server.inboundQueue <- &pkt
	}
}

func (server *Server) handle(pkt *ServicePacket) error {
	// fmt.Println("SimTime:", pkt.SimulinkTime, " ------ Insert into table record", pkt.Param)

	// // --------- For latency test ---------
	// server.Mu.Lock()
	// fmt.Println("Pkt index:", server.Count, "----- Time:", int(time.Now().UnixNano()))
	// pkt.SimulinkTime = server.Count
	// server.Count += 1
	// server.Mu.Unlock()
	// // ----------------------------------

	// fmt.Println("Receive data -> ", pkt.SubframeNum)
	// for _, subpkt := range pkt.Subpackets {
	// 	fmt.Println(subpkt.DataID, subpkt.Row, subpkt.Col, subpkt.Length)
	// }

	switch pkt.Service {
	case utils.SER_SEND: //Send (data packet)
		for _, subpkt := range pkt.Subpackets {
			rawData := PayloadBuf2Float(subpkt.Payload)
			err := server.Send(subpkt.DataID, pkt.SimulinkTime+uint32(subpkt.TimeDiff), pkt.PhysicalTime, rawData)
			if err != nil {
				return err
			}
			for _, dst := range server.subscriberRegister[subpkt.DataID] {
				var dataMat [][]float64
				for i := 0; i < int(subpkt.Row); i++ {
					dataMat = append(dataMat, rawData[i*int(subpkt.Col):(i+1)*int(subpkt.Col)])
				}
				err = server.send(dst, pkt.Priority, pkt.SimulinkTime, pkt.Flag, subpkt.DataID, dataMat)
				if err != nil {
					fmt.Println("failed to forward data:  ", err)
					return err
				}
			}
		}

	case utils.SER_REQUEST: //Request (operation packet)
		// Time diff used to tell the end time of request
		// fmt.Println("[-]Test4", pkt.Service)
		for _, subpkt := range pkt.Subpackets {
			if subpkt.TimeDiff == 0 {

				err := server.Request(subpkt.DataID, pkt.SimulinkTime, pkt.Src, pkt.Priority)
				if err != nil {
					return err
				}
			} else if subpkt.TimeDiff > 0 {
				err := server.RequestRange(subpkt.DataID, pkt.SimulinkTime, subpkt.TimeDiff, pkt.Src, pkt.Priority)
				if err != nil {
					return err
				}
			}
		}

	case utils.SER_PUBLISH: // Publish (opeartion packet / data packet)

		rawData := PayloadBuf2Float(pkt.Payload)
		for _, subpkt := range pkt.Subpackets {
			err := server.Publish(subpkt.DataID, pkt.Src, subpkt.Row, subpkt.Col, pkt.SimulinkTime+uint32(subpkt.TimeDiff), pkt.PhysicalTime, rawData)
			if err != nil {
				return err
			}

			if subpkt.Length == 0 {
				return nil
			}
			for _, dst := range server.subscriberRegister[subpkt.DataID] {
				var dataMat [][]float64
				for i := 0; i < int(subpkt.Row); i++ {
					dataMat = append(dataMat, rawData[i*int(subpkt.Col):(i+1)*int(subpkt.Col)])
				}
				err = server.send(dst, pkt.Priority, pkt.SimulinkTime, pkt.Flag, subpkt.DataID, dataMat)
				if err != nil {
					fmt.Println("failed to forward data:  ", err)
					return err
				}
			}

		}

		// forward if not publish regiester

	case utils.SER_SUBSCRIBE: // Subscribe (operation packet)
		for _, subpkt := range pkt.Subpackets {
			err := server.Subscribe(subpkt.DataID, pkt.Src, pkt.SimulinkTime, subpkt.TimeDiff)
			if err != nil {
				return err
			}
		}

	}

	return nil
}
