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

func (handler *Handler) Init(src uint8) error {
	var (
		err       error
		tableName string
	)

	// -------------------------- Fix the paramter for docker envirioment

	if src == 0 {
		handler.DBPointer, err = sql.Open("mysql", fmt.Sprintf("%v:%v@(ground_db:3306)/%v", // "hms_db" is the database container's name in the docker-compose.yml
			os.Getenv("DB_USER_GROUND"),
			os.Getenv("DB_PASSWORD_GROUND"),
			os.Getenv("DB_NAME_GROUND")))
		handler.DBName = "ground"

	} else if src == 1 {
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

	// -------------------------- Fix the paramter for docker envirioment

	//Record all tables
	query := fmt.Sprintf("SHOW TABLES from %s", handler.DBName)
	rows, err := handler.DBPointer.Query(query)
	if err != nil {
		return err
	}

	regInteraction := regexp.MustCompile(`link\d+`)
	regRelationship := regexp.MustCompile(`rela\d+`)
	regInfo := regexp.MustCompile(`info\d+`)
	regRecord := regexp.MustCompile(`record\d+`)
	for rows.Next() {
		err := rows.Scan(&tableName)
		if err != nil {
			fmt.Println("Failed to load data:", err)
		} else {
			// Sniff Interaction Table
			matchInte := regRelationship.FindAllString(tableName, -1)
			if matchInte != nil {
				temp, err := utils.StringToInt(matchInte[0][4:])
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
				temp, err := utils.StringToInt(matchLink[0][4:])
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
				temp, err := utils.StringToInt(matchInfo[0][4:])
				if err != nil {
					fmt.Println("Sniff Data Information table error:", err)
					return err
				}
				if temp != 0 {
					fmt.Println("Table ID of information table not equal to zero!", err)
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
				handler.RecordTables = append(handler.RecordTables, uint16(temp))
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
		handler.DataShapes[dataId] = dataSize
	}
	return nil
}

func (handler *Handler) WriteSynt(id uint16, synt uint32, phyt uint32, value []float64) error {
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
	columnList = append(columnList, "simulink_time")
	columnList = append(columnList, "physical_time")
	columnList = append(columnList, "physical_time_2")

	for i := 0; i != int(handler.DataShapes[id]); i++ {
		columnList = append(columnList, "value"+strconv.Itoa(i))
	}
	columnPattern := strings.Join(columnList, ",")

	columnFillin = append(columnFillin, strconv.Itoa(int(synt)))
	// Need to fix int64 -> unsigned int32?
	columnFillin = append(columnFillin, strconv.Itoa(int(phyt)))
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

func (handler *Handler) ReadSynt(id uint16, synt uint32) ([]float64, error) {
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
		"SELECT %s FROM %s.%s WHERE simulink_time = %s;",
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

	query := fmt.Sprintf(
		"SELECT simulink_time,%s FROM %s.%s WHERE (simulink_time >= %s) AND (simulink_time < %s);",
		columnPattern,
		handler.DBName,
		tableName,
		strconv.Itoa(int(start)),
		strconv.Itoa(int(end)),
	)

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

			if i == 0 {
				s, err := strconv.ParseInt(data, 10, 32)
				timeVec = append(timeVec, uint32(s))
				if err != nil {
					fmt.Println("Failed to parse scan result from SQL query.")
				}

			} else {
				s, err := strconv.ParseFloat(data, 64)
				rawData = append(rawData, s)
				if err != nil {
					fmt.Println("Failed to parse scan result from SQL query.")
				}

			}
		}
		dataMat = append(dataMat, rawData)
	}
	return timeVec, dataMat, nil
}

func (handler *Handler) QueryInfo(id uint16, column string) (int, error) {

	tableName := "info" + strconv.Itoa(int(handler.InfoTable))
	query := fmt.Sprintf(
		"SELECT %s FROM "+
			handler.DBName+"."+tableName+
			" WHERE DATA_ID = %d", column, int(id),
	)

	row := handler.DBPointer.QueryRow(query)
	var result string
	err := row.Scan(&result)
	if err != nil {
		return 0, err
	}
	para, err := utils.StringToInt(result)
	if err != nil {
		return 0, err
	}
	return int(para), nil
}

func (handler *Handler) QueryLastSynt(id uint16) uint32 {
	var time string
	tableName := "record" + strconv.Itoa(int(id))
	query := fmt.Sprintf(
		"SELECT simulink_time FROM %s.%s ORDER BY simulink_time DESC LIMIT 1;",
		handler.DBName,
		tableName,
	)
	row := handler.DBPointer.QueryRow(query)
	err := row.Scan(&time)
	if err != nil {
		fmt.Println("Failed to retrieve last time stamp")
	}
	result, _ := utils.StringToInt(time)
	return uint32(result)
}

func (handler *Handler) QueryFirstSynt(id uint16) uint32 {
	var time string
	tableName := "record" + strconv.Itoa(int(id))
	query := fmt.Sprintf(
		"SELECT simulink_time FROM %s.%s ORDER BY simulink_time LIMIT 1;",
		handler.DBName,
		tableName,
	)
	row := handler.DBPointer.QueryRow(query)
	err := row.Scan(&time)
	if err != nil {
		fmt.Println("Failed to retrieve last time stamp")
	}
	result, _ := utils.StringToInt(time)
	return uint32(result)
}
