package databasemanager

import (
	"datarepo/src/units"
	"encoding/binary"
	"math"
)

type DemoHandler struct {
	packet units.Packet
	data   units.MetaData
}

func PacHandler(packet units.Packet) *DemoHandler {
	this := DemoHandler{packet: packet}
	return &this
}

func (this *DemoHandler) Handle() units.MetaData {
	this.data = units.MetaData{}
	this.data.Index = this.packet.Src

	// Decode the data stream
	var data64 []float64

	for i, _ := range this.packet.Payload {
		if i%8 == 0 {
			targetBuf := this.packet.Payload[i : i+8]
			// base64EncodedStr := base64.StdEncoding.EncodeToString(targetBuf)
			// floatData, _ := base64.StdEncoding.DecodeString(base64EncodedStr)
			data64 = append(data64, Float64frombytes(targetBuf))

		}
	}

	this.data.Data = data64
	return this.data
}

func Float64frombytes(bytes []byte) float64 {
	bits := binary.LittleEndian.Uint64(bytes)
	float := math.Float64frombits(bits)
	return float
}
