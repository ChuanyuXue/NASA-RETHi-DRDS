package handler

import (
	"database/sql"
	"datarepo/src/utils"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

type Handler struct {
	utils.JsonStandard

	Local  string `json:"local"`
	Public string `json:"public"`
	Port   string `json:"port"`
	DBType string `json:"db_type"`
	DBName string `json:"db_name"`

	DBPointer    *sql.DB
	Tables       []string
	InteTable    uint8
	InfoTable    uint8
	RecordTables []uint8

	DataShapes    map[uint8]uint8
	LastWriteTime map[uint8]int

	UserName string `json:"user_name"`
	PassWord string `json:"password"`
}

func (handler *Handler) Init() error {
	var (
		err       error
		tableName string
	)

	// Connect database
	loginInfo := fmt.Sprintf(
		"%s:%s@tcp(%s:%s)/%s",
		handler.UserName,
		handler.PassWord,
		handler.Local,
		handler.Port,
		handler.DBName,
	)

	handler.DBPointer, err = sql.Open(handler.DBType, loginInfo)
	if err != nil {
		return err
	}

	//Record all tables
	query := fmt.Sprintf("SHOW TABLES from %s", handler.DBName)
	rows, err := handler.DBPointer.Query(query)
	if err != nil {
		return err
	}

	regInteraction := regexp.MustCompile(`inte\d+`)
	regInfo := regexp.MustCompile(`info\d+`)
	regRecord := regexp.MustCompile(`record\d+`)
	for rows.Next() {
		err := rows.Scan(&tableName)
		if err != nil {
			fmt.Println("Failed to load data:", err)
		} else {
			// Sniff Interaction Table
			matchInte := regInteraction.FindAllString(tableName, -1)
			if matchInte != nil {
				temp, err := utils.StringToInt(matchInte[0][4:])
				if err != nil {
					fmt.Println("Sniff Interation table error:", err)
					panic("sniff Interation table error")
				}
				if temp != 0 {
					fmt.Println("Table ID of interaction table not equal to zero!", err)
				}
				handler.InteTable = uint8(temp)
			}
			// Sniff DataInfo Table
			matchInfo := regInfo.FindAllString(tableName, -1)
			if matchInfo != nil {
				temp, err := utils.StringToInt(matchInfo[0][4:])
				if err != nil {
					fmt.Println("Sniff Data Information table error:", err)
					panic("sniff data information table error")
				}
				if temp != 1 {
					fmt.Println("Table ID of information table not equal to one!", err)
				}
				handler.InfoTable = uint8(temp)
			}
			// Sniff DataRecord Table
			matchRecord := regRecord.FindAllString(tableName, -1)
			if matchRecord != nil {
				temp, err := utils.StringToInt(matchRecord[0][6:])
				if err != nil {
					fmt.Println("Sniff Data Record table error:", err)
				}
				handler.RecordTables = append(handler.RecordTables, uint8(temp))
			}
			// Sniff all Table
			handler.Tables = append(handler.Tables, tableName)
		}
	}

	// Record the size of each Record tables
	query = fmt.Sprintf(
		"SELECT %s, %s FROM %s.%s;",
		"data_id",
		"data_size",
		handler.DBName,
		"info"+strconv.Itoa(int(handler.InfoTable)),
	)

	rows, err = handler.DBPointer.Query(query)
	if err != nil {
		panic("failed to query information table")
	}

	handler.DataShapes = make(map[uint8]uint8)
	for rows.Next() {
		var dataId uint8
		var dataSize uint8
		err := rows.Scan(&dataId, &dataSize)
		if err != nil {
			fmt.Println("failed to query information table")
		}
		handler.DataShapes[dataId] = dataSize
	}

	// fill the last insert time all 0
	handler.LastWriteTime = make(map[uint8]int)
	for i := range handler.Tables {
		handler.LastWriteTime[uint8(i)] = 0
	}

	// Security check
	// 1. .... Leave for future

	return nil
}

func (handler *Handler) WriteSynt(id uint8, synt uint32, value []float64) error {
	//Security Check:
	// // 1. ID == 0 is not allowed
	// if handler.InteTable == id {
	// 	return errors.New("attemping to change interaction table by atomic function, please try query function again.")
	// }
	// if handler.InfoTable == id {
	// 	return errors.New("attemping to change information table by atomic function, please try query function again.")
	// }
	// tableName = "record" + strconv.Itoa(int(id))
	// // 2. Length of value must equal to data_size in information table
	// if int(handler.DataShapes[id]) != len(value){
	// 	panic("insert data length not equal to data description table")
	// }
	// // 3. The new time stamp must bigger than the last one

	tableName := "record" + strconv.Itoa(int(id))

	// construct query sentence
	var columnList []string
	var columnFillin []string
	columnList = append(columnList, "synchronous_time")
	columnList = append(columnList, "time")

	for i := 0; i != int(handler.DataShapes[id]); i++ {
		columnList = append(columnList, "value"+strconv.Itoa(i))
	}
	columnPattern := strings.Join(columnList, ",")

	columnFillin = append(columnFillin, strconv.Itoa(int(synt)))
	// Need to fix int64 -> unsigned int32?
	columnFillin = append(columnFillin, strconv.Itoa(int(time.Now().Unix())))
	for i := 0; i != int(handler.DataShapes[id]); i++ {
		columnFillin = append(columnFillin, fmt.Sprintf("%f", value[i]))
	}
	columnValue := strings.Join(columnFillin, ",")

	query := fmt.Sprintf(
		"INSERT INTO %s.%s ("+columnPattern+") VALUES ("+columnValue+");",
		handler.DBName,
		tableName,
	)

	_, err := handler.DBPointer.Exec(query)
	if err != nil {
		return err
	}
	return nil
}

func (handler *Handler) ReadSynt(id uint8, synt uint32) ([]float64, error) {
	var tableName string
	var dataSize uint8
	var columnPattern string
	var rawData []float64

	tableName = "record" + strconv.Itoa(int(id))
	dataSize = handler.DataShapes[id]

	if dataSize == 1 {
		columnPattern = "value0"
	} else {
		var columnList []string
		for i := 0; i < int(dataSize); i++ {
			columnList = append(columnList, "value"+strconv.Itoa(i))
		}
		columnPattern = strings.Join(columnList, ",")
	}

	query := fmt.Sprintf(
		"SELECT %s FROM %s.%s WHERE synchronous_time = %s;",
		columnPattern,
		handler.DBName,
		tableName,
		strconv.Itoa(int(synt)),
	)
	scans := make([]interface{}, dataSize)
	values := make([][]byte, dataSize)
	for i := range values {
		scans[i] = &values[i]
	}

	row := handler.DBPointer.QueryRow(query)
	err := row.Scan(scans...)
	if err != nil {
		return rawData, err
	}

	for _, v := range values {
		data := string(v)
		s, err := strconv.ParseFloat(data, 64)
		if err != nil {
			fmt.Println("Failed to parse scan result from SQL query.")
		}
		rawData = append(rawData, s)
	}

	return rawData, nil
}

func (Handler *Handler) handle(id uint8, rawData []float64) []float64 {
	return rawData
}
