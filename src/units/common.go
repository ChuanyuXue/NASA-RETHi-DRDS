package units

type Subsys struct {
	ID         int    `json:"id"`
	Name       string `json:"name"`
	LocalAddr  string `json:"local_addr"`
	RemoteAddr string `json:"remote_addr"`
}

var (
	SUBSYS_LIST   []Subsys
	SUBSYS_TABLE  = map[string]Subsys{}
	ROUTING_TABLE = map[int]string{
		0: "SW1",
		1: "SW2",
		2: "SW3",
		3: "SW4",
		4: "SW5",
		5: "SW6",
		6: "SW7",
	}
	fwdCntTotal = 0
)

type MetaData struct {
	Index uint8
	Data  []float64
}
