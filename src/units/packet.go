package units

import (
	"encoding/binary"
	"fmt"
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
	Payload []byte
}

func (pkt *Packet) FromBuf(buf []byte) error {
	pkt.Src = uint8(buf[0])
	pkt.Dst = uint8(buf[1])
	pkt.Type = uint8(buf[2])
	pkt.Priority = uint8(buf[3])
	pkt.Row = uint8(buf[4])
	pkt.Col = uint8(buf[5])
	pkt.Length = binary.LittleEndian.Uint16(buf[6:8])
	// pkt.Payload = buf[8:]
	pkt.Payload = buf[8:]

	// check
	if int(pkt.Src) >= len(SUBSYS_LIST) ||
		int(pkt.Dst) >= len(SUBSYS_LIST) ||
		int(pkt.Type) >= 8 ||
		int(pkt.Priority) >= 8 ||
		int(pkt.Length) != (int(pkt.Row)*int(pkt.Col)) {
		return fmt.Errorf("[!] invalid header format: [%d, %d, %d, %d, %d, %d, %d]",
			pkt.Src, pkt.Dst, pkt.Type, pkt.Priority, pkt.Row, pkt.Col, pkt.Length)
	}
	return nil
}
