package statistic

type StatDB struct {
	BandWidth    float32
	UsageRAM     float32
	TotalRAM     float32
	UsageDisk    float32
	TotalDisk    float32
	AvgProcDelay uint32
}

type StatTime struct {
	Synt     uint64 `json:"synt"`
	PhytEMS  uint64 `json:"phyt_ems"`
	PhytC2   uint64 `json:"phyt_c2"`
	PhytDVI  uint64 `json:"phyt_dvi"`
	PhytDRDS uint64 `json:"phyt_drds"`
}

type StatTables struct {
	TableNum   uint16
	TableIndex map[uint16]int

	TableAlive     []bool
	TableIn        []bool
	TableOut       []bool
	TableLength    []int32
	TableWidth     []int32
	TableFirstSynt []int64
	TableLastSynt  []int64
	TableMaxValue  []float64
	TableMinValue  []float64

	TableReadRate  []float32
	TableWriteRate []float32
}

type StatSys struct {
	SysNum   uint16
	SysIndex map[uint16]int

	SysAlive     []bool
	SysIn        []bool
	SysOut       []bool
	SysReadRate  []float32
	SysWriteRate []float32
}

type Logs struct {
	LogRequest   string
	LogSend      string
	LogPublish   string
	LogSubscribe string

	LogWeb string
}

type Errors struct {
	ErrorRequest   string
	ErrorSend      string
	ErrorPublish   string
	ErrorSubscribe string

	ErrorWeb string
}

type Stat struct {
}
