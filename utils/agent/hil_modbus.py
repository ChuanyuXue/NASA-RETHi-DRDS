import serial
from modbus_tk import modbus_rtu
import modbus_tk


class hil_modbus:
    def __init__(self, port="/dev/ttyUSB0") -> None:
        self.PORT = port

        BAUD_RATE = 9600
        TIMEOUT = 5

        BYTE_SIZE = serial.EIGHTBITS
        STOP_BIT = serial.STOPBITS_TWO
        PARITY = serial.PARITY_NONE

        self.SLAVE_ADDR = 1
        self.HOLDING_REG_ADDR = 0x0000
        self.LENGTH_PKT = 8

        ser = serial.Serial(port=port,
                            baudrate=BAUD_RATE,
                            bytesize=BYTE_SIZE,
                            parity=PARITY,
                            stopbits=STOP_BIT,
                            timeout=TIMEOUT,
                            xonxoff=0)
        self.master = modbus_rtu.RtuMaster(ser)
        self.master.set_timeout(TIMEOUT)

    def read(self):
        try:
            response = self.master.execute(
                self.SLAVE_ADDR, modbus_tk.defines.READ_INPUT_REGISTERS,
                self.HOLDING_REG_ADDR, 8)
            return response
        except modbus_tk.modbus.ModbusError as e:
            print("%s- Code=%d" % (e, e.get_exception_code()))
