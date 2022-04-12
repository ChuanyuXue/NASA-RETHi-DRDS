package utils

//---------- Basic configuraitons ---------- SEQ
const (
	BUFFLEN            uint32 = 65536
	QUEUELELN          uint32 = 65536
	PROCNUMS           uint8  = 64
	FRENQUENCE         uint32 = 10000
	SUBSNUMS           uint8  = 10
	TABLENUMS          uint32 = 65536
	HEADER_LEN         uint8  = 24
	SERVICE_HEADER_LEN uint8  = 6
	SUB_HEADER_LEN     uint8  = 8
	MTU                uint16 = 1500
)

//---------- Source_address
const (
	SRC_GCC   uint8 = 0
	SRC_HMS   uint8 = 1
	SRC_STR   uint8 = 2
	SRC_PWR   uint8 = 3
	SRC_ECLSS uint8 = 4
	SRC_AGT   uint8 = 5
	SRC_ING   uint8 = 6
	SRC_EXT   uint8 = 7
	SRC_SPL   uint8 = 8
	SRC_DTB   uint8 = 9
)

//----------- Message Type
const (
	MSG_INNER uint8 = 0
	MSG_OUTER uint8 = 1
)

//----------- Data Type
const (
	TYPE_NODATA uint8 = 0
	TYPE_FDD    uint8 = 1
	TYPE_SENSOR uint8 = 2
	TYPE_AGENT  uint8 = 3
	TYPE_TEST   uint8 = 4
	TYPE_OTHER  uint8 = 255
)

//------------ Priority
const (
	PRIORITY_LOW    uint8 = 1
	PRIORITY_NORMAL uint8 = 3
	PRIORITY_MEDIUM uint8 = 5
	PRIORITY_HIGHT  uint8 = 7
)

//------------ Version
const (
	VERSION_V0 uint8 = 0
)

//------------ Reserved
const (
	RESERVED uint8 = 0
)

//------------ OPTION
const (
	SER_SEND      uint8 = 0
	SER_REQUEST   uint8 = 1
	SER_PUBLISH   uint8 = 2
	SER_SUBSCRIBE uint8 = 3
	SER_RESPONSE  uint8 = 0x0A
)

//------------ FLAG
const (
	FLAG_SINGLE  uint8 = 0
	FLAG_STREAM  uint8 = 1
	FLAG_WARNING uint8 = 0xFE
	FLAG_ERROR   uint8 = 0xFF
)

//------------ SIMU TIME
const (
	TIME_SIMU_LAST uint32 = 0xFFFFFFFF
)

//----------- PARAMTER
const (
	PARAMTER_REQUEST_LAST  uint16 = 0xFFFF
	PARAMTER_EMPTY         uint16 = 0
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
