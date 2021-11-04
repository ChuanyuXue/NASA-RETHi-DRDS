import mysql.connector
for data_base in ["nasa", "nasa_mirror"]:
    cnx = mysql.connector.connect(user='root', password='12345678',
                                host='127.0.0.1',
                                database=data_base)

    tables = {}
    actions = {}

    data_id = 0
    table_name = "info%d"%data_id
    tables[table_name] = '''
    CREATE TABLE `%s`.`info0` (
    `data_id` INT(16) UNSIGNED NOT NULL,
    `data_name` VARCHAR(45) NULL,
    `data_type` INT(8) UNSIGNED NOT NULL,
    `data_subtype1` INT(8) UNSIGNED NULL,
    `data_subtype2` INT(8) UNSIGNED NULL,
    `data_rate` INT(16) UNSIGNED NULL,
    `data_size` INT(16) UNSIGNED NULL,
    `data_unit` VARCHAR(45) NULL,
    `data_notes` VARCHAR(45) NULL,
    PRIMARY KEY (`data_id`),
    UNIQUE INDEX `data_id_UNIQUE` (`data_id` ASC) VISIBLE);
    '''%data_base

    actions[table_name] = []

    act = '''
    INSERT INTO `%s`.`info0` (`data_id`, `data_name`, `data_type`, `data_rate`, `data_size`) VALUES 
    ('%d', '%s', '%d', '%d', '%d');
    '''

    data_id = 3
    data_name = "npg_dust"
    data_type = 1
    data_rate = 1000
    data_size = 1
    actions[table_name].append(act%(data_base, data_id, data_name, data_type, data_rate, data_size))

    data_id = 4
    data_name = "spg_paint"
    data_type = 1
    data_rate = 1000
    data_size = 4
    actions[table_name].append(act%(data_base, data_id, data_name, data_type, data_rate, data_size))

    data_id = 5
    data_name = "states_agent"
    data_type = 3
    data_rate = 1000
    data_size = 1
    actions[table_name].append(act%(data_base, data_id, data_name, data_type, data_rate, data_size))

    ### Create tables

    data_id = 1
    table_name = "rela%d"%data_id
    tables[table_name] = '''
    CREATE TABLE `%s`.`rela1` (
    `relationship_id` INT UNSIGNED NOT NULL,
    `input_data_id` INT(16) UNSIGNED NOT NULL,
    `output_data_id` INT(16) UNSIGNED NOT NULL,
    `subsystem_id` INT(8) UNSIGNED NULL,
    `relation_type` INT(8) UNSIGNED NULL,
    PRIMARY KEY (`relationship_id`),
    UNIQUE INDEX `relationship_id_UNIQUE` (`relationship_id` ASC) VISIBLE);
    '''%data_base

    data_id = 2
    table_name = "link%d"%data_id
    tables[table_name] = '''
    CREATE TABLE `%s`.`link2` (
    `data_id` INT(16) UNSIGNED NOT NULL,
    `input_subsystem_id` INT(8) UNSIGNED NOT NULL,
    `output_subsystem_id` INT(8) UNSIGNED NOT NULL,
    `interaction_type` INT(8) UNSIGNED NULL,
    PRIMARY KEY (`data_id`),
    UNIQUE INDEX `data_id_UNIQUE` (`data_id` ASC) VISIBLE);
    '''%data_base

    ## Create for npg dust
    data_id = 3
    table_name = 'record%d'%data_id
    tables[table_name] = ''.join(
        [
            "create table `%s` ("%table_name,
            "`simulink_time` int unsigned NOT NULL,",
            "`physical_time` int unsigned NOT NULL,",

        ] + [
            "`value%d` float,"%x for x in range(1)
            
        ] + [
            "primary key (`simulink_time`), UNIQUE KEY `simulink_time` (`simulink_time`)",
            ")ENGINE=InnoDB"
            
        ]
    )

    ## Create for spg dust
    data_id = 4
    table_name = 'record%d'%data_id
    tables[table_name] = ''.join(
        [
            "create table `%s` ("%table_name,
            "`simulink_time` int unsigned NOT NULL,",
            "`physical_time` int unsigned NOT NULL,",

        ] + [
            "`value%d` float,"%x for x in range(4)
            
        ] + [
            "primary key (`simulink_time`), UNIQUE KEY `simulink_time` (`simulink_time`)",
            ")ENGINE=InnoDB"
            
        ]
    )

    ## Create for agent
    data_id = 5
    table_name = 'record%d'%data_id
    tables[table_name] = ''.join(
        [
            "create table `%s` ("%table_name,
            "`simulink_time` int unsigned NOT NULL,",
            "`physical_time` int unsigned NOT NULL,",

        ] + [
            "`value%d` float,"%x for x in range(1)
            
        ] + [
            "primary key (`simulink_time`), UNIQUE KEY `simulink_time` (`simulink_time`)",
            ")ENGINE=InnoDB"
            
        ]
    )

    cursor = cnx.cursor()

    for key in tables:
        cursor.execute("DROP TABLE IF EXISTS %s.%s"%(data_base, key))        

    for key, value in tables.items():
        back = cursor.execute(value)
        if key in actions:
            for i in actions[key]:
                cursor.execute(i)
    print("Data base %s has been initialized"%data_base)
            
    cnx.close()