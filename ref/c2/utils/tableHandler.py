r''' Utilities Script which contain helper objects to
facilitate serving the Command & Control (C2) database
By - Murali Krishnan R

:Note: Please mind the `,` in the SQL queries. SQLite3 doesn't
like any ambiguity :uwu:
'''
import sqlite3
from sqlite3 import Error

class TableHandler(object):
	'''Base Class for Table Handling
	'''
	def __init__(self, name, mode, dbLoc=None):
		assert isinstance(name, str), "Table name should be string!"
		assert mode in ['read', 'write'], "Valid modes: [`read`, `write`]"
		assert dbLoc is not None, "Provide valid DB Location!"
		# [!Note!] Should do more clever checks for this!
		self.dbLoc = dbLoc
		self.name = name
		self.mode = mode
		# Obtain connection and curson for Handler Object
		try:
			self.dbConn = sqlite3.connect(self.dbLoc)
			try:
				self.dbCursor = self.dbConn.cursor()
			except Error as err_cursor:
				print(f"Error getting cursor to DB: {err_cursor}")
		except Error as err_conn:
			print(f"Error creating DB connection: {err_conn}")

class SimFDDTableHandler(TableHandler):
	''' The table specification for Simulated FDDs within C2-Database
	'''
	def __init__(self, name, nH, mode, dbLoc=None):
		
		TableHandler.__init__(self, name, mode, dbLoc)
		
		assert nH>=1, "Minimum 1 Health State for Simulated FDDs"
		self.nH = nH
		
		if self.mode == 'write':
			self.init_writeHandler()
		elif self.mode == 'read':
			self.init_readHandler()

	def init_writeHandler(self):
		'''Initializes a write handler for Simulated FDD Table
		'''
		# Strings for SQL Commands
		l_cInfo = ['hs_{} double'.format(str(i)) for i in range(1, self.nH+1)]
		l_iInfo = ['hs_{}'.format(str(i)) for i in range(1, self.nH+1)]
		l_vInfo = ['?' for _ in range(self.nH)]
		
		assert len(l_cInfo) == len(l_iInfo) == len(l_vInfo), \
		"Auto-lambdas have issues"
		createInfo = ','.join(l_cInfo)
		insertInfo = [','.join(l_iInfo), ','.join(l_vInfo)]

		self.cQuery = '''DROP TABLE IF EXISTS {0};
						 CREATE TABLE IF NOT EXISTS {0}
						 (testbed_TS integer PRIMARY KEY, {1});
						'''.format(self.name, createInfo)
		self.iQuery = '''INSERT INTO {0}
						 (testbed_TS, {1})
						 VALUES(?,{2});
						 '''.format(self.name,insertInfo[0],insertInfo[1])

		self.fQuery = None
		self.queries = [self.cQuery, self.iQuery, self.fQuery]
		try:
			self.dbCursor.executescript(self.cQuery)
		except Error as err_creation:
			print(f"[!] Error creating table [{self.name}] in DB!!")

	def insert_into_table(self, values):
		'''Insert into resp. sim FDD table
		'''
		assert self.mode == 'write', f"Handler configured for {self.mode}, not `write`"
		assert values is not None, "Nonetype cannot go into DB tables!"
		self.dbCursor.execute(self.iQuery, values)
		self.dbConn.commit()

	def init_readHandler(self):
		'''Initialize Read Handler for the Sim FDD Tables
		'''
		self.cQuery = None
		self.iQuery = None
		# l_fInfo = ['hs_{}'.format(str(i)) for i in range(1, self.nH+1)]
		# fetchInfo = ','.join(l_fInfo)
		self.fQuery = '''SELECT *
						 FROM {0}
						 WHERE testbed_TS > {{0}}
						 ORDER BY testbed_TS ASC;
						 '''.format(self.name)
		self.queries = [self.cQuery, self.iQuery, self.fQuery]
		verbose = False
		if verbose:
			print(self.name)
			print(self.queries)


	def fetch_from_table(self, last_ts, debug=False):
		'''Fetch data from the table
		'''
		limit = 5
		tStamp = last_ts if last_ts else 0

		dbg_fQuery = '''SELECT *
						FROM {0}
						WHERE testbed_TS > {{0}}
						ORDER BY testbed_TS ASC
						LIMIT {1};
					'''.format(self.name, limit)
		try:
			if debug:
				self.dbCursor.execute(dbg_fQuery.format(tStamp))
			else:
				self.dbCursor.execute(self.fQuery.format(tStamp))

			rows = self.dbCursor.fetchall()
			assert len(rows) > 1, f"[!] Empty rows fetched from [{self.name}] table!"
			n_timestamp = rows[len(rows)-1][0]
		except Error as err_fetch:
			print(f"[!] Error in fetching data from {self.name}!")

		return rows, n_timestamp

class AgentTableHandler(TableHandler):
	'''The table specification for Agent Model within C2-Database
	'''
	def __init__(self, name, mode, dbLoc=None):
		TableHandler.__init__(self, name, mode, dbLoc)
		
		if self.mode == 'write':
			self.init_writeHandler()
		elif self.mode == 'read':
			self.init_readHandler()


		verbose = False
		if verbose:
			print("In AgentTableHandler!!!!")
			print("Name: ", self.name)
			print("DB Conn: ", self.dbConn)
			print("DB Cursor: ", self.dbCursor)

	def init_writeHandler(self):
		'''Initializes a write handler for the Agent Table
		'''
		# Table Creation Query
		self.cQuery = '''DROP TABLE IF EXISTS {0};
						 CREATE TABLE IF NOT EXISTS {0}
						 (
						 testbed_TS integer PRIMARY KEY,
						 act_id double
						 );
						 '''.format(self.name)
		# Insertion Query
		self.iQuery = '''INSERT INTO {0}
						 (testbed_TS, act_id)
						 VALUES (?,?);
						 '''.format(self.name)

		# Fetch Query
		self.fQuery = None
		# Table connection to DB
		self.queries = [self.cQuery, self.iQuery, self.fQuery]
		# Create an empty table in the DB
		try:
			self.dbCursor.executescript(self.cQuery)
		except Error as err_creation:
			print(f"[!] Error creating table [{self.name}] in DB!")

		verbose=False
		if verbose:
			print(f"In {self.name} initialize_write_handler()!!!!")
			print("dbLoc: ", self.dbLoc)
			print("dbConn: ", self.dbConn)
			print("dbCursor: ", self.dbCursor)

	def insert_into_table(self, values):
		'''Insert into agent table
		'''
		assert self.mode == 'write', f"Handler configured for {self.mode}, not `write`"
		assert values is not None, "Empty values cannot go into tables!"
		self.dbCursor.execute(self.iQuery, values)
		self.dbConn.commit()

	def init_readHandler(self):
		self.cQuery = None
		self.iQuery = None
		self.fQuery = '''SELECT *
						 FROM {0}
						 WHERE testbed_TS > {{0}}
						 ORDER BY testbed_TS ASC;
						 '''.format(self.name)
		self.queries = [self.cQuery, self.iQuery, self.fQuery]
		
		verbose = False
		if verbose:
			print(self.name)
			print(self.queries)
			print(self.dbConn, self.dbCursor)

	def fetch_from_table(self, last_ts, debug=False):
		'''Fetch data from the table
		'''
		tStamp = last_ts if last_ts else 0
		limit = 5
		dbg_fQuery = '''SELECT *
						FROM {0}
						WHERE testbed_TS > {{0}}
						ORDER BY testbed_TS ASC
						LIMIT {1}
					'''.format(self.name, limit)
		try:
			if debug:
				self.dbCursor.execute(dbg_fQuery.format(tStamp))
			else:
				self.dbCursor.execute(self.fQuery.format(tStamp))

			rows = self.dbCursor.fetchall()
			assert len(rows) > 1, f"[!] Empty rows fetched from [{self.name}] table!"
			n_timestamp = rows[len(rows)-1][0]
		except Error as err_fetch:
			print(f"[!] Error in fetching data from {self.name}!")


		return rows, n_timestamp

class NPGTableHandler(TableHandler):
	'''The table specification for NPG Model within C2-Database
	'''
	def __init__(self, name, mode, dbLoc=None):
		TableHandler.__init__(self, name, mode, dbLoc)
		
		if self.mode == 'write':
			self.init_writeHandler()
		elif self.mode == 'read':
			self.init_readHandler()


		verbose = False
		if verbose:
			print("In NPGTableHandler!!!!")
			print("Name: ", self.name)
			print("DB Conn: ", self.dbConn)
			print("DB Cursor: ", self.dbCursor)

	def init_writeHandler(self):
		'''Initializes a write handler for the Agent Table
		'''
		# Table Creation Query
		self.cQuery = '''DROP TABLE IF EXISTS {0};
						 CREATE TABLE IF NOT EXISTS {0}
						 (
						 testbed_TS integer PRIMARY KEY,
						 dust_hs double
						 );
						 '''.format(self.name)
		# Insertion Query
		self.iQuery = '''INSERT INTO {0}
						 (testbed_TS, dust_hs)
						 VALUES (?,?);
						 '''.format(self.name)

		# Fetch Query
		self.fQuery = None
		# Table connection to DB
		self.queries = [self.cQuery, self.iQuery, self.fQuery]
		# Create an empty table in the DB
		try:
			self.dbCursor.executescript(self.cQuery)
		except Error as err_creation:
			print(f"[!] Error creating table [{self.name}] in DB!")

		verbose=False
		if verbose:
			print(f"In {self.name} initialize_write_handler()!!!!")
			print("dbLoc: ", self.dbLoc)
			print("dbConn: ", self.dbConn)
			print("dbCursor: ", self.dbCursor)

	def insert_into_table(self, values):
		'''Insert into agent table
		'''
		assert self.mode == 'write', f"Handler configured for {self.mode}, not `write`"
		assert values is not None, "Empty values cannot go into tables!"
		self.dbCursor.execute(self.iQuery, values)
		self.dbConn.commit()

	def init_readHandler(self):
		self.cQuery = None
		self.iQuery = None
		self.fQuery = '''SELECT *
						 FROM {0}
						 WHERE testbed_TS > {{0}}
						 ORDER BY testbed_TS ASC;
						 '''.format(self.name)
		self.queries = [self.cQuery, self.iQuery, self.fQuery]
		
		verbose = False
		if verbose:
			print(self.name)
			print(self.queries)
			print(self.dbConn, self.dbCursor)

	def fetch_from_table(self, last_ts, debug=False):
		'''Fetch data from the table
		'''
		tStamp = last_ts if last_ts else 0
		limit = 5
		dbg_fQuery = '''SELECT *
						FROM {0}
						WHERE testbed_TS > {{0}}
						ORDER BY testbed_TS ASC
						LIMIT {1}
					'''.format(self.name, limit)
		try:
			if debug:
				self.dbCursor.execute(dbg_fQuery.format(tStamp))
			else:
				self.dbCursor.execute(self.fQuery.format(tStamp))

			rows = self.dbCursor.fetchall()
			assert len(rows) > 1, f"[!] Empty rows fetched from [{self.name}] table!"
			n_timestamp = rows[len(rows)-1][0]
		except Error as err_fetch:
			print(f"[!] Error in fetching data from {self.name}!")


		return rows, n_timestamp