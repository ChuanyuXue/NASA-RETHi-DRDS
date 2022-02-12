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

	Count uint32
	Mu    sync.Mutex

	LocalSrc     uint8
	ClientSrc    []uint8
	ClientSrcMap map[uint8]net.UDPAddr

	inboundQueue chan *ServicePacket

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
	server.Count = 0
	server.ClientSrcMap = make(map[uint8]net.UDPAddr)

	server.inboundQueue = make(chan *ServicePacket, utils.BUFFLEN)

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

func (server *Server) Request(id uint16, synt uint32, dst uint8) error {
	// for request last data
	if synt == utils.TIME_SIMU_LAST {
		synt = server.handler.QueryLastSynt(id)
	}

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
	err = server.send(dst, uint8(data_type), utils.PRIORITY_HIGHT,
		synt, utils.OPT_REQUEST, utils.FLAG_SINGLE, id, utils.PARAMTER_EMPTY, dataMat)
	if err != nil {
		return err
	}
	return nil
}

func (server *Server) RequestRange(id uint16, timeStart uint32, timeDiff uint16, dst uint8) error {
	var dataMat [][]float64

	data_type, err := server.handler.QueryInfo(id, "data_type")
	if err != nil {
		return err
	}
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

	err = server.send(dst, uint8(data_type), utils.PRIORITY_HIGHT,
		timeStart, utils.OPT_REQUEST, utils.FLAG_SINGLE, id, timeDiff, dataMat)

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
			server.sendOpt(dst, utils.PRIORITY_HIGHT, synt, utils.OPT_RESPONSE,
				utils.FLAG_ERROR, id, utils.PARAMTER_EMPTY)
			return errors.New("published data not synchronous")
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
		rate, err := server.handler.QueryInfo(id, "data_rate")
		if err != nil {
			return err
		}
		server.publisherRegister[id] = append(server.publisherRegister[id], dst)
		server.sendOpt(dst, utils.PRIORITY_HIGHT, synt, utils.OPT_RESPONSE,
			utils.FLAG_SINGLE, id, uint16(rate))
	}

	return nil
}

func (server *Server) Subscribe(id uint16, dst uint8, synt uint32, rate uint16) error {
	if utils.Uint8Contains(server.subscriberRegister[id], dst) { // if subscriber registered
		lastSynt := server.handler.QueryLastSynt(id)
		dataType, _ := server.handler.QueryInfo(id, "data_type")
		if synt <= lastSynt {
			dataMap := make([][]float64, 0)
			for i := synt; i <= lastSynt; i++ {
				row, _ := server.handler.ReadSynt(id, i)
				dataMap = append(dataMap, row)
			}
			server.send(dst, uint8(dataType), utils.PRIORITY_HIGHT, synt,
				utils.OPT_SEND, utils.FLAG_SINGLE, id, utils.PARAMTER_EMPTY, dataMap)
		}

	} else {
		server.subscriberRegister[id] = append(server.subscriberRegister[id], dst)
		server.sendOpt(dst, utils.PRIORITY_HIGHT, synt,
			utils.OPT_RESPONSE, utils.FLAG_SINGLE, id, rate)
	}
	return nil
}

func (server *Server) send(dst uint8, types uint8, priority uint8, synt uint32, opt uint16, flag uint16, para uint16, para2 uint16, dataMap [][]float64) error {
	var pkt ServicePacket
	pkt.Src = server.LocalSrc
	pkt.Dst = dst
	pkt.MessageType = utils.MSG_OUTER
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

func (server *Server) sendOpt(dst uint8, priority uint8, synt uint32, opt uint16, flag uint16, para uint16, para2 uint16) error {
	var pkt ServicePacket
	pkt.Src = server.LocalSrc
	pkt.Dst = dst
	pkt.MessageType = utils.MSG_OUTER
	pkt.DataType = utils.TYPE_FDD
	pkt.Priority = priority
	pkt.PhysicalTime = uint32(time.Now().Unix())
	pkt.SimulinkTime = synt

	pkt.Row = 0
	pkt.Col = 0
	pkt.Length = 0

	pkt.Opt = uint16(opt)
	pkt.Flag = uint16(flag)
	pkt.Param = uint16(para)
	pkt.Subparam = uint16(para2)

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
	conn.Close()
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
				server.handle(pkt)
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

	switch pkt.Opt {
	case utils.OPT_SEND: //Send (data packet)
		rawData := PayloadBuf2Float(pkt.Payload)
		err := server.Send(pkt.Param, pkt.SimulinkTime, pkt.PhysicalTime, rawData)
		if err != nil {
			return err
		}

		// forward incoming data
		for _, dst := range server.subscriberRegister[pkt.Param] {
			var dataMat [][]float64
			for i := 0; i < int(pkt.Row); i++ {
				dataMat = append(dataMat, rawData[i*int(pkt.Col):(i+1)*int(pkt.Col)])
			}
			err = server.send(dst, pkt.DataType, pkt.Priority, pkt.SimulinkTime,
				utils.OPT_SEND, pkt.Flag, pkt.Param, pkt.Subparam, dataMat)
			if err != nil {
				fmt.Println("failed to forward data:  ", err)
				return err
			}
		}

	case utils.OPT_REQUEST: //Request (operation packet)
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

	case utils.OPT_PUBLISH: // Publish (opeartion packet / data packet)
		rawData := PayloadBuf2Float(pkt.Payload)
		err := server.Publish(pkt.Param, pkt.Src, pkt.Row, pkt.Col, pkt.SimulinkTime, pkt.PhysicalTime, rawData)
		if err != nil {
			return err
		}

		// forward if not publish regiester
		if pkt.Length == 0 {
			return nil
		}

		for _, dst := range server.subscriberRegister[pkt.Param] {
			var dataMat [][]float64
			for i := 0; i < int(pkt.Row); i++ {
				dataMat = append(dataMat, rawData[i*int(pkt.Col):(i+1)*int(pkt.Col)])
			}
			err = server.send(dst, pkt.DataType, pkt.Priority, pkt.SimulinkTime,
				utils.OPT_SEND, pkt.Flag, pkt.Param, pkt.Subparam, dataMat)
			if err != nil {
				fmt.Println("failed to forward data:  ", err)
				return err
			}

		}

	case utils.OPT_SUBSCRIBE: // Subscribe (operation packet)
		err := server.Subscribe(pkt.Param, pkt.Src, pkt.SimulinkTime, pkt.Subparam)
		if err != nil {
			return err
		}

	}

	return nil
}
