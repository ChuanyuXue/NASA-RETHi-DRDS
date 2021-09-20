package communicator

import (
	"datarepo/src/databasemanager"
	"datarepo/src/units"
	// "net"
)

type Server interface {
	Build()
	Listen()
	Send()
	Handle()
	Close()
}

type UDPServer struct {
	HostLocal  string
	HostPublic string
	Port       string
	Client     *Client
	Manager    *databasemanager.Manager
}

func DefaultServer(config *units.Config) *UDPServer {
	this := &UDPServer{HostLocal: config.}
	return this
}

type TSNServer struct {
}
