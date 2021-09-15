package databasemanager

import (
	"database/sql"
	"datarepo/src/units"
	"fmt"

	_ "github.com/go-sql-driver/mysql"
)

type Manager interface {
	AccessDatabase()
	CreateTable()
	InsertData()
	DeleteTable()
}

type DemoManager struct {
	Database *sql.DB
	MetaData units.MetaData
	count    int64
}

func (this *DemoManager) AccessDatabase() {
	db, err := sql.Open("mysql", "root:xcy199818x@tcp(127.0.0.1:3306)/nasa")
	err = db.Ping()
	if err != nil {
		fmt.Println("[!] Error: Can't access database")
	} else {
		fmt.Println("Connected!")
		this.Database = db
		var id int
		err := db.QueryRow("SELECT id FROM nasa ORDER BY id DESC LIMIT 1").Scan(&id)
		fmt.Println(err)
		fmt.Println("max", id)
		this.count = int64(id + 1)

	}
}

func (this *DemoManager) InsertData(metadata units.MetaData) {
	// fmt.Println(this.count, metadata.Index, metadata.Data)
	// fmt.Println(this.Database)
	stmt, _ := this.Database.Prepare("INSERT INTO nasa(id,src,value0,value1,value2) VALUES (?,?,?,?,?)")

	_, err := stmt.Exec(this.count, metadata.Index, metadata.Data[0], metadata.Data[1], metadata.Data[2])
	if err != nil {
		fmt.Println("[!] Insert error", err)
	} else {
		fmt.Println("Data inserted")
		this.count += 1
	}

}
