## Introduction

This instruction is about how to use Data Service Protocol on developing Simulink API. 

The goal is to send all of required data from Power System Simulink environment to Habitat Data Server via communication network. 

I think this goal can be achieved by following these steps:

## Step 1: Collect data descriptions

Figure 1 is the current Database Schema, the Step 1 is to write Description Data [Info(0) Table].

Figure 1:

<img src="./img/DDS_SCHEMA.drawio.png" style="zoom:33%;"  >

To fully incorporate current Database Schema, please fill out this table by hand as much as possible first. First line is an example for NPG_DUST_FDD data.

Table 1:

| Data_ID | Data_Name                         | Data_Type | Data_Subtype1 | Data_Subtype2 | Data_Rate | Data_Size | Data_Unit | Data_Notes         |
| ------- | --------------------------------- | --------- | ------------- | ------------- | --------- | --------- | --------- | ------------------ |
| 3       | npg_dust                          | 0x01      | -             | -             | 1000      | 1         | -         | Nuclear FDD output |
|         |                                   |           |               |               |           |           |           |                    |
|         |                                   |           |               |               |           |           |           |                    |
| 128     | sys3_in_dust_accumulation_nuclear |           |               |               |           |           |           |                    |
| 129     | Sys3_In_Dust_Accumulation_PV      |           |               |               |           |           |           |                    |
| 130     | Sys3_In_Solar_Flux                |           |               |               |           |           |           |                    |
| 131     | Sys3_In_Power_Consumed_by_Sys2    |           |               |               |           |           |           |                    |
| 132     | Sys3_In_Power_Consumed_by_Sys5    |           |               |               |           |           |           |                    |
| 133     | Sys3_In_Power_Consumed_by_Sys8    |           |               |               |           |           |           |                    |
| 134     | Sys3_Out_Power_Supply_to_Sys2     |           |               |               |           |           |           |                    |
| 135     | Sys3_Out_Power_Supply_to_Sys5     |           |               |               |           |           |           |                    |
| 136     | Sys3_Out_Power_Supply_to_Sys8     |           |               |               |           |           |           |                    |
| 137     | Sys3_Out_total_power              |           |               |               |           |           |           |                    |
| 138     | Sys3_Out_Physical_Input_Agents    |           |               |               |           |           |           |                    |
| 139     | Sys3_Out_Damage_Information       |           |               |               |           |           |           |                    |
| 140     | Sys3_Out_Current_Power_Stored     |           |               |               |           |           |           |                    |
|         |                                   |           |               |               |           |           |           |                    |
|         |                                   |           |               |               |           |           |           |                    |
| 256     | Sys3_In_Intervention              |           |               |               |           |           |           |                    |

Notes:

If you don't know how to fill for some columns, please fill in N/A . (For example Human intervention has no unit, so fill in N/A)

If you certainly know some columns should be empty, please fill in - . 

Data_ID, Data_Size, Data_Type must be filled with Unsigned Integer Value [1, 65535]

For Data ID

- For FDD data, please select from [3, 127]
- For Sensor data, please select from [128, 255]
- For Agent data, please select from [256, 383]
- For Other data, please select from [384, 511]

For Data Type

  - 0x00: No data
  - 0x01: FDD data
  - 0x02: Sensor data
  - 0x03: Agent data
  - 0x03: Other data

## Step 2:

The Step 2 is to write Relationship Data[rela(1) table] and Interactio Data[link(2) table].

*This procedure can be temporarily deferred until Yaml Graph is finished*



## Step 3:

Go through [MCVT code](https://github.com/murakrishn/mcvt_v15) and find the corresponding variable for each Data in Table 1.



## Step 4:

Change the communication part in MCVT code, let all variables found in Step 3 send by Service Protocol.

*I think [this file](https://github.com/murakrishn/mcvt_v15/blob/master/EMS_v15/SysFiles/Sys4_Communication/Comms_Config.m) is to configure how Simulink send data, but I am not sure if it can work by only changing this file*

<img src="/Users/chuanyu/Library/Application Support/typora-user-images/Screen Shot 2021-11-14 at 5.10.34 PM.png" alt="Screen Shot 2021-11-14 at 5.10.34 PM" style="zoom:50%;" />

This is the current protocol

Figure 2:



<img src="./img/packet.png" alt="dds_packet" style="zoom:50%;" />

Please set:

- Src = 4
- Des = 0 
- Message_Type = 1
- Data_Type = (Please refer the Data_Type in Table 1)
- Priority_Type = 3
- Physical_Time = Unix Time of data send from MCVT (for example, 1636928132 for Sun Nov 14 2021 22:15:32 GMT+0000)
- Simulink_Time = Simulink time of data send from MCVT
- [Row, Col, Length] (Please refer the Data Type in Table 1)
- Opt = 0
- Flag = 0
- Param = ID of data will be sent (Please refer the Data_ID in Table 1)
- Subparam = 0
- Data = One row of sending data in C_Double



