import pandas as pd
import sqlite3

# simulate some data


# function to write csv to .db file
def pandas_db_reader(db_file):

    conn = sqlite3.connect(db_file)
    c = conn.cursor()
    c.execute("SELECT name FROM sqlite_master WHERE type='table';")
    names = [tup[0] for tup in c.fetchall()]
    print(names)
    
    print(conn.("SHOW TABLES"))

    table = pd.read_sql_query("SELECT * from {}".format("FDD_SPG_DUST"), conn)
    print(table)
    conn.close()
    return

out_db = 'mcvt_run_agnt_spg_ep_ed_new.db'
pandas_db_reader(out_db)