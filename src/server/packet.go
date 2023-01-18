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

// FromBuf function converts a byte slice to a Packet struct
// Args:
// 	buf: the byte slice to be converted
// Returns:
// 	pkt: the converted Packet struct
func FromBuf(buf []byte) Packet {
	var pkt Packet
	pkt.Src = uint8(buf[0])
	pkt.Dst = uint8(buf[1])
	temp := binary.LittleEndian.Uint16(buf[2:4])
	pkt.MessageType = uint8(temp >> 12)
	pkt.Priority = uint8(temp >> 8 & 0x0f)
	pkt.Version = uint8(temp >> 4 & 0x0f)
	pkt.Reserved = uint8(temp & 0x0f)
	pkt.PhysicalTime = uint32(binary.LittleEndian.Uint32(buf[4:8]))
	pkt.SimulinkTime = uint32(binary.LittleEndian.Uint32(buf[8:12]))
	pkt.Sequence = binary.LittleEndian.Uint16(buf[12:14])
	pkt.Length = binary.LittleEndian.Uint16(buf[14:16])
	pkt.Payload = buf[16:]
	return pkt
}

// ToBuf function converts a Packet struct to a byte slice
// Args:
// 	pkt: the Packet struct to be converted
// Returns:
// 	buf: the converted byte slice
func (pkt Packet) ToBuf() []byte {
	var buf [16]byte
	buf[0] = byte(pkt.Src)
	buf[1] = byte(pkt.Dst)
	temp := uint16(pkt.MessageType)<<12 + uint16(pkt.Priority)<<8 + uint16(pkt.Version)<<4 + uint16(pkt.Reserved)
	binary.LittleEndian.PutUint16(buf[2:4], uint16(temp))
	binary.LittleEndian.PutUint32(buf[4:8], uint32(pkt.PhysicalTime))
	binary.LittleEndian.PutUint32(buf[8:12], uint32(pkt.SimulinkTime))
	binary.LittleEndian.PutUint16(buf[12:14], uint16(pkt.Sequence))
	binary.LittleEndian.PutUint16(buf[14:16], uint16(pkt.Length))
	return append(buf[:], pkt.Payload...)
}

// PayloadFloat2Buf function converts a float64 slice to a byte slice
// Args:
// 	payload: the float64 slice to be converted
// Returns:
// 	buft: the converted byte slice
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

// PayloadBuf2Float function converts a byte slice to a float64 slice
// Args:
// 	buf: the byte slice to be converted
// Returns:
// 	data64: the converted float64 slice
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

// Float64frombytes function converts a byte slice to a float64
// Args:
// 	bytes: the byte slice to be converted
// Returns:
// 	float: the converted float64
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

// SubPacket struct
// Note subpacket is the smallest unit of data in the service packet
type SubPacket struct {
	DataID   uint16
	TimeDiff uint16
	Row      uint8
	Col      uint8
	Length   uint16
	Payload  []byte
}

// ServicePacket struct
// Defined on top of the TSN Emulation Protocol by adding service, flag, option1, option2, subframe_num fields
type ServicePacket struct {
	Packet
	Service     uint8  `json:"service"`
	Flag        uint8  `json:"flag"`
	Option1     uint8  `json:"option_1"`
	Option2     uint8  `json:"option_2"`
	SubframeNum uint16 `json:"subframe_num"`

	Subpackets []*SubPacket
}

// ToServiceBuf function converts a ServicePacket struct to a byte slice
// Args:
// 	pkt: the ServicePacket struct to be converted
// Returns:
// 	buf: the converted byte slice
func (pkt *ServicePacket) ToServiceBuf() []byte {
	var buf [16]byte
	var bufExt []byte

	buf[0] = byte(pkt.Src)
	buf[1] = byte(pkt.Dst)
	temp := uint16(pkt.MessageType)<<12 + uint16(pkt.Priority)<<8 + uint16(pkt.Version)<<4 + uint16(pkt.Reserved)
	binary.LittleEndian.PutUint16(buf[2:4], uint16(temp))
	binary.LittleEndian.PutUint32(buf[4:8], uint32(pkt.PhysicalTime))
	binary.LittleEndian.PutUint32(buf[8:12], uint32(pkt.SimulinkTime))
	binary.LittleEndian.PutUint16(buf[12:14], uint16(pkt.Sequence))
	binary.LittleEndian.PutUint16(buf[14:16], uint16(pkt.Length))

	bufExt = append(bufExt, buf[:]...)
	bufExt = append(bufExt, byte(pkt.Service))
	bufExt = append(bufExt, byte(pkt.Flag))
	bufExt = append(bufExt, byte(pkt.Option1))
	bufExt = append(bufExt, byte(pkt.Option2))

	payload := make([]byte, 2)
	binary.LittleEndian.PutUint16(payload, pkt.SubframeNum)

	for _, subpacket := range pkt.Subpackets {
		temp := make([]byte, 8)
		binary.LittleEndian.PutUint16(temp[:2], subpacket.DataID)
		binary.LittleEndian.PutUint16(temp[2:4], subpacket.TimeDiff)
		temp[4] = byte(subpacket.Row)
		temp[5] = byte(subpacket.Col)
		binary.LittleEndian.PutUint16(temp[6:8], uint16(subpacket.Length))
		temp = append(temp, subpacket.Payload...)
		payload = append(payload, temp...)
	}

	return append(bufExt, payload...)
}

// FromServiceBuf function converts a byte slice to a ServicePacket struct
// Args:
// 	buf: the byte slice to be converted
// Returns:
// 	pkt: the converted ServicePacket struct
func FromServiceBuf(buf []byte) ServicePacket {
	pkt := FromBuf(buf)
	servicePkt := ServicePacket{}
	servicePkt.Service = uint8(pkt.Payload[0])
	servicePkt.Flag = uint8(pkt.Payload[1])
	servicePkt.Option1 = uint8(pkt.Payload[2])
	servicePkt.Option2 = uint8(pkt.Payload[3])
	servicePkt.SubframeNum = binary.LittleEndian.Uint16(pkt.Payload[4:6])

	pkt.Payload = pkt.Payload[6:]
	for i := 0; i != int(servicePkt.SubframeNum); i++ {
		var subpacket SubPacket

		subpacket.DataID = binary.LittleEndian.Uint16(pkt.Payload[:2])
		subpacket.TimeDiff = binary.LittleEndian.Uint16(pkt.Payload[2:4])
		subpacket.Row = uint8(pkt.Payload[4])
		subpacket.Col = uint8(pkt.Payload[5])
		subpacket.Length = binary.LittleEndian.Uint16(pkt.Payload[6:8])
		subpacket.Payload = pkt.Payload[8 : 8+8*subpacket.Length]
		servicePkt.Subpackets = append(servicePkt.Subpackets, &subpacket)

		pkt.Payload = pkt.Payload[8+8*subpacket.Length:]
	}
	servicePkt.Packet = pkt

	return servicePkt
}
