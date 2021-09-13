package main

type packet struct{
	Src		 uint8
	Dst      uint8
	Type     uint8
	Priority uint8
	Row      uint8
	Col      uint8
	Length   uint16
	
	Payload []float64
	Buf []byte
}

func (p *package) initFromBuf(buf []byte){

}