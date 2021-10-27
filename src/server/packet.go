package server

import (
	"bytes"
	"encoding/binary"
	"math"
)

type Packet struct {
	Opt      uint8
	Src      uint8
	Dst      uint8
	Type     uint8
	Param    uint8
	Priority uint8
	Row      uint8
	Col      uint8
	Length   uint16
	Time     uint32
	Payload  []byte // don't parse payload here
}

func FromBuf(buf []byte) Packet {
	var pkt Packet
	pkt.Opt = uint8(buf[0])
	pkt.Src = uint8(buf[1])
	pkt.Dst = uint8(buf[2])
	pkt.Type = uint8(buf[3])
	pkt.Param = uint8(buf[4])
	pkt.Priority = uint8(buf[5])
	pkt.Row = uint8(buf[6])
	pkt.Col = uint8(buf[7])
	pkt.Length = binary.LittleEndian.Uint16(buf[8:12])
	pkt.Time = binary.LittleEndian.Uint32(buf[12:16])
	pkt.Payload = buf[16:]

	// // check
	// if pkt.Src >= utils.SUBSNUMS ||
	// 	pkt.Dst >= utils.SUBSNUMS ||
	// 	pkt.Type >= utils.SUBSNUMS ||
	// 	pkt.Priority >= utils.SUBSNUMS ||
	// 	int(pkt.Length) != (int(pkt.Row)*int(pkt.Col)) {
	// 	fmt.Println("[!] invalid header format: [%d, %d, %d, %d, %d, %d, %d]",
	// 		pkt.Src, pkt.Dst, pkt.Type, pkt.Priority, pkt.Row, pkt.Col, pkt.Length)
	// }
	return pkt
}

func (pkt Packet) ToBuf() []byte {
	var buf [16]byte

	buf[0] = byte(pkt.Opt)
	buf[1] = byte(pkt.Src)
	buf[2] = byte(pkt.Dst)
	buf[3] = byte(pkt.Type)
	buf[4] = byte(pkt.Param)
	buf[5] = byte(pkt.Priority)
	buf[6] = byte(pkt.Row)
	buf[7] = byte(pkt.Col)

	binary.LittleEndian.PutUint16(buf[8:12], pkt.Length)
	binary.LittleEndian.PutUint32(buf[12:16], pkt.Time)
	return append(buf[:], pkt.Payload...)
}

func PayloadFloat2Buf(payload []float64) []byte {
	var buft bytes.Buffer
	for _, v := range payload {
		err := binary.Write(&buft, binary.LittleEndian, v)
		if err != nil {
			panic("Failed to convert Payload to 64bytes")
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
