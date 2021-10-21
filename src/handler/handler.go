package handler

import (
	"database/sql"
	"datarepo/src/utils"
	"errors"
	"fmt"
	"regexp"
	"strconv"

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
	FDDTables    []uint8
	SensorTables []uint8

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
	qurry := fmt.Sprintf("SHOW TABLES from %s", handler.DBName)
	rows, err := handler.DBPointer.Query(qurry)
	if err != nil {
		return err
	}

	regFdd := regexp.MustCompile(`fdd\d+`)
	regSensor := regexp.MustCompile(`sensor\d+`)
	for rows.Next() {
		err := rows.Scan(&tableName)
		if err != nil {
			fmt.Println("Failed to load data:", err)
		} else {
			// Sniff FDD Table
			matchFdd := regFdd.FindAllString(tableName, -1)
			if matchFdd != nil {
				temp, err := utils.StringToInt(matchFdd[0][3:])
				if err != nil {
					fmt.Println("Sniff FDD table error:", err)
				}
				handler.FDDTables = append(handler.FDDTables, uint8(temp))
			}
			// Sniff Sensor Table
			matchSensor := regSensor.FindAllString(tableName, -1)
			if matchSensor != nil {
				temp, err := utils.StringToInt(matchSensor[0][3:])
				if err != nil {
					fmt.Println("Sniff Sensor table error:", err)
				}
				handler.SensorTables = append(handler.SensorTables, uint8(temp))
			}
			// Sniff all Table
			handler.Tables = append(handler.Tables, tableName)
		}
	}

	return nil
}

func (handler *Handler) Write(id uint8, index uint32, value float64, loc uint32, time uint32) error {
	var tableName string
	if utils.Uint8Contains(handler.FDDTables, id) {
		tableName = "fdd" + strconv.Itoa(int(id))
	} else if utils.Uint8Contains(handler.SensorTables, id) {
		tableName = "sensor" + strconv.Itoa(int(id))
	} else {
		return errors.New("writing value into unrecognized id")
	}

	qurry := fmt.Sprintf(
		"INSERT INTO %s.%s (%s, %s, %s, %s) VALUES (?, ?, ?, ?);",
		handler.DBName,
		tableName,
		"time",
		"id",
		"value",
		"loc",
	)

	stmt, err := handler.DBPointer.Prepare(qurry)
	if err != nil {
		return err
	}
	_, err = stmt.Exec(time, index, value, loc)
	if err != nil {
		return err
	}
	return nil
}

func (handler *Handler) ReadIndex(id uint8, index uint8, valueName string) ([]float64, error) {
	var tableName string
	var rawData []float64

	if utils.Uint8Contains(handler.FDDTables, id) {
		tableName = "fdd" + strconv.Itoa(int(id))
	} else if utils.Uint8Contains(handler.SensorTables, id) {
		tableName = "sensor" + strconv.Itoa(int(id))
	} else {
		return rawData, errors.New("writing value into unrecognized id")
	}

	qurry := fmt.Sprintf(
		"SELECT %s FROM %s.%s WHERE id = %s;",
		valueName,
		handler.DBName,
		tableName,
		strconv.Itoa(int(index)),
	)

	rows, err := handler.DBPointer.Query(qurry)
	if err != nil {
		return rawData, err
	}

	for rows.Next() {
		var value float64
		err := rows.Scan(&value)
		rawData = append(rawData, value)
		if err != nil {
			return rawData, err
		}
	}
	return rawData, nil
}

func (handler *Handler) ReadTime(id uint8, time uint8, valueName string) (float64, error) {
	var tableName string
	var rawData float64

	if utils.Uint8Contains(handler.FDDTables, id) {
		tableName = "fdd" + strconv.Itoa(int(id))
	} else if utils.Uint8Contains(handler.SensorTables, id) {
		tableName = "sensor" + strconv.Itoa(int(id))
	} else {
		return rawData, errors.New("writing value into unrecognized id")
	}

	qurry := fmt.Sprintf(
		"SELECT %s FROM %s.%s WHERE time = %s;",
		valueName,
		handler.DBName,
		tableName,
		strconv.Itoa(int(time)),
	)

	err := handler.DBPointer.QueryRow(qurry).Scan(&rawData)
	if err != nil {
		return rawData, err
	}
	return rawData, nil
}

func (Handler *Handler) handle(id uint8, rawData []float64) []float64 {
	return rawData
}
