package server

import (
	"errors"
	"os"
	"strconv"
	"sync"
	"sync/atomic"
	"time"

	"fmt"
	"net"

	"github.com/ChuanyuXue/NASA-RETHi-DRDS/src/handler"
	"github.com/ChuanyuXue/NASA-RETHi-DRDS/src/utils"
)

type Server struct {
	utils.JsonStandard
	utils.ServiceStandard

	Type string
	Src  string

	handler *handler.Handler

	LocalSystemID uint8
	AllLocalAddr  []*net.UDPAddr

	UDPProcduerNums uint16
	UDPConsumerNums uint16

	AllClientSystemID []uint8
	AllClientAddr     map[uint8]*net.UDPAddr

	Buffer   chan *[utils.PKTLEN]byte
	Sequence uint16
	mu       sync.Mutex

	count uint64

	publisherRegister      map[uint16][]uint8
	publisherRegisterLock  sync.RWMutex
	subscriberRegister     map[uint16][]uint8
	subscriberRegisterLock sync.RWMutex
}

func (server *Server) Init(src uint8) error {
	err := server.initID(src)
	if err != nil {
		return err
	}

	err = server.initAddr()
	if err != nil {
		return err
	}

	err = server.initDBHander()
	if err != nil {
		return err
	}

	server.initService()

	go func() {
		for {
			time.Sleep(5 * time.Second)
			receivedPackets := atomic.LoadUint64(&server.count)
			currentTime := time.Now().Format("2006-01-02 15:04:05")
			fmt.Printf("%s - Received packets: %d\n", currentTime, receivedPackets)
		}
	}()

	return nil
}

func (server *Server) initID(src uint8) error {
	server.LocalSystemID = src
	if server.LocalSystemID == utils.SYSTEM_ID["GCC"] {
		server.Type = "GROUND"
	}
	if server.LocalSystemID == utils.SYSTEM_ID["HMS"] {
		server.Type = "HABITAT"
	}

	server.AllClientSystemID = []uint8{}
	for _, value := range utils.SYSTEM_ID {
		if value == server.LocalSystemID {
			continue
		}
		server.AllClientSystemID = append(server.AllClientSystemID, value)
	}
	return nil
}

func (server *Server) initAddr() error {
	server.AllLocalAddr = []*net.UDPAddr{}

	localAddrNet, err := net.ResolveUDPAddr("udp", os.Getenv("DS_LOCAL_ADDR_"+server.Type))
	if err != nil {
		return fmt.Errorf("unable to resolve local address for %s", server.Type)
	}
	server.AllLocalAddr = append(server.AllLocalAddr, localAddrNet)

	localAddrLoop, err := net.ResolveUDPAddr("udp", os.Getenv("DS_LOCAL_LOOP_"+server.Type))
	if err != nil {
		return errors.New("unable to resolve local loop")
	}
	server.AllLocalAddr = append(server.AllLocalAddr, localAddrLoop)

	server.AllClientAddr = make(map[uint8]*net.UDPAddr)
	remoteAddr, err := net.ResolveUDPAddr("udp", os.Getenv("DS_REMOTE_ADDR_"+server.Type))
	if err != nil {
		return fmt.Errorf("unable to resolve remote address for %s", server.Type)
	}
	for _, key := range server.AllClientSystemID {
		server.AllClientAddr[uint8(key)] = remoteAddr
	}

	remoteAddrLoop, err := net.ResolveUDPAddr("udp", os.Getenv("DS_REMOTE_LOOP_"+server.Type))
	if err != nil {
		return errors.New("unable to resolve remote loop")
	}
	server.AllClientAddr[server.LocalSystemID] = remoteAddrLoop
	return nil
}

func (server *Server) initDBHander() error {
	server.handler = &handler.Handler{}
	err := server.handler.Init(server.LocalSystemID)
	if err != nil {
		fmt.Println("Failed to init data handler", err)
		return err
	}
	return nil
}

func (server *Server) initService() {
	server.Sequence = 0
	server.publisherRegister = make(map[uint16][]uint8)
	server.subscriberRegister = make(map[uint16][]uint8)
	server.publisherRegisterLock = sync.RWMutex{}
	server.subscriberRegisterLock = sync.RWMutex{}
	server.Buffer = make(chan *[utils.PKTLEN]byte, utils.BUFFLEN)

	producerNum, err := strconv.ParseUint(os.Getenv("DB_PRODUCER_NUM"), 10, 16)
	if err != nil {
		server.UDPProcduerNums = utils.PROCUDER_NUMS
	} else {
		server.UDPProcduerNums = uint16(producerNum)
	}

	consumerNum, err := strconv.ParseUint(os.Getenv("DB_CONSUMER_NUM"), 10, 16)
	if err != nil {
		server.UDPConsumerNums = utils.CONSUMER_NUMS
	} else {
		server.UDPConsumerNums = uint16(consumerNum)
	}

	for _, localAddr := range server.AllLocalAddr {
		go server.listen(localAddr)
	}
}

func (server *Server) Send(id uint16, time uint32, physical_time uint32, rawData []float64) error {
	data := &handler.Data{Iter: time, SendT: physical_time, Value: rawData}
	err := server.handler.WriteToBuffer(id, data)
	if err != nil {
		fmt.Println(err)
		return err
	}
	return nil
}

func (server *Server) Request(id uint16, synt uint32, dst uint8, priority uint8) error {
	if synt == utils.TIME_SIMU_LAST {
		synt = server.handler.QueryLastSynt(id)
	}

	_, data, err := server.handler.ReadSynt(id, synt)
	if err != nil {
		return err
	}
	var dataMat [][]float64
	dataMat = append(dataMat, data)
	err = server.sendPkt(dst, priority, synt, utils.FLAG_SINGLE, id, dataMat, synt)
	if err != nil {
		return err
	}
	return nil
}

func (server *Server) RequestRange(id uint16, timeStart uint32, timeDiff uint16, dst uint8, priority uint8) error {
	var dataMat [][]float64
	var err error

	if timeDiff == utils.PARAMTER_REQUEST_LAST {
		_, _, dataMat, err = server.handler.ReadRange(id, timeStart, server.handler.QueryLastSynt(id))
		if err != nil {
			fmt.Println(err)
			return err
		}
	} else {
		_, _, dataMat, err = server.handler.ReadRange(id, timeStart, timeStart+uint32(timeDiff))
		if err != nil {
			fmt.Println(err)
			return err
		}
	}

	err = server.sendPkt(dst, utils.PRIORITY_HIGHT,
		timeStart, utils.FLAG_SINGLE, id, dataMat, timeStart)

	if err != nil {
		return err
	}
	return nil
}

func (server *Server) Publish(id uint16, dst uint8, rows uint8, cols uint8, synt uint32, physical_time uint32, rawData []float64) error {
	server.publisherRegisterLock.RLock()
	isPublisherRegistered := utils.Uint8Contains(server.publisherRegister[id], dst)
	server.publisherRegisterLock.RUnlock()

	if isPublisherRegistered {
		lastSynt := server.handler.QueryLastSynt(id)
		if synt < lastSynt {
			server.sendOpt(dst, utils.PRIORITY_HIGHT, synt, utils.SER_RESPONSE, utils.FLAG_ERROR, utils.RESERVED, utils.RESERVED)
			return errors.New("published data are not synchronized with current database")
		}

		col := int(cols)
		for row := 0; row < int(rows); row++ {
			data := &handler.Data{
				Iter:  synt + uint32(row),
				SendT: physical_time,
				Value: rawData[row*col : (row+1)*col],
			}
			err := server.handler.WriteToBuffer(id, data)
			if err != nil {
				return err
			}
		}

	} else {
		server.publisherRegisterLock.Lock()
		server.publisherRegister[id] = append(server.publisherRegister[id], dst)
		server.publisherRegisterLock.Unlock()

		server.sendOpt(dst, utils.PRIORITY_HIGHT, synt, utils.SER_RESPONSE,
			utils.FLAG_SINGLE, utils.RESERVED, utils.RESERVED)
	}

	return nil
}

func (server *Server) Subscribe(id uint16, dst uint8, synt uint32, rate uint16) error {
	server.subscriberRegisterLock.RLock()
	isSubscriberRegistered := utils.Uint8Contains(server.subscriberRegister[id], dst)
	server.subscriberRegisterLock.RUnlock()
	if isSubscriberRegistered {
		lastSynt := server.handler.QueryLastSynt(id)
		if synt <= lastSynt {
			dataMap := make([][]float64, 0)
			for i := synt; i <= lastSynt; i++ {
				_, row, _ := server.handler.ReadSynt(id, i)
				dataMap = append(dataMap, row)
			}
			server.sendPkt(dst, utils.PRIORITY_MEDIUM, synt, utils.FLAG_SINGLE, id, dataMap, synt)
		}
	} else {
		server.subscriberRegisterLock.Lock()
		server.subscriberRegister[id] = append(server.subscriberRegister[id], dst)
		server.subscriberRegisterLock.Unlock()
	}
	err := server.sendOpt(dst, utils.PRIORITY_HIGHT, synt, utils.SER_RESPONSE, utils.FLAG_SINGLE, utils.RESERVED, utils.RESERVED)
	if err != nil {
		return err
	}
	return nil
}

func (server *Server) sendPkt(dst uint8, priority uint8, synt uint32, flag uint8, data_id uint16, dataMap [][]float64, phct uint32) error {
	var pkt ServicePacket
	pkt.Src = server.LocalSystemID
	pkt.Dst = dst
	pkt.MessageType = utils.MSG_OUTER
	pkt.Priority = priority
	pkt.Version = utils.VERSION_V0
	pkt.Reserved = utils.RESERVED
	pkt.PhysicalTime = phct
	pkt.SimulinkTime = synt
	server.mu.Lock()
	pkt.Sequence = server.Sequence
	server.Sequence += 1
	server.mu.Unlock()

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

	dstAddr := server.AllClientAddr[dst]
	conn, err := net.DialUDP("udp", nil, dstAddr)

	if err != nil {
		fmt.Println("[!] Failed to dial clients")
		return err
	}
	defer conn.Close()
	_, err = conn.Write(pkt.ToServiceBuf())
	if err != nil {
		fmt.Println("[!] Failed to send data to clients")
		return err
	}

	return nil
}

func (server *Server) sendOpt(dst uint8, priority uint8, synt uint32, service uint8, flag uint8, opt1 uint8, opt2 uint8) error {
	var pkt ServicePacket
	pkt.Src = server.LocalSystemID
	pkt.Dst = dst
	pkt.MessageType = utils.MSG_OUTER
	pkt.Priority = priority
	pkt.Version = utils.VERSION_V0
	pkt.Reserved = utils.RESERVED
	pkt.PhysicalTime = uint32(time.Now().UnixMilli() / 1e3)
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

	dstAddr := server.AllClientAddr[dst]
	conn, err := net.DialUDP("udp", nil, dstAddr)
	if err != nil {
		fmt.Println("Failed to dial clients")
		return err
	}
	defer conn.Close()

	fmt.Println("[DEBUG]: Send OPT to", dst)
	fmt.Println("[DEBUG]:", dstAddr.IP)
	fmt.Println("[DEBUG]:", dstAddr.Port)

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

func (server *Server) listen(addr *net.UDPAddr) {
	for i := 0; i < int(server.UDPConsumerNums); i++ {
		go func() {
			for {
				select {
				case buf := <-server.Buffer:
					pkt := FromServiceBuf(buf[:])
					err := server.handlePkt(&pkt)
					if err != nil {
						fmt.Println("Failed to handle packet")
						fmt.Println(err)
					}
				}
			}
		}()
	}

	conn, _ := net.ListenUDP("udp", addr)
	for i := 0; i < int(server.UDPProcduerNums); i++ {
		go func() {
			for {
				var buf [utils.PKTLEN]byte
				_, _, err := conn.ReadFromUDP(buf[:])
				atomic.AddUint64(&server.count, 1)
				if err != nil {
					fmt.Println("Failed to listen packet from connection")
					fmt.Println(err)
				}
				server.Buffer <- &buf
			}
		}()
	}
	select {}
}

func (server *Server) handlePkt(pkt *ServicePacket) error {
	switch pkt.Service {
	case utils.SER_SEND:
		for _, subpkt := range pkt.Subpackets {
			rawData := PayloadBuf2Float(subpkt.Payload)
			go server.Send(subpkt.DataID, pkt.SimulinkTime+uint32(subpkt.TimeDiff), pkt.PhysicalTime, rawData)

			server.subscriberRegisterLock.RLock()
			subscribers, ok := server.subscriberRegister[subpkt.DataID]
			server.subscriberRegisterLock.RUnlock()

			if ok {
				for _, dst := range subscribers {
					var dataMat [][]float64
					for i := 0; i < int(subpkt.Row); i++ {
						dataMat = append(dataMat, rawData[i*int(subpkt.Col):(i+1)*int(subpkt.Col)])
					}
					go server.sendPkt(dst, pkt.Priority, pkt.SimulinkTime, pkt.Flag, subpkt.DataID, dataMat, pkt.PhysicalTime)
				}
			}
		}

	case utils.SER_REQUEST:
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

	case utils.SER_PUBLISH:
		rawData := PayloadBuf2Float(pkt.Payload)
		for _, subpkt := range pkt.Subpackets {
			go server.Publish(subpkt.DataID, pkt.Src, subpkt.Row, subpkt.Col, pkt.SimulinkTime+uint32(subpkt.TimeDiff), pkt.PhysicalTime, rawData)

			if subpkt.Length == 0 {
				return nil
			}

			server.subscriberRegisterLock.RLock()
			subscribers, ok := server.subscriberRegister[subpkt.DataID]
			server.subscriberRegisterLock.RUnlock()

			if ok {
				for _, dst := range subscribers {
					var dataMat [][]float64
					for i := 0; i < int(subpkt.Row); i++ {
						dataMat = append(dataMat, rawData[i*int(subpkt.Col):(i+1)*int(subpkt.Col)])
					}
					go server.sendPkt(dst, pkt.Priority, pkt.SimulinkTime, pkt.Flag, subpkt.DataID, dataMat, pkt.PhysicalTime)
				}
			}
		}

	case utils.SER_SUBSCRIBE:
		for _, subpkt := range pkt.Subpackets {
			err := server.Subscribe(subpkt.DataID, pkt.Src, pkt.SimulinkTime, subpkt.TimeDiff)
			if err != nil {
				return err
			}
		}
	}

	return nil
}