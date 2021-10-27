package server

import (
	"datarepo/src/handler"
	"datarepo/src/utils"
	"fmt"
	"net"
	"strconv"
	"sync"
)

type UdpServer struct {
	Server
	utils.JsonStandard
	utils.ServiceStandard

	handler *handler.Handler

	addr         net.UDPAddr
	clientSrc    []uint8
	clientSrcMap map[uint8]net.UDPAddr
}

func (udpServer *UdpServer) Init() error {
	// Init data service server
	var (
		addr net.UDPAddr
		err  error
	)

	if udpServer.Public == "NA" {
		addr.Port, err = utils.StringToInt(udpServer.Port)
		addr.IP = net.ParseIP(udpServer.Local)
	} else {
		addr.Port, err = utils.StringToInt(udpServer.Port)
		addr.IP = net.ParseIP(udpServer.Public)
	}
	if err != nil {
		fmt.Println(err)
		return err
	}
	udpServer.addr = addr
	udpServer.clientSrc = make([]uint8, len(udpServer.ClientsSrc))
	udpServer.clientSrcMap = make(map[uint8]net.UDPAddr)

	for i := range udpServer.Clients {
		addr.Port, err = utils.StringToInt(udpServer.ClientsPort[i])
		addr.IP = net.ParseIP(udpServer.Clients[i])
		if err != nil {
			fmt.Println("Failed to load clients configuration")
			return err
		}
		if addr.IP == nil {
			fmt.Println("Failed to load clients configuration")
		}

		clientSrc, _ := strconv.Atoi(udpServer.ClientsSrc[i])
		udpServer.clientSrc[i] = uint8(clientSrc)
		udpServer.clientSrcMap[uint8(clientSrc)] = addr
	}

	// Init data service handler
	udpServer.handler = &handler.Handler{}
	utils.LoadFromJson("config/database_configs.json", udpServer.handler)
	err = udpServer.handler.Init()
	if err != nil {
		fmt.Println("Failed to init data handler")
		panic(err)
	}

	// Start Service -- For multi port
	// var wg sync.WaitGroup
	// for _, v := range udpServer.clientSrc {
	// 	wg.Add(1)
	// 	go udpServer.listen(v, &wg)
	// }
	// wg.Wait()

	// Start Service -- For single port
	udpServer.listen(udpServer.addr, nil)

	return nil
}

func (udpServer *UdpServer) Send(id uint8, time uint32, rawData []float64) error {
	err := udpServer.handler.WriteSynt(id, time, rawData)
	if err != nil {
		return err
	}
	return nil
}

func (udpServer *UdpServer) Request(id uint8, time uint32, dst uint8) error {
	data, err := udpServer.handler.ReadSynt(id, time)
	if err != nil {
		return err
	}
	var dataMat [][]float64
	dataMat = append(dataMat, data)
	err = udpServer.send(dst, dataMat)
	if err != nil {
		return err
	}
	return nil
}

func (udpServer *UdpServer) RequestRange(id uint8, timeStart uint32, timeEnd uint32, dst uint8) error {
	var dataMat [][]float64

	for i := timeStart; i <= timeEnd; i++ {
		data, err := udpServer.handler.ReadSynt(id, i)
		if err != nil {
			return err
		}
		dataMat = append(dataMat, data)
	}

	err := udpServer.send(dst, dataMat)
	if err != nil {
		return err
	}
	return nil
}

func (udpServer *UdpServer) send(dst uint8, dataMap [][]float64) error {
	var pkt Packet
	src, _ := utils.StringToInt(udpServer.Src)
	pkt.Src = uint8(src)
	pkt.Dst = dst
	pkt.Opt = 0      // send data
	pkt.Param = 0    // No param in response current stage
	pkt.Priority = 0 // No priority response in current stage
	pkt.Time = 0     // No time response in current stage
	pkt.Type = 0     // No type response in current stage
	pkt.Row = uint8(len(dataMap))
	pkt.Col = uint8(len(dataMap[0]))
	pkt.Length = uint16(pkt.Row * pkt.Col)

	var dataFlatten []float64
	for _, row := range dataMap {
		dataFlatten = append(dataFlatten, row...)
	}

	pkt.Payload = PayloadFloat2Buf(dataFlatten)
	dstAddr := udpServer.clientSrcMap[dst]
	conn, err := net.DialUDP("udp", nil, &dstAddr)
	if err != nil {
		fmt.Println("Failed to build connection to clients")
		return err
	}

	_, err = conn.Write(pkt.ToBuf())
	if err != nil {
		fmt.Println("Failed to send data to clients")
		return err
	}
	return nil
}

func (udpServer *UdpServer) listen(addr net.UDPAddr, wg *sync.WaitGroup) error {
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
		pkt := FromBuf(buf[:])
		err = udpServer.handle(pkt)
		if err != nil {
			fmt.Println(err)
		}
	}
}

func (udpServer *UdpServer) handle(pkt Packet) error {
	switch pkt.Opt {
	case 0:
		rawData := PayloadBuf2Float(pkt.Payload)
		err := udpServer.Send(pkt.Param, pkt.Time, rawData)
		if err != nil {
			return err
		}
	case 1:
		if pkt.Length == 1 {
			err := udpServer.Request(pkt.Param, pkt.Time, pkt.Src)
			if err != nil {
				return err
			}
		} else if pkt.Length >= 1 {
			err := udpServer.RequestRange(pkt.Param, pkt.Time, pkt.Time+uint32(pkt.Length), pkt.Src)
			if err != nil {
				return err
			}
		}
	}

	return nil
}
