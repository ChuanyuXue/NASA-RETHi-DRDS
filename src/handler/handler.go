package handler

import (
	"database/sql"
	"errors"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/ChuanyuXue/NASA-RETHi-DRDS/src/utils"
	_ "github.com/go-sql-driver/mysql"
)

type Data struct {
	Iter  uint32
	SendT uint32
	Value []float64
}

// Handler is the main struct for the handler
type Handler struct {
	utils.JsonStandard
	DBName string

	DBPointer    *sql.DB
	Tables       []string
	InteTable    uint8
	RelaTable    uint8
	InfoTable    uint8
	RecordTables []uint16

	DataShapes map[uint16]uint8
	DataBuffer map[uint16]chan *Data
}

// Init is the function to initialize the handler
// Args:
// 	src: 0 for ground, 1 for habitat
// Returns:
// 	error: nil if no error

func (handler *Handler) Init(id uint8) error {
	var (
		err       error
		tableName string
	)

	// Open database connection
	if id == 0 { // ground
		handler.DBPointer, err = sql.Open("mysql", fmt.Sprintf("%v:%v@(ground_db:3306)/%v", // "hms_db" is the database container's name in the docker-compose.yml
			os.Getenv("DB_USER_GROUND"),
			os.Getenv("DB_PASSWORD_GROUND"),
			os.Getenv("DB_NAME_GROUND")))
		handler.DBName = "ground"

	} else if id == 1 { // habitat
		handler.DBPointer, err = sql.Open("mysql", fmt.Sprintf("%v:%v@(habitat_db:3306)/%v", // "hms_db" is the database container's name in the docker-compose.yml
			os.Getenv("DB_USER_HABITAT"),
			os.Getenv("DB_PASSWORD_HABITAT"),
			os.Getenv("DB_NAME_HABITAT")))
		handler.DBName = "habitat"
	}
	if err != nil {
		fmt.Println(err)
		return err
	}

	// wait database container to start
	for {
		err := handler.DBPointer.Ping()
		if err == nil {
			break
		}
		fmt.Println(err)
		time.Sleep(2 * time.Second)
	}

	fmt.Println("Database " + handler.DBName + " has been connected!")

	// Get all tables
	query := fmt.Sprintf("SHOW TABLES from %s", handler.DBName)
	rows, err := handler.DBPointer.Query(query)
	if err != nil {
		return err
	}

	// Sniff all tables
	regInteraction := regexp.MustCompile(`link\d+`)
	regRelationship := regexp.MustCompile(`rela\d+`)
	regInfo := regexp.MustCompile(`info\d+`)
	regRecord := regexp.MustCompile(`record\d+`)
	for rows.Next() {
		err := rows.Scan(&tableName) // Scan the table name
		if err != nil {
			fmt.Println("Failed to load data:", err)
		} else {
			// Sniff Relationship Table
			matchInte := regRelationship.FindAllString(tableName, -1)
			if matchInte != nil {
				temp, err := utils.StringToInt(matchInte[0][4:]) // Get the table ID
				if err != nil {
					fmt.Println("Sniff relationship table error:", err)
					return err
				}
				if temp != 1 {
					fmt.Println("Table ID of relationship table not equal to one!", err)
				}
				handler.RelaTable = uint8(temp)
			}

			// Sniff Interaction Table
			matchLink := regInteraction.FindAllString(tableName, -1)
			if matchLink != nil {
				temp, err := utils.StringToInt(matchLink[0][4:]) // Get the table ID
				if err != nil {
					fmt.Println("Sniff Interaction table error:", err)
					return err
				}
				if temp != 2 {
					fmt.Println("Table ID of Interaction table not equal to two!", err)
				}
				handler.InteTable = uint8(temp)
			}
			// Sniff DataInfo Table
			matchInfo := regInfo.FindAllString(tableName, -1)
			if matchInfo != nil {
				temp, err := utils.StringToInt(matchInfo[0][4:]) // Get the table ID
				if err != nil {
					fmt.Println("Sniff Data Information table error:", err)
					return err
				}
				if temp != 0 {
					fmt.Println("Table ID of information table not equal to zero!", err)
				}
				handler.InfoTable = uint8(temp) // Get the info table ID
			}
			// Sniff DataRecord Table
			matchRecord := regRecord.FindAllString(tableName, -1)
			if matchRecord != nil {
				temp, err := utils.StringToInt(matchRecord[0][6:]) // Get the table ID
				if err != nil {
					fmt.Println("Sniff Data Record table error:", err)
				}
				handler.RecordTables = append(handler.RecordTables, uint16(temp))
			}
			// Record all tables including info, inte, rela, record
			handler.Tables = append(handler.Tables, tableName)
		}
	}
	// fmt.Println("[DEBUG]: Record ID:", handler.RecordTables)

	// Record the size of each Record tables
	query = fmt.Sprintf(
		"SELECT %s, %s FROM %s.%s;",
		"data_id",
		"data_size",
		handler.DBName,
		"info"+strconv.Itoa(int(handler.InfoTable)),
	)

	// Get the size of each data
	rows, err = handler.DBPointer.Query(query)
	if err != nil {
		fmt.Println("failed to query information table")
		return err

	}

	handler.DataShapes = make(map[uint16]uint8)
	for rows.Next() {
		var dataId uint16
		var dataSize uint8
		err := rows.Scan(&dataId, &dataSize)
		if err != nil {
			fmt.Println("failed to query information table")
		}
		handler.DataShapes[dataId] = dataSize // Record the size of each data
	}

	// Init data buffer
	handler.DataBuffer = make(map[uint16]chan *Data)
	for _, id := range handler.RecordTables {
		handler.DataBuffer[id] = make(chan *Data, utils.BUFFLEN)
	}

	for _, id := range handler.RecordTables {
		go handler.handleData(id)
		time.Sleep(time.Duration(int(1000/len(handler.RecordTables))) * time.Millisecond)
	}

	return nil
}

// WriteSynt write a new data into the database
// Args:
// 	id: the id of the data
// 	synt: the synt of the data
// 	phyt: the phyt of the data
// 	value: the value of the data
// Return:
// 	error: error message

func (handler *Handler) WriteSynt(id uint16, data *Data) error {
	// TODO: Security Check:
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
	if !utils.Uint16Contains(handler.RecordTables, id) {
		fmt.Println("[!] Data Error: Unknown data ", id, " is received")
		return nil
	}

	tableName := "record" + strconv.Itoa(int(id))

	// Construct the query
	var columnList []string
	var columnFillin []string
	columnList = append(columnList, "iter")
	columnList = append(columnList, "send_t")
	columnList = append(columnList, "recv_t")

	for i := 0; i != int(handler.DataShapes[id]); i++ {
		columnList = append(columnList, "v"+strconv.Itoa(i))
	}
	columnPattern := strings.Join(columnList, ",") // Join the column name by comma

	columnFillin = append(columnFillin, strconv.Itoa(int(data.Iter)))
	// Need to fix int64 -> unsigned int32?
	columnFillin = append(columnFillin, strconv.FormatUint(uint64(data.SendT), 10))
	columnFillin = append(columnFillin, strconv.FormatUint(uint64(time.Now().UnixMilli()), 10))

	if int(handler.DataShapes[id]) != len(data.Value) {
		return fmt.Errorf("[!] Data #%d has inconsistent data shape %d rather than %d", id, len(data.Value), int(handler.DataShapes[id]))
	}

	for i := 0; i != int(handler.DataShapes[id]); i++ {
		columnFillin = append(columnFillin, fmt.Sprintf("%f", data.Value[i]))
	}
	columnValue := strings.Join(columnFillin, ",")

	// Construct the query
	query := fmt.Sprintf(
		"INSERT INTO %s.%s ("+columnPattern+") VALUES ("+columnValue+");",
		handler.DBName,
		tableName,
	)

	// Write the data into the database
	_, err := handler.DBPointer.Exec(query)
	if err != nil {
		return err
	}
	return nil

}

func (handler *Handler) WriteRange(id uint16, dataVec []*Data) error {
	// fmt.Println("[DEBUG]: WriteRange", id, len(dataVec))
	if !utils.Uint16Contains(handler.RecordTables, id) {
		fmt.Println("[!] Data Error: Unknown data ", id, " is received")
		return nil
	}

	// It seems like there is no problem for WriteRange
	// iterVec := make([]int, len(dataVec))
	// for i, data := range dataVec {
	// 	iterVec[i] = int(data.Iter)
	// }
	// if id == 10001 {
	// 	fmt.Println("[DEBUG]:", id, " Iter: ", iterVec)
	// }

	tableName := "record" + strconv.Itoa(int(id))

	// Construct the query
	var columnList []string
	var columnFillinVec []string
	columnList = append(columnList, "iter")
	columnList = append(columnList, "send_t")
	columnList = append(columnList, "recv_t")

	for i := 0; i != int(handler.DataShapes[id]); i++ {
		columnList = append(columnList, "v"+strconv.Itoa(i))
	}
	columnPattern := strings.Join(columnList, ",") // Join the column name by comma

	recv_t := strconv.FormatUint(uint64(time.Now().UnixMilli()), 10)
	for _, data := range dataVec {
		columnFillin := []string{}
		columnFillin = append(columnFillin, strconv.Itoa(int(data.Iter)))
		// Need to fix int64 -> unsigned int32?
		columnFillin = append(columnFillin, strconv.FormatUint(uint64(data.SendT), 10))
		columnFillin = append(columnFillin, recv_t)

		if int(handler.DataShapes[id]) != len(data.Value) {
			return fmt.Errorf("[!] Data #%d has inconsistent data shape %d rather than %d", id, len(data.Value), int(handler.DataShapes[id]))
		}

		for k := 0; k != int(handler.DataShapes[id]); k++ {
			columnFillin = append(columnFillin, fmt.Sprintf("%f", data.Value[k]))
		}
		columnValue := "(" + strings.Join(columnFillin, ",") + ")"
		columnFillinVec = append(columnFillinVec, columnValue)
	}
	columnFillinStr := strings.Join(columnFillinVec, ",")

	// Construct the query
	query := fmt.Sprintf(
		"INSERT INTO %s.%s ("+columnPattern+") VALUES "+columnFillinStr+";",
		handler.DBName,
		tableName,
	)

	// Write the data into the database
	_, err := handler.DBPointer.Exec(query)
	if err != nil {
		return err
	}
	return nil
}

func (handler *Handler) ReadSynt(id uint16, synt uint32) (uint64, []float64, error) {
	var tableName string
	var columnSize uint8
	var columnPattern string
	var rawData []float64

	tableName = "record" + strconv.Itoa(int(id)) // Get the table name
	columnSize = handler.DataShapes[id]          // Get the size of the data

	if columnSize == 1 {
		columnPattern = "v0" // If the data size is 1, then only one column is needed
	} else {
		var columnList []string
		for i := 0; i < int(columnSize); i++ {
			columnList = append(columnList, "v"+strconv.Itoa(i)) // Get the column name
		}
		columnPattern = strings.Join(columnList, ",") // Join the column name by comma
	}

	// Construct the query
	query := fmt.Sprintf(
		"SELECT recv_t, %s FROM %s.%s WHERE iter = %s;",
		columnPattern,
		handler.DBName,
		tableName,
		strconv.Itoa(int(synt)),
	)

	scans := make([]interface{}, columnSize+1)
	values := make([][]byte, columnSize+1)
	for i := range values {
		scans[i] = &values[i]
	}

	row := handler.DBPointer.QueryRow(query)
	err := row.Scan(scans...) // Scan the data
	if err != nil {
		// fmt.Println("No data found!")
		return 0, rawData, nil
	} else {
		var timePhy uint64
		for i, v := range values {
			data := string(v)
			switch i {
			case 0:
				s, err := strconv.ParseInt(data, 10, 64)
				timePhy = uint64(s)
				if err != nil {
					fmt.Println("[!]Element0: Failed to parse scan result from SQL query.")
				}
			default:
				s, err := strconv.ParseFloat(data, 64)
				if err != nil {
					fmt.Println("[!]Element1: Failed to parse scan result from SQL query.")
				}
				rawData = append(rawData, s)
			}

		}
		return timePhy, rawData, nil
	}

}

// Read multiple rows of data from database
//
// Args:
//   - id: data id
//   - start: start simulation timestamp
//   - end: end simulation timestamp
//
// Return:
//   - simulation time 1D vector
//   - physical time 1D vector
//   - data matrix (2D)
//   - err: error
func (handler *Handler) ReadRange(id uint16, start uint32, end uint32) ([]uint32, []uint64, [][]float64, error) {
	var tableName string
	var dataSize uint8
	var columnPattern string
	var timePhyVec []uint64
	var timeSimuVec []uint32
	var dataMat [][]float64

	tableName = "record" + strconv.Itoa(int(id))
	dataSize = handler.DataShapes[id]

	if dataSize == 1 {
		columnPattern = "v0"
	} else {
		var columnList []string
		for i := 0; i < int(dataSize); i++ {
			columnList = append(columnList, "v"+strconv.Itoa(i))
		}
		columnPattern = strings.Join(columnList, ",")
	}

	// Construct the query with condition of time range
	query := fmt.Sprintf(
		"SELECT recv_t, iter, %s FROM %s.%s WHERE (iter >= %s) AND (iter < %s);",
		columnPattern,
		handler.DBName,
		tableName,
		strconv.Itoa(int(start)),
		strconv.Itoa(int(end)),
	)

	scans := make([]interface{}, dataSize+2)
	values := make([][]byte, dataSize+2)
	for i := range values {
		scans[i] = &values[i]
	}

	rows, err := handler.DBPointer.Query(query)
	if err != nil {
		fmt.Println(err)
		return nil, nil, nil, err
	}

	for rows.Next() {
		rows.Scan(scans...)
		var rawData []float64
		for i, v := range values {
			data := string(v)
			switch i {
			case 0:
				s, err := strconv.ParseUint(data, 10, 64)
				timePhyVec = append(timePhyVec, s)
				if err != nil {
					fmt.Println("[!]Element0 Range:  Failed to parse scan result from SQL query.")
				}

			case 1:
				s, err := strconv.ParseUint(data, 10, 32)
				timeSimuVec = append(timeSimuVec, uint32(s))
				if err != nil {
					fmt.Println("[!]Element1 Range: Failed to parse scan result from SQL query.")
				}
			default:
				s, err := strconv.ParseFloat(data, 64)
				rawData = append(rawData, s)
				if err != nil {
					fmt.Println("[!]Element2 Range: Failed to parse scan result from SQL query.")
				}
			}
		}
		dataMat = append(dataMat, rawData) // Append the data to the data matrix
	}
	return timeSimuVec, timePhyVec, dataMat, nil
}

// QueryInfo query the information of the data
// Args:
//
//	id: the id of the data
//	column: the column name of the data
//
// Return:
//
//	para: the value of the column
//	err: the error of the query
func (handler *Handler) QueryInfo(id uint16, column string) (int, error) {

	// Construct the query with condition of table name and data id
	tableName := "info" + strconv.Itoa(int(handler.InfoTable))
	query := fmt.Sprintf(
		"SELECT %s FROM "+
			handler.DBName+"."+tableName+
			" WHERE DATA_ID = %d", column, int(id),
	)

	row := handler.DBPointer.QueryRow(query)
	var result string
	err := row.Scan(&result) // Scan the data
	if err != nil {
		return 0, err
	}
	para, err := utils.StringToInt(result)
	if err != nil {
		return 0, err
	}
	return int(para), nil
}

// QueryLastSynt query the last time of the data
// Args:
//
//	id: the id of the data
//
// Return:
//
//	time: the last time of the data
func (handler *Handler) QueryLastSynt(id uint16) uint32 {
	var time string
	tableName := "record" + strconv.Itoa(int(id))
	query := fmt.Sprintf(
		"SELECT iter FROM %s.%s ORDER BY iter DESC LIMIT 1;",
		handler.DBName,
		tableName,
	) // Sort the data by simulink time and get the last one
	row := handler.DBPointer.QueryRow(query)
	err := row.Scan(&time)
	if err != nil {
		// fmt.Println("No data found!")
		return 0
	}
	result, _ := utils.StringToInt(time)
	return uint32(result)
}

// QueryFirstSynt query the first time of the data
// Args:
//
//	id: the id of the data
//
// Return:
//
//	time: the first time of the data
func (handler *Handler) QueryFirstSynt(id uint16) uint32 {
	var time string
	tableName := "record" + strconv.Itoa(int(id))
	query := fmt.Sprintf(
		"SELECT iter FROM %s.%s ORDER BY iter LIMIT 1;",
		handler.DBName,
		tableName,
	) // Sort the data by simulink time and get the first one
	row := handler.DBPointer.QueryRow(query)
	err := row.Scan(&time)
	if err != nil {
		fmt.Println("Failed to retrieve last time stamp")
	}
	result, _ := utils.StringToInt(time)
	return uint32(result)
}

func (handler *Handler) WriteToBuffer(id uint16, data *Data) error {
	// Check if the buffer is full
	if len(handler.DataBuffer[id]) >= int(utils.BUFFLEN) {
		return errors.New("buffer is full")
	}
	handler.DataBuffer[id] <- data // Push the new data
	return nil
}

func (handler *Handler) handleData(id uint16) {
	buffer := []*Data{}
	lastWriteTime := time.Now()
	for {
		select {
		case data := <-handler.DataBuffer[id]:
			buffer = append(buffer, data)
			if len(buffer) > 0 {
				now := time.Now()
				if now.Sub(lastWriteTime) >= time.Second || len(buffer) >= 100 {
					handler.WriteRange(id, buffer)
					buffer = []*Data{}
					lastWriteTime = now
				}
			}
		default:
			if len(buffer) > 0 {
				now := time.Now()
				if now.Sub(lastWriteTime) >= time.Second || len(buffer) >= 100 {
					handler.WriteRange(id, buffer)
					buffer = []*Data{}
					lastWriteTime = now
				}
			}
		}
	}

}

// func (handler *Handler) handleData() {

// 	buffer := map[uint16][]*Data{}
// 	lastWriteTime := map[uint16]time.Time{}

// 	for id, dataChan := range handler.DataBuffer {
// 		go func(id uint16, dataChan <-chan *Data) {
// 			for data := range dataChan {
// 				buffer[id] = append(buffer[id], data)
// 			}
// 		}(id, dataChan)
// 	}

// 	for {
// 		for id, data := range buffer {
// 			if len(data) > 0 {
// 				now := time.Now()
// 				lastTime, ok := lastWriteTime[id]
// 				if !ok || now.Sub(lastTime) >= 1*time.Second {
// 					go handler.WriteRange(id, data)
// 					buffer[id] = []*Data{}
// 					lastWriteTime[id] = now
// 				}
// 			}
// 		}
// 	}
// }
