package utils
//---------- Constant ----------
const (
	BUFFLEN int = 65536
	CHANELLEN int = 128
	FRENQUENCE int = 10000
	SUBSNUMS int = 8
)

//---------- Interface Standard ---------
type JsonStandard interface{

}

type ComponentStandard interface{
	Init()
	Run()
	Terminate()
}

type CtrlSig int
const (
	START CtrlSig = iota
	CLOSE
)

//---------- Communicator Standard ----------
type ServerStandard interface {

	Build()
	Listen()
	Send()
	Close()
}

type ClientStandard interface {

	Build()
	Listen()
	Send()
	Close()
}

//---------- Database Standard ----------
type ManagerStandard interface {

	AccessDatabase()
	CreateTable()
	InsertData()
	DeleteTable()
}

type HandlerStandard interface {
	Handle()

}

