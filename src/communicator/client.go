package communicator

type Client struct{
	Local  string `json:"local"`
	Public string `json:"public"`
	Port   string `json:"port"`
	BuffLen   int    `json:"buff_len"`
	Frequence int    `json:"frequence"`
	Headers   struct {
		Src      string `json:"src"`
		Dst      string `json:"dst"`
		Type     string `json:"type"`
		Priority string `json:"priority"`
		Row      string `json:"row"`
		Col      string `json:"col"`
		Length   string `json:"length"`
	} `json:"headers"`
	Payload string `json:"payload"`
	Trailer string `json:"trailer"`
}