package communicator

import (
	"bytes"
	"datarepo/src/utils"
	"encoding/binary"
	"fmt"
	"math"
)

type Packet struct {
	Src      uint8
	Dst      uint8
	Type     uint8
	Priority uint8
	Row      uint8
	Col      uint8
	Length   uint16
	// Payload  []byte // don't parse payload here
	Payload []float64
}

func FromBuf(buf []byte) Packet {
	var pkt Packet
	pkt.Src = uint8(buf[0])
	pkt.Dst = uint8(buf[1])
	pkt.Type = uint8(buf[2])
	pkt.Priority = uint8(buf[3])
	pkt.Row = uint8(buf[4])
	pkt.Col = uint8(buf[5])
	pkt.Length = binary.LittleEndian.Uint16(buf[6:8])
	// pkt.Payload = buf[8:]
	pkt.Payload = PayloadBuf2Float(buf[8:])

	// check
	if int(pkt.Src) >= utils.SUBSNUMS ||
		int(pkt.Dst) >= utils.SUBSNUMS ||
		int(pkt.Type) >= utils.SUBSNUMS ||
		int(pkt.Priority) >= utils.SUBSNUMS ||
		int(pkt.Length) != (int(pkt.Row)*int(pkt.Col)) {
		fmt.Println("[!] invalid header format: [%d, %d, %d, %d, %d, %d, %d]",
			pkt.Src, pkt.Dst, pkt.Type, pkt.Priority, pkt.Row, pkt.Col, pkt.Length)
	}
	return pkt
}

func (pkt Packet) ToBuf() []byte {
	var buf [8]byte

	buf[0] = byte(pkt.Src)
	buf[1] = byte(pkt.Dst)
	buf[2] = byte(pkt.Type)
	buf[3] = byte(pkt.Priority)
	buf[4] = byte(pkt.Row)
	buf[5] = byte(pkt.Col)
	binary.LittleEndian.PutUint16(buf[6:8], pkt.Length)
	return append(buf[:], PayloadFloat2Buf(pkt.Payload)...)
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
