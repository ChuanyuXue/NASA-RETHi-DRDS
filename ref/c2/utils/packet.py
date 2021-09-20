from ctypes import *
import time

class Header(Structure):
	_fields_ = [("src", c_uint8),
				("dst", c_uint8),
				("type", c_uint8),
				("priority", c_uint8),
				("row", c_uint8),
				("col", c_uint8),
				("length", c_uint16)]

class Packet:
	def __init__(self):
		pass

	# payload is a double list
	def pkt2Buf(self, _src, _dst, _type, _priority, _row, _col, _length, _payload):
		'''Convert a packet to buffer
		''' 
		header_buf = Header(_src, _dst, _type, _priority, _row, _col, _length)
		double_arr = c_double * _length
		payload_buf = double_arr(*_payload)
		buf = bytes(header_buf)+bytes(payload_buf)
		return buf

	def buf2Pkt(self, buffer):
		'''Convert buffer to packet
		'''
		self.header = Header.from_buffer_copy(buffer[:8])
		double_arr = c_double * self.header.length
		self.payload = double_arr.from_buffer_copy(buffer[8:8+8*self.header.length])

	def get_values(self, buffer):
		'''Extract useful information from `buffer` to store into 
		appropriate database tables'''
		self.buf2Pkt(buffer)
		tableID = None
		values = None
		try:
			_pld_list = list(self.payload[:])
			tableID = int(_pld_list[0])
			testbed_TS = int(_pld_list[1])
			values = tuple([testbed_TS] + _pld_list[2:])
			assert values is not None, "`values` for table cannot be None."
			assert tableID is not None, "`tableID` cannot be None."
			return tableID, values
		except:
			print("[!] Error in extracting values from buffer!")