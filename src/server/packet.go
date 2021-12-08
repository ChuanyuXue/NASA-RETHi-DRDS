package server

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"math"
)

type Packet struct {
	Src          uint8
	Dst          uint8
	MessageType  uint8
	DataType     uint8
	Priority     uint8
	PhysicalTime uint32
	SimulinkTime uint32
	Row          uint8
	Col          uint8
	Length       uint16
	Payload      []byte // don't parse payload here
}

func FromBuf(buf []byte) Packet {
	var pkt Packet
	pkt.Src = uint8(buf[0])
	pkt.Dst = uint8(buf[1])
	temp := binary.BigEndian.Uint16(buf[2:4])
	pkt.MessageType = uint8(temp >> 12 & 0x0f)
	pkt.DataType = uint8(temp >> 4 & 0xff)
	pkt.Priority = uint8(temp & 0x0f)
	pkt.PhysicalTime = uint32(binary.BigEndian.Uint32(buf[4:8]))
	pkt.SimulinkTime = uint32(binary.BigEndian.Uint32(buf[8:12]))
	pkt.Row = uint8(buf[12])
	pkt.Col = uint8(buf[13])
	pkt.Length = binary.BigEndian.Uint16(buf[14:16])
	pkt.Payload = buf[16:]
	return pkt
}

func (pkt Packet) ToBuf() []byte {
	var buf [16]byte
	buf[0] = byte(pkt.Src)
	buf[1] = byte(pkt.Dst)
	temp := uint16(pkt.MessageType)<<12 + uint16(pkt.DataType)<<4 + uint16(pkt.Priority)
	binary.BigEndian.PutUint16(buf[2:4], uint16(temp))
	binary.BigEndian.PutUint32(buf[4:8], uint32(pkt.PhysicalTime))
	binary.BigEndian.PutUint32(buf[8:12], uint32(pkt.SimulinkTime))
	buf[12] = byte(pkt.Row)
	buf[13] = byte(pkt.Col)
	binary.BigEndian.PutUint16(buf[14:16], uint16(pkt.Length))
	return append(buf[:], pkt.Payload...)
}

func PayloadFloat2Buf(payload []float64) []byte {
	var buft bytes.Buffer
	for _, v := range payload {
		err := binary.Write(&buft, binary.BigEndian, v)
		if err != nil {
			fmt.Println("Failed to convert Payload to 64bytes")
		}
	}
	return buft.Bytes()
}

func PayloadBuf2Float(buf []byte) []float64 {
	var data64 []float64

	for i, _ := range buf {
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
	Opt      uint16
	Flag     uint16
	Param    uint16
	Subparam uint16
}

func (pkt *ServicePacket) ToServiceBuf() []byte {
	var buf [24]byte
	buf[0] = byte(pkt.Src)
	buf[1] = byte(pkt.Dst)
	temp := uint16(pkt.MessageType)<<12 + uint16(pkt.DataType)<<4 + uint16(pkt.Priority)
	binary.BigEndian.PutUint16(buf[2:4], uint16(temp))
	binary.BigEndian.PutUint32(buf[4:8], uint32(pkt.PhysicalTime))
	binary.BigEndian.PutUint32(buf[8:12], uint32(pkt.SimulinkTime))
	buf[12] = byte(pkt.Row)
	buf[13] = byte(pkt.Col)
	binary.BigEndian.PutUint16(buf[14:16], uint16(pkt.Length))

	binary.BigEndian.PutUint16(buf[16:18], uint16(pkt.Opt))
	binary.BigEndian.PutUint16(buf[18:20], uint16(pkt.Flag))
	binary.BigEndian.PutUint16(buf[20:22], uint16(pkt.Param))
	binary.BigEndian.PutUint16(buf[22:24], uint16(pkt.Subparam))

	return append(buf[:], pkt.Payload...)
}

func FromServiceBuf(buf []byte) ServicePacket {
	pkt := FromBuf(buf)
	servicePkt := ServicePacket{}
	servicePkt.Opt = binary.BigEndian.Uint16(pkt.Payload[:2])
	servicePkt.Flag = binary.BigEndian.Uint16(pkt.Payload[2:4])
	servicePkt.Param = binary.BigEndian.Uint16(pkt.Payload[4:6])
	servicePkt.Subparam = binary.BigEndian.Uint16(pkt.Payload[6:8])
	pkt.Payload = pkt.Payload[8:]
	servicePkt.Packet = pkt

	return servicePkt
}
