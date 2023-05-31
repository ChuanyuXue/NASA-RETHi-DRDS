package utils

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"strconv"
)

// UDP server configuration
const (
	BUFFLEN            uint32 = 65536
	QUEUELELN          uint32 = 65536
	PKTLEN             uint32 = 4500
	CONSUMER_NUMS      uint16 = 2000
	PROCUDER_NUMS      uint16 = 2000
	FRENQUENCE         uint32 = 10000
	SUBSNUMS           uint8  = 10
	TABLENUMS          uint32 = 65536
	HEADER_LEN         uint8  = 24
	SERVICE_HEADER_LEN uint8  = 6
	SUB_HEADER_LEN     uint8  = 8
	MTU                uint16 = 1500
)

// WebServer configuration
const (
	OUTPUT_BUFFER_LEN uint32 = 65536
	RT_STREAM_FREQ    uint32 = 1
)

//---------- Source_address

var SYSTEM_ID = map[string]uint8{
	"GCC":   0,
	"HMS":   1,
	"STR":   2,
	"SPL":   11,
	"CORR":  10,
	"ECLSS": 5,
	"PWR":   3,
	"AGT":   6,
	"IE":    8,
	"DTB":   9,
	"EXT":   7,
}

var TIME_OFFSET = map[string]uint64{
	"0":   1672574400000,
	"45":  1672941600000,
	"90":  1673222400000,
	"135": 1673589600000,
	"180": 1673870400000,
}

// ----------- Message Type
const (
	MSG_INNER uint8 = 0
	MSG_OUTER uint8 = 1
)

// ----------- Data Type
const (
	TYPE_NODATA        uint8 = 0
	TYPE_SENSOR        uint8 = 1
	TYPE_FDD           uint8 = 2
	TYPE_FDD_COMPONENT uint8 = 3
	TYPE_FDD_MEASURE   uint8 = 4
	TYPE_AGENT         uint8 = 5
	TYPE_OTHER         uint8 = 255
)

// ------------ Priority
const (
	PRIORITY_LOW    uint8 = 1
	PRIORITY_NORMAL uint8 = 3
	PRIORITY_MEDIUM uint8 = 5
	PRIORITY_HIGHT  uint8 = 7
)

// ------------ Version
const (
	VERSION_V0 uint8 = 0
)

// ------------ Reserved
const (
	RESERVED uint8 = 0
)

// ------------ OPTION
const (
	SER_SEND      uint8 = 0
	SER_REQUEST   uint8 = 1
	SER_PUBLISH   uint8 = 2
	SER_SUBSCRIBE uint8 = 3
	SER_RESPONSE  uint8 = 0x0A
)

// ------------ FLAG
const (
	FLAG_SINGLE  uint8 = 0
	FLAG_STREAM  uint8 = 1
	FLAG_WARNING uint8 = 0xFE
	FLAG_ERROR   uint8 = 0xFF
)

// ------------ SIMU TIME
const (
	TIME_SIMU_START uint32 = 0
	TIME_SIMU_LAST  uint32 = 0xFFFFFFFF
)

// ----------- PARAMTER
const (
	PARAMTER_REQUEST_LAST uint16 = 0xFFFF
	PARAMTER_EMPTY        uint16 = 0
)

type JsonStandard interface {
}

type PacketStandard interface {
	FromBuff() (PacketStandard, error)
	ToBuff() ([]byte, error)
}

type ServiceStandard interface {
	Init() error
	Send() error
	Publish() error
	Request() ([]float64, error)
	Subscribe() (chan float64, error)
	Close() error
}

type HandlerStandard interface {
	Init() error
	Write() error
	Read() ([]float64, error)
}

type ClientStandard interface {
	Send() error
	Listen() (PacketStandard, error)
}

// ----------- Common static functions ----------
func LoadFromJson(path string, server JsonStandard) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()

	byteValue, err := ioutil.ReadAll(file)
	if err != nil {
		return err
	}

	err = json.Unmarshal([]byte(byteValue), &server)
	if err != nil {
		return err
	}
	return nil
}

func StringToInt(s string) (int, error) {
	i, err := strconv.Atoi(s)
	if err != nil {
		return -1, err
	}
	return i, nil
}

func Uint8Contains(s []uint8, i uint8) bool {
	for _, v := range s {
		if v == i {
			return true
		}
	}
	return false
}

func Uint16Contains(s []uint16, i uint16) bool {
	for _, v := range s {
		if v == i {
			return true
		}
	}
	return false
}

func Uint32Contains(s []uint32, i uint32) bool {
	for _, v := range s {
		if v == i {
			return true
		}
	}
	return false
}

func DoubleContains(s []float64, i float64) bool {
	for _, v := range s {
		if v == i {
			return true
		}
	}
	return false
}
