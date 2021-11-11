package server

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"math"
)

type Packet struct {
	Src          uint8  `json:"-"`
	Dst          uint8  `json:"-"`
	TransType    uint8  `json:"-"`
	MessageType  uint8  `json:"-"`
	DataType     uint8  `json:"data_type"`
	Priority     uint8  `json:"priority"`
	PhysicalTime uint32 `json:"phy_time"`
	SimulinkTime uint32 `json:"sim_time"`
	Row          uint8  `json:"row"`
	Col          uint8  `json:"col"`
	Length       uint16 `json:"len"`
	Payload      []byte `json:"payload"`
}

func FromBuf(buf []byte) Packet {
	var pkt Packet
	pkt.Src = uint8(buf[0])
	pkt.Dst = uint8(buf[1])
	temp := binary.LittleEndian.Uint16(buf[2:4])
	pkt.MessageType = uint8(temp >> 12 & 0x0f)
	pkt.DataType = uint8(temp >> 4 & 0xff)
	pkt.Priority = uint8(temp & 0x0f)
	pkt.PhysicalTime = uint32(binary.LittleEndian.Uint16(buf[4:8]))
	pkt.SimulinkTime = uint32(binary.LittleEndian.Uint16(buf[8:12]))
	pkt.Row = uint8(buf[12])
	pkt.Col = uint8(buf[13])
	pkt.Length = binary.LittleEndian.Uint16(buf[14:16])
	pkt.Payload = buf[16:]
	pkt.TransType = 0
	return pkt
}

func (pkt Packet) ToBuf() []byte {
	var buf [16]byte
	buf[0] = byte(pkt.Src)
	buf[1] = byte(pkt.Dst)
	temp := uint16(pkt.MessageType)<<12 + uint16(pkt.DataType)<<4 + uint16(pkt.Priority)
	binary.LittleEndian.PutUint16(buf[2:4], uint16(temp))
	binary.LittleEndian.PutUint16(buf[4:8], uint16(pkt.PhysicalTime))
	binary.LittleEndian.PutUint16(buf[8:12], uint16(pkt.SimulinkTime))
	buf[12] = byte(pkt.Row)
	buf[13] = byte(pkt.Col)
	binary.LittleEndian.PutUint16(buf[14:16], uint16(pkt.Length))
	return append(buf[:], pkt.Payload...)
}

func PayloadFloat2Buf(payload []float64) []byte {
	var buft bytes.Buffer
	for _, v := range payload {
		err := binary.Write(&buft, binary.LittleEndian, v)
		if err != nil {
			fmt.Println("Failed to convert Payload to 64bytes")
		}
	}
	return buft.Bytes()
}

func PayloadBuf2Float(buf []byte) []float64 {
	var data64 []float64

	for i := range buf {
		if i%8 == 0 {
			targetBuf := buf[i : i+8]
			data64 = append(data64, Float64frombytes(targetBuf))
		}
	}
	return data64
}

func Float64frombytes(bytes []byte) float64 {
	bits := binary.LittleEndian.Uint64(bytes)
	float := math.Float64frombits(bits)
	return float
}

type ServicePacket struct {
	Packet
	Opt      uint16 `json:"opt"`
	Flag     uint16 `json:"flag"`
	Param    uint16 `json:"param"`
	Subparam uint16 `json:"subparam"`
}

func (pkt *ServicePacket) ToServiceBuf() []byte {
	var buf [24]byte
	buf[0] = byte(pkt.Src)
	buf[1] = byte(pkt.Dst)
	temp := uint16(pkt.MessageType)<<12 + uint16(pkt.DataType)<<4 + uint16(pkt.Priority)
	binary.LittleEndian.PutUint16(buf[2:4], uint16(temp))
	binary.LittleEndian.PutUint32(buf[4:8], uint32(pkt.PhysicalTime))
	binary.LittleEndian.PutUint32(buf[8:12], uint32(pkt.SimulinkTime))
	buf[12] = byte(pkt.Row)
	buf[13] = byte(pkt.Col)
	binary.LittleEndian.PutUint16(buf[14:16], uint16(pkt.Length))

	binary.LittleEndian.PutUint16(buf[16:18], uint16(pkt.Opt))
	binary.LittleEndian.PutUint16(buf[18:20], uint16(pkt.Flag))
	binary.LittleEndian.PutUint16(buf[20:22], uint16(pkt.Param))
	binary.LittleEndian.PutUint16(buf[22:24], uint16(pkt.Subparam))
	return append(buf[:], pkt.Payload...)
}

func FromServiceBuf(buf []byte) ServicePacket {
	pkt := FromBuf(buf)
	servicePkt := ServicePacket{}
	servicePkt.Opt = binary.LittleEndian.Uint16(pkt.Payload[:2])
	servicePkt.Flag = binary.LittleEndian.Uint16(pkt.Payload[2:4])
	servicePkt.Param = binary.LittleEndian.Uint16(pkt.Payload[4:6])
	servicePkt.Subparam = binary.LittleEndian.Uint16(pkt.Payload[6:8])
	pkt.Payload = pkt.Payload[8:]
	servicePkt.Packet = pkt
	return servicePkt
}

func FromJSON(buf []byte) ServicePacket {
	var pkt ServicePacket
	json.Unmarshal(buf, &pkt)
	pkt.MessageType = 1
	return pkt
}
