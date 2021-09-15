package communicator

type Client interface{
	BuildConnection()
	Send()
	CloseConnection()
}