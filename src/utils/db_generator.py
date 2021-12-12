import mysql.connector
import json


class db_generator:
    def __init__(self, conf_path) -> None:
        with open(conf_path) as f:
            self.param = json.load(f)

        if self.param['public'] != 'NA':
            self.param['local'] = self.param['public']

        self.cnx = mysql.connector.connect(
            user=self.param['user_name'],
            password=self.param['password'],
            host=self.param['local'],
            database=self.param['db_name']
        )

    def create_info(self, table_id=0) -> None:
        table_name = "info%d" % table_id
        create_table = '''
            CREATE TABLE `%s`.`%s` (
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
            ''' % (self.param['db_name'], table_name)
        cursor = self.db.cursor()
        cursor.execute("DROP TABLE IF EXISTS %s.%s" %
                       (self.param['db_name'], table_name))
        cursor.execute(create_table)

    def insert_info(self, data_description: dict) -> None:
        act = '''
        INSERT INTO `%s`.`info0` (`data_id`, `data_name`, `data_type`,`data_subtype1`,`data_subtype2`, `data_rate`, `data_size`,`data_unit`,`data_notes`) VALUES
        ('%d', '%s', '%d', '%d', '%d', '%d', '%d', '%s', '%s');
        '''

        data_id = data_description["data_id"]
        data_name = data_description["data_name"]
        data_type = data_description["data_type"]
        data_subtype1 = data_description["data_subtype1"] if "data_subtype1" in data_description else 255
        data_subtype2 = data_description["data_subtype2"] if "data_subtype2" in data_description else 255
        data_rate = data_description["data_rate"]
        data_size = data_description["data_size"]
        data_unit = data_description["data_unit"] if "data_unit" in data_description else "-"
        data_notes = data_description["data_notes"] if "data_notes" in data_description else "-"

        insert_table = act % (data_base, data_id, data_name, data_type, data_subtype1, data_subtype2, data_rate, data_size, data_unit, data_notes))
        cursor=self.db.cursor()
        cursor.execute(insert_table)


    def create_relationship(self, table_id = 1) -> None:
        table_name="rela%d" % table_id
        create_table='''
        CREATE TABLE `%s`.`%s` (
        `relationship_id` INT UNSIGNED NOT NULL,
        `input_data_id` INT(16) UNSIGNED NOT NULL,
        `output_data_id` INT(16) UNSIGNED NOT NULL,
        `subsystem_id` INT(8) UNSIGNED NULL,
        `relation_type` INT(8) UNSIGNED NULL,
        PRIMARY KEY (`relationship_id`),
        UNIQUE INDEX `relationship_id_UNIQUE` (`relationship_id` ASC) VISIBLE);
        ''' % (self.param['db_name'], table_name)
        cursor=self.db.cursor()
        cursor.execute("DROP TABLE IF EXISTS %s.%s" %
                       (self.param['db_name'], table_name))
        cursor.execute(create_table)

    def create_link(self, table_id = 2) -> None:
        table_name="link%d" % table_id
        create_table='''
        CREATE TABLE `%s`.`%s` (
        `data_id` INT(16) UNSIGNED NOT NULL,
        `input_subsystem_id` INT(8) UNSIGNED NOT NULL,
        `output_subsystem_id` INT(8) UNSIGNED NOT NULL,
        `interaction_type` INT(8) UNSIGNED NULL,
        PRIMARY KEY (`data_id`),
        UNIQUE INDEX `data_id_UNIQUE` (`data_id` ASC) VISIBLE);
        ''' % (self.param['db_name'], table_name)
        cursor=self.db.cursor()
        cursor.execute("DROP TABLE IF EXISTS %s.%s" %
                       (self.param['db_name'], table_name))
        cursor.execute(create_table)

    def create_data(self, table_id, shape) -> None:
        table_name='record%d' % table_id
        create_table=''.join(
            [
                "create table `%s` (" % table_name,
                "`simulink_time` int unsigned NOT NULL,",
                "`physical_time` int unsigned NOT NULL,",

            ] + [
                "`value%d` float," % x for x in range(shape)

            ] + [
                "primary key (`simulink_time`), UNIQUE KEY `simulink_time` (`simulink_time`)",
                ")ENGINE=InnoDB"

            ]
        )
        cursor = self.db.cursor()
        cursor.execute("DROP TABLE IF EXISTS %s.%s" %
                       (self.param['db_name'], table_name))
        cursor.execute(create_table)

if __name__ == '__main__':
    for db in ["habitat", "ground"]:
        generator = db_generator('../../config/%s.json')
        generator.create_info()
        generator.create_relationship()
        generator.create_link()

        