package handler

import (
	"database/sql"
	"datarepo/src/utils"
	"fmt"
	"regexp"

	_ "github.com/go-sql-driver/mysql"
)

type Handler struct {
	utils.JsonStandard

	Local  string `json:"local"`
	Public string `json:"public"`
	Port   string `json:"port"`
	DBType string `json:"db_type"`
	DBName string `json:"db_name"`

	DBPointer *sql.DB
	Tables    []string
	FDDTables []uint8

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
	rows, err := handler.DBPointer.Query("SHOW TABLES from nasa")
	if err != nil {
		return err
	}

	reg := regexp.MustCompile(`fdd\d+`)
	for rows.Next() {
		err := rows.Scan(&tableName)
		if err != nil {
			fmt.Println("Failed to load data:", err)
		} else {
			match := reg.FindAllString(tableName, -1)
			if match != nil {
				temp, err := utils.StringToInt(match[0][3:])
				if err != nil{
					return err
				}
				handler.FDDTables = append(handler.FDDTables, uint8(temp))
			}
			handler.Tables = append(handler.Tables, tableName)
		}
	}

	return nil
}
