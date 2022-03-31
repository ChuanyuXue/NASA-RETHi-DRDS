package server

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"math"
)

type Packet struct {
	Src          uint8  `json:"src"`
	Dst          uint8  `json:"dst"`
	MessageType  uint8  `json:"message_type"`
	Priority     uint8  `json:"priority"`
	Version      uint8  `json:"version"`
	Reserved     uint8  `json:"reserved"`
	PhysicalTime uint32 `json:"physical_time"`
	SimulinkTime uint32 `json:"simulink_time"`
	Sequence     uint16 `json:"sequence"`
	Length       uint16 `json:"length"`
	Payload      []byte `json:"-"`

	// for visualization
	Data []float64 `json:"data"`
}

//                     1                   2                   3
// 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |      SRC      |       DST     | TYPE  | PRIO  |  VER  |  RES  |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                     PHYSICAL_TIMESTAMP                        |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                     SIMULINK_TIMESTAMP                        |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |            SEQUENCE           |              LEN              |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |      DATA…
// +-+-+-+-+-+-+-+-+

func FromBuf(buf []byte) Packet {
	var pkt Packet
	pkt.Src = uint8(buf[0])
	pkt.Dst = uint8(buf[1])
	temp := binary.BigEndian.Uint16(buf[2:4])
	pkt.MessageType = uint8(temp >> 12)
	pkt.Priority = uint8(temp >> 8 & 0x0f)
	pkt.Version = uint8(temp >> 4 & 0x0f)
	pkt.Reserved = uint8(temp & 0x0f)
	pkt.PhysicalTime = uint32(binary.BigEndian.Uint32(buf[4:8]))
	pkt.SimulinkTime = uint32(binary.BigEndian.Uint32(buf[8:12]))
	pkt.Sequence = binary.BigEndian.Uint16(buf[12:14])
	pkt.Length = binary.BigEndian.Uint16(buf[14:16])
	pkt.Payload = buf[16:]
	return pkt
}

func (pkt Packet) ToBuf() []byte {
	var buf [16]byte
	buf[0] = byte(pkt.Src)
	buf[1] = byte(pkt.Dst)
	temp := uint16(pkt.MessageType)<<12 + uint16(pkt.Priority)<<8 + uint16(pkt.Version)<<4 + uint16(pkt.Reserved)
	binary.BigEndian.PutUint16(buf[2:4], uint16(temp))
	binary.BigEndian.PutUint32(buf[4:8], uint32(pkt.PhysicalTime))
	binary.BigEndian.PutUint32(buf[8:12], uint32(pkt.SimulinkTime))
	binary.BigEndian.PutUint16(buf[12:14], uint16(pkt.Sequence))
	binary.BigEndian.PutUint16(buf[14:16], uint16(pkt.Length))
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

//                     1                   2                   3
// 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |      SRC      |       DST     | TYPE  | PRIO  |  VER  |  RES  |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                     PHYSICAL_TIMESTAMP                        |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                     SIMULINK_TIMESTAMP                        |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |            SEQUENCE           |              LEN              |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |    SERVICE    |     FLAG      |    OPTION1    |    OPTION2    |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |          SUBFRAME_NUM         |            DATA_ID            |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |           TIME_DIFF           |      ROW      |      COL      |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |            LENGTH             |             DATA...
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

type ServicePacket struct {
	Packet
	Service     uint8    `json:service`
	Flag        uint8    `json:flag`
	Option1     uint8    `json:option1`
	Option2     uint8    `json:option2`
	SubframeNum uint16   `json:subframe_num`
	DataIDArr   []uint16 `json:data_id`
	TimeDiffArr []uint16
	RowArr      []uint8  `json:row`
	ColArr      []uint8  `json:col`
	LengthArr   []uint16 `json:length`
	PayloadArr  [][]byte `json:"-"`
}

func (pkt *ServicePacket) ToServiceBuf() []byte {
	var buf [16]byte
	var bufExt []byte

	buf[0] = byte(pkt.Src)
	buf[1] = byte(pkt.Dst)
	temp := uint16(pkt.MessageType)<<12 + uint16(pkt.Priority)<<8 + uint16(pkt.Version)<<4 + uint16(pkt.Reserved)
	binary.BigEndian.PutUint16(buf[2:4], uint16(temp))
	binary.BigEndian.PutUint32(buf[4:8], uint32(pkt.PhysicalTime))
	binary.BigEndian.PutUint32(buf[8:12], uint32(pkt.SimulinkTime))
	binary.BigEndian.PutUint16(buf[12:14], uint16(pkt.Sequence))
	binary.BigEndian.PutUint16(buf[14:16], uint16(pkt.Length))

	bufExt = append(bufExt, buf[:]...)
	bufExt = append(bufExt, byte(pkt.Service))
	bufExt = append(bufExt, byte(pkt.Flag))
	bufExt = append(bufExt, byte(pkt.Option1))
	bufExt = append(bufExt, byte(pkt.Option2))

	payload := make([]byte, 2)
	binary.BigEndian.PutUint16(payload, pkt.SubframeNum)

	for i, dataID := range pkt.DataIDArr {
		temp := make([]byte, 8)
		binary.BigEndian.PutUint16(temp[:2], dataID)
		binary.BigEndian.PutUint16(temp[2:4], uint16(pkt.TimeDiffArr[i]))
		temp[4] = byte(pkt.RowArr[i])
		temp[5] = byte(pkt.ColArr[i])
		binary.BigEndian.PutUint16(temp[6:8], uint16(pkt.LengthArr[i]))
		temp = append(temp, pkt.PayloadArr[i]...)
		payload = append(payload, temp...)
	}

	return append(bufExt, payload...)
}

func FromServiceBuf(buf []byte) ServicePacket {
	pkt := FromBuf(buf)
	servicePkt := ServicePacket{}
	servicePkt.Service = uint8(pkt.Payload[0])
	servicePkt.Flag = uint8(pkt.Payload[1])
	servicePkt.Option1 = uint8(pkt.Payload[2])
	servicePkt.Option2 = uint8(pkt.Payload[3])
	servicePkt.SubframeNum = binary.BigEndian.Uint16(pkt.Payload[4:6])

	pkt.Payload = pkt.Payload[6:]
	for i := 0; i != int(servicePkt.SubframeNum); i++ {
		servicePkt.DataIDArr = append(servicePkt.DataIDArr, binary.BigEndian.Uint16(pkt.Payload[:2]))
		servicePkt.TimeDiffArr = append(servicePkt.TimeDiffArr, binary.BigEndian.Uint16(pkt.Payload[2:4]))
		servicePkt.RowArr = append(servicePkt.RowArr, uint8(pkt.Payload[4]))
		servicePkt.ColArr = append(servicePkt.ColArr, uint8(pkt.Payload[5]))
		servicePkt.LengthArr = append(servicePkt.LengthArr, binary.BigEndian.Uint16(pkt.Payload[6:8]))
		servicePkt.PayloadArr = append(servicePkt.PayloadArr, pkt.Payload[8:8+8*binary.BigEndian.Uint16(pkt.Payload[6:8])])
		pkt.Payload = pkt.Payload[8+8*binary.BigEndian.Uint16(pkt.Payload[6:8]):]
	}
	servicePkt.Packet = pkt

	return servicePkt
}
