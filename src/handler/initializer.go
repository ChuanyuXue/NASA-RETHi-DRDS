package handler

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"time"

	"github.com/ChuanyuXue/NASA-RETHi-DRDS/src/utils"
)

// TableInfo struct defines the structure of the data information table
type TableInfo struct {
	utils.JsonStandard
	Id       uint16 `json:"data_id"`
	Name     string `json:"data_name"`
	Type     uint16 `json:"data_type"`
	Subtype1 uint16 `json:"data_subtype1"`
	Subtype2 uint16 `json:"data_subtype2"`
	Rate     uint16 `json:"data_rate"`
	Size     uint16 `json:"data_size"`
	Unit     string `json:"data_unit"`
	Notes    string `json:"data_notes"`
}

// ReadDataInfo function reads the data information from the specified file path
// Args:
//
//	path: the path of the data information file
//
// Returns:
//
//	dataList: the list of data information
func ReadDataInfo(path string) ([]TableInfo, error) {
	var dataList []TableInfo
	var objmap map[string]json.RawMessage // map of data information

	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// Read the file content
	byteValue, err := ioutil.ReadAll(file)
	if err != nil {
		fmt.Println("Failed to read data configuration file")
		return nil, err
	}

	// Unmarshal the json content
	err = json.Unmarshal(byteValue, &objmap)
	if err != nil {
		fmt.Println("Failed to unmarshal data configuration json file")
		return nil, err
	}
	// dataList = make([]TableInfo, len(objmap))

	// Append the unmarshaled json object to the dataList slice
	for _, value := range objmap {
		var info TableInfo
		err = json.Unmarshal(value, &info)
		if err != nil {
			return nil, err
		}
		dataList = append(dataList, info)
	}
	return dataList, nil

}

// DatabaseGenerator function creates a database and a table according to the data information
// Args:
// 	src: the source of the data
// 	path: the path of the data information file
// Returns:
// 	err: error

func DatabaseGenerator(src uint8, path string) error {
	// -------------------- Connect database ----------------------------------
	var err error
	var db *sql.DB
	var dbName string
	if src == utils.SYSTEM_ID["GCC"] { // gcc
		db, err = sql.Open("mysql", fmt.Sprintf("%v:%v@(ground_db:3306)/%v", // "hms_db" is the database container's name in the docker-compose.yml
			os.Getenv("DB_USER_GROUND"),
			os.Getenv("DB_PASSWORD_GROUND"),
			os.Getenv("DB_NAME_GROUND")))
		dbName = "ground"

	} else if src == utils.SYSTEM_ID["HMS"] { // hms
		db, err = sql.Open("mysql", fmt.Sprintf("%v:%v@(habitat_db:3306)/%v", // "hms_db" is the database container's name in the docker-compose.yml
			os.Getenv("DB_USER_HABITAT"),
			os.Getenv("DB_PASSWORD_HABITAT"),
			os.Getenv("DB_NAME_HABITAT")))
		dbName = "habitat"
	}
	if err != nil {
		fmt.Println(err)
		return err
	}

	// wait database container to start
	for {
		err := db.Ping()
		if err == nil {
			break
		}
		fmt.Println(err)
		time.Sleep(1 * time.Second)
	}

	tableName := "info0"
	drop := fmt.Sprintf(`DROP TABLE IF EXISTS %s.%s`, dbName, tableName)
	_, err = db.Exec(drop)
	if err != nil {
		fmt.Println(err)
	}
	action := fmt.Sprintf(`CREATE TABLE %s.%s (
            data_id INT(16) UNSIGNED NOT NULL,
            data_name VARCHAR(128) NULL,
            data_type INT(8) UNSIGNED NOT NULL,
            data_subtype1 INT(8) UNSIGNED NULL,
            data_subtype2 INT(8) UNSIGNED NULL,
            data_rate INT(16) UNSIGNED NULL,
            data_size INT(16) UNSIGNED NULL,
            data_unit VARCHAR(45) NULL,
            data_notes VARCHAR(128) NULL,
            PRIMARY KEY (data_id),
            UNIQUE INDEX data_id_UNIQUE (data_id ASC) VISIBLE);`, dbName, tableName) // UNIQUE INDEX data_id_UNIQUE (data_id ASC) VISIBLE

	_, err = db.Exec(action) // create table
	if err != nil {
		fmt.Println(err)
	}

	// ---------------------- Read json file

	dataList, err := ReadDataInfo(path)
	if err != nil {
		fmt.Println(err)
		return err
	}

	// ---------------------- Insert info

	for _, info := range dataList {
		act := fmt.Sprintf(`INSERT INTO %s.%s (data_id, data_name, data_type, data_subtype1, data_subtype2, data_rate, data_size) VALUES
				("%d", "%s", "%d", "%d","%d","%d", "%d");`, dbName, tableName, info.Id, info.Name, info.Type, info.Subtype1, info.Subtype2, info.Rate, info.Size)
		_, err = db.Exec(act)
		if err != nil {
			fmt.Println(err)
		}
	}

	// ---------------------- Create data table
	for _, info := range dataList {
		tableName = fmt.Sprintf(`record%d`, info.Id)
		drop := fmt.Sprintf(`DROP TABLE IF EXISTS %s`, tableName)
		db.Exec(drop)
		act := fmt.Sprintf("create table `%s` (", tableName)
		act = act + "iter int unsigned NOT NULL,"
		act = act + "send_t bigint unsigned NOT NULL,"
		act = act + "recv_t bigint unsigned NOT NULL,"
		for i := 0; i != int(info.Size); i++ {
			act = act + fmt.Sprintf("v%d float,", i)
		}
		act = act + "primary key (iter), UNIQUE KEY (iter)"
		act = act + ")ENGINE=InnoDB" // ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci"

		_, err = db.Exec(act)
		if err != nil {
			fmt.Println(err)
		}
	}
	return nil
}
