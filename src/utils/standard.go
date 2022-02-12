package utils

//---------- Basic configuraitons ----------
const (
	BUFFLEN    uint32 = 65536
	QUEUELELN  uint32 = 65536
	PROCNUMS   uint8  = 64
	FRENQUENCE uint32 = 10000
	SUBSNUMS   uint8  = 10
	TABLENUMS  uint32 = 65536
	MTU        uint16 = 1500
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
	TYPE_OTHER  uint8 = 4
)

//------------ Priority
const (
	PRIORITY_LOW    uint8 = 1
	PRIORITY_NORMAL uint8 = 3
	PRIORITY_MEDIUM uint8 = 5
	PRIORITY_HIGHT  uint8 = 7
)

//------------ OPTION
const (
	OPT_SEND      uint16 = 0
	OPT_REQUEST   uint16 = 1
	OPT_PUBLISH   uint16 = 2
	OPT_SUBSCRIBE uint16 = 3
	OPT_RESPONSE  uint16 = 0x000A
)

//------------ FLAG
const (
	FLAG_SINGLE  uint16 = 0
	FLAG_STREAM  uint16 = 1
	FLAG_WARNING uint16 = 0xFFFE
	FLAG_ERROR   uint16 = 0xFFFF
)

//------------ SIMU TIME
const (
	TIME_SIMU_LAST uint32 = 0xFFFFFFFF
)

//----------- PARAMTER
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
