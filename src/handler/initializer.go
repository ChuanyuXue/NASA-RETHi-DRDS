package handler

import (
	"database/sql"
	"fmt"
	"os"
	"time"
)

func DatabaseGenerator(src uint8) error {
	// -------------------- Connect database ----------------------------------
	var err error
	var db *sql.DB
	var dbName string
	if src == 0 {
		db, err = sql.Open("mysql", fmt.Sprintf("%v:%v@(ground_db:3306)/%v", // "hms_db" is the database container's name in the docker-compose.yml
			os.Getenv("DB_USER_GROUND"),
			os.Getenv("DB_PASSWORD_GROUND"),
			os.Getenv("DB_NAME_GROUND")))
		dbName = "ground"

	} else if src == 1 {
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
		time.Sleep(2 * time.Second)
	}

	// ----------------------- Create table ------------------------------
	tableName := "info0"
	drop := fmt.Sprintf(`DROP TABLE IF EXISTS %s.%s`, dbName, tableName)
	_, err = db.Exec(drop)
	action := fmt.Sprintf(`CREATE TABLE %s.%s (
            data_id INT(16) UNSIGNED NOT NULL,
            data_name VARCHAR(45) NULL,
            data_type INT(8) UNSIGNED NOT NULL,
            data_subtype1 INT(8) UNSIGNED NULL,
            data_subtype2 INT(8) UNSIGNED NULL,
            data_rate INT(16) UNSIGNED NULL,
            data_size INT(16) UNSIGNED NULL,
            data_unit VARCHAR(45) NULL,
            data_notes VARCHAR(45) NULL,
            PRIMARY KEY (data_id),
            UNIQUE INDEX data_id_UNIQUE (data_id ASC) VISIBLE);`, dbName, tableName)

	_, err = db.Exec(action)
	if err != nil {
		fmt.Println(err, 1)
	}

	// ---------------------- Insert info
	idList := [...]uint16{8, 6, 131, 132, 133, 134, 3, 7, 128, 129, 130, 4, 5, 135, 136}
	nameList := [...]string{
		"agent",
		"str_dmg",
		"Sys2_Out_PanelDamageProbabilities",
		"Sys2_Out_Damage_Detection_Probabilities",
		"Sys2_Out_Impact_Location_Probabiilities",
		"Sys2_Out_FDD_Structure_Damage_xe",
		"spg_dust",
		"fdd_dust",
		"SolarPV_FDD",
		"SolarPV_FDD_simu",
		"Nuclear_Dust_FDD",
		"eclss_dust",
		"eclss_paint",
		"FDD_ECLSS_Dust_xe",
		"FDD_ECLSS_Paint_xe"}

	typeList := [...]uint8{1, 1, 2, 2, 2, 2, 1, 1, 2, 2, 2, 1, 1, 2, 2}
	rateList := [len(typeList)]uint16{}
	for i, _ := range idList {
		rateList[i] = 1000
	}
	sizeList := [...]uint16{1, 1, 1, 10, 5, 1, 4, 1, 1, 4, 1, 50, 50, 50, 50}

	for index, id := range idList {
		act := fmt.Sprintf(`INSERT INTO %s.%s (data_id, data_name, data_type, data_rate, data_size) VALUES
				("%d", "%s", "%d", "%d", "%d");`, dbName, tableName, id, nameList[index], typeList[index], rateList[index], sizeList[index])
		_, err = db.Exec(act)
		if err != nil {
			fmt.Println(err, 2)
		}
	}

	// ---------------------- Create data table
	for index, id := range idList {
		tableName = fmt.Sprintf(`record%d`, id)
		drop := fmt.Sprintf(`DROP TABLE IF EXISTS %s`, tableName)
		_, err = db.Exec(drop)
		act := fmt.Sprintf("create table `%s` (", tableName)
		act = act + "simulink_time int unsigned NOT NULL,"
		act = act + "physical_time int unsigned NOT NULL,"
		for i := 0; i != int(sizeList[index]); i++ {
			act = act + fmt.Sprintf("value%d float,", i)
		}
		act = act + "primary key (simulink_time), UNIQUE KEY simulink_time (simulink_time)"
		act = act + ")ENGINE=InnoDB"

		_, err = db.Exec(act)
		if err != nil {
			fmt.Println(err, 3)
		}
	}
	fmt.Println("Database has been initialized")
	return nil

}
