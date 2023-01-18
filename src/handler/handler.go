package handler

import (
	"data-service/src/utils"
	"database/sql"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

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
}

// Init is the function to initialize the handler
// Args:
// 	src: 0 for ground, 1 for habitat
// Returns:
// 	error: nil if no error

func (handler *Handler) Init(src uint8) error {
	var (
		err       error
		tableName string
	)

	// Open database connection
	if src == 0 { // ground
		handler.DBPointer, err = sql.Open("mysql", fmt.Sprintf("%v:%v@(ground_db:3306)/%v", // "hms_db" is the database container's name in the docker-compose.yml
			os.Getenv("DB_USER_GROUND"),
			os.Getenv("DB_PASSWORD_GROUND"),
			os.Getenv("DB_NAME_GROUND")))
		handler.DBName = "ground"

	} else if src == 1 { // habitat
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

func (handler *Handler) WriteSynt(id uint16, synt uint32, phyt uint32, value []float64) error {
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

	tableName := "record" + strconv.Itoa(int(id))

	// Construct the query
	var columnList []string
	var columnFillin []string
	columnList = append(columnList, "simulink_time")
	columnList = append(columnList, "physical_time")
	columnList = append(columnList, "physical_time_2")

	for i := 0; i != int(handler.DataShapes[id]); i++ {
		columnList = append(columnList, "value"+strconv.Itoa(i))
	}
	columnPattern := strings.Join(columnList, ",") // Join the column name by comma

	columnFillin = append(columnFillin, strconv.Itoa(int(synt)))              // Convert the simulink timestamp to string
	columnFillin = append(columnFillin, strconv.Itoa(int(phyt)))              // Convert the physical sending timestamp to string
	columnFillin = append(columnFillin, strconv.Itoa(int(time.Now().Unix()))) // Convert the physical receiving timestamp to string
	for i := 0; i != int(handler.DataShapes[id]); i++ {
		columnFillin = append(columnFillin, fmt.Sprintf("%f", value[i]))
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

// ReadSynt read the single data from the database
// Args:
// 	id: the id of the data
// 	synt: the simulink timestamp
// Return:
// 	value: the value of the data
// 	err: error

func (handler *Handler) ReadSynt(id uint16, synt uint32) ([]float64, error) {
	var tableName string
	var columnSize uint8
	var columnPattern string
	var rawData []float64

	tableName = "record" + strconv.Itoa(int(id)) // Get the table name
	columnSize = handler.DataShapes[id]          // Get the size of the data

	if columnSize == 1 {
		columnPattern = "value0" // If the data size is 1, then only one column is needed
	} else {
		var columnList []string
		for i := 0; i < int(columnSize); i++ {
			columnList = append(columnList, "value"+strconv.Itoa(i)) // Get the column name
		}
		columnPattern = strings.Join(columnList, ",") // Join the column name by comma
	}

	// Construct the query
	query := fmt.Sprintf(
		"SELECT %s FROM %s.%s WHERE simulink_time = %s;",
		columnPattern,
		handler.DBName,
		tableName,
		strconv.Itoa(int(synt)),
	)

	// The []interface{} is a magic trick to scan the data to bypass type check
	scans := make([]interface{}, columnSize) 
	values := make([][]byte, columnSize)
	for i := range values {
		scans[i] = &values[i]
	}

	row := handler.DBPointer.QueryRow(query) 
	err := row.Scan(scans...) // Scan the data
	if err != nil {
		// fmt.Println("No data found!")
		return rawData, nil
	} else {
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

}


// ReadRange read multi data from the database
// Args:
// 	id: the id of the data
// 	start: the start time of the data
// 	end: the end time of the data
// Return:
// 	timeVec: the time vector of the data
// 	dataMat: the data matrix of the data

func (handler *Handler) ReadRange(id uint16, start uint32, end uint32) ([]uint32, [][]float64, error) {
	var tableName string
	var dataSize uint8
	var columnPattern string
	var timeVec []uint32
	var dataMat [][]float64

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

	// Construct the query with condition of time range
	query := fmt.Sprintf(
		"SELECT simulink_time,%s FROM %s.%s WHERE (simulink_time >= %s) AND (simulink_time < %s);",
		columnPattern,
		handler.DBName,
		tableName,
		strconv.Itoa(int(start)),
		strconv.Itoa(int(end)),
	)

	// The []interface{} is a magic trick to scan the data to bypass type check
	scans := make([]interface{}, dataSize+1)
	values := make([][]byte, dataSize+1)
	for i := range values {
		scans[i] = &values[i]
	}

	rows, err := handler.DBPointer.Query(query)
	if err != nil {
		fmt.Println(err)
		return nil, nil, err
	}

	for rows.Next() {
		rows.Scan(scans...)
		var rawData []float64
		for i, v := range values {
			data := string(v)

			if i == 0 { // The first column is the time vector
				s, err := strconv.ParseInt(data, 10, 32)
				timeVec = append(timeVec, uint32(s))
				if err != nil {
					fmt.Println("Failed to parse scan result from SQL query.")
				}

			} else { // The rest columns are the data matrix
				s, err := strconv.ParseFloat(data, 64)
				rawData = append(rawData, s)
				if err != nil {
					fmt.Println("Failed to parse scan result from SQL query.")
				}

			}
		}
		dataMat = append(dataMat, rawData) // Append the data to the data matrix
	}
	return timeVec, dataMat, nil
}

// QueryInfo query the information of the data
// Args:
// 	id: the id of the data
// 	column: the column name of the data
// Return:
// 	para: the value of the column	
// 	err: the error of the query
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
// 	id: the id of the data
// Return:
// 	time: the last time of the data
func (handler *Handler) QueryLastSynt(id uint16) uint32 {
	var time string
	tableName := "record" + strconv.Itoa(int(id))
	query := fmt.Sprintf(
		"SELECT simulink_time FROM %s.%s ORDER BY simulink_time DESC LIMIT 1;",
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
// 	id: the id of the data
// Return:
// 	time: the first time of the data
func (handler *Handler) QueryFirstSynt(id uint16) uint32 {
	var time string
	tableName := "record" + strconv.Itoa(int(id))
	query := fmt.Sprintf(
		"SELECT simulink_time FROM %s.%s ORDER BY simulink_time LIMIT 1;",
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
