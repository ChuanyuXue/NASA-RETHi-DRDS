package utils
//---------- Constant ----------
const (
	BUFFLEN uint = 65536
	CHANELLEN uint = 128
	FRENQUENCE uint = 10000
	SUBSNUMS uint = 10
	TABLENUMS uint = 65536
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