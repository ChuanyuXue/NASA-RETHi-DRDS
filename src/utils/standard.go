package utils
//---------- Constant ----------
const (
	BUFFLEN uint32 = 65536
	CHANELLEN uint32 = 128
	FRENQUENCE uint32 = 10000
	SUBSNUMS uint8 = 10
	TABLENUMS uint32 = 65536
)

type JsonStandard interface{

}

type PacketStandard interface{
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

type ClientStandard interface{
	Send() error
	Listen() (PacketStandard, error)
}