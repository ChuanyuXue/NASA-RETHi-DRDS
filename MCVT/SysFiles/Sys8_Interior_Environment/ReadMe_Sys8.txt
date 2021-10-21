MCVT Integrated Model
Subsystem 8 - Habitat Interior Environment Model

Date Created: 3 June 2021
Date Last Modified: 7 September 2021
Modeler Name: Jeffrey Steiner (UConn)
Funding Acknowledgement: Funded by the NASA RETHi Project (Grant #80NSSC19K1076)
Version Number: MCVT v4



	I. FUNCTIONAL REQUIREMENTS
		
The Habitat Interior Environment Model (HIEM) was developed to model changes of the state of the air (atmosphere) within the interior of a deep-space habitat. The state of the air at this time includes values for temperature, pressure, and air mass density that are
all subject to change based on interaction with other subsystems over time.

For example, regarding temperature input, the model interacts with the Structural Thermal Model and the Thermal Management Model. Using input from those two models, the change in temperature of the air is calculated, and this temperature is then output back to the Structural Thermal Model and Thermal Management Model to act as a boundary condition and input. The temperature influences, and is influenced by, any pressure and corresponding density gradients that develop within the air space. In addition, the HIEM provides information to the Humans Model, Environmental Control and Life Support System (ECLSS) Model and Command & Control. Future iterations of the model are expected to introduce other state variables such as partial pressure of gases such as Oxygen or Nitrogen.

	II. INTRODUCTION

The Habitat Interior Environment Model (HIEM) utilizes a physics-based approach to provide data in real-time simulation on the air temperature and air pressure, as well as rates
of change for those variables, within the space habitat interior space. A finite-volume based zonal model approach has been developed to predict the pressure, temperature and
air mass flow at different points within the habitat space. In the model, the air within the habitat dome was divided into a number of rectangular prismatic cells, inside of which
mass and energy conservation equations, in conjunction with the ideal gas law, were satisfied. A Simulink model utilizing these physics-based approaches was developed to provide
location-specific data for the interior air, including changes due to point-source thermal input, such as pressure and temperature change due to a heater, as well as widespread input
such as that of the heat conduction through the outer wall of the habitat. Within Simulink, the air pressure model satisfies mass conservation with iteration of pressure. The air temperature model satisfies energy conservation with iteration of temperature. Two models have been developed, with one additional model currently in development: the temperature
alone, pressure alone and coupled temperature-pressure models, respectively. A coupled model is currently being developed that solves for air pressure and temperature simultaneously within one system, while allowing all variables to affect each other and change with time. Two-dimensional, as well as three-dimensional, models have been developed for
each case. The model has been tested for damageability and repairability using predetermined damage cases corresponding to increasing severity of damage due to micrometeorite
impact. This testing is crucial to understanding how the habitat, and associated repair or maintenance systems, can be expected to perform during damage scenarios. The HIEM
plays a vital role in the deep space habitat and interacts with many other subsystems/systems in the habitat, including pressure control, temperature management, environmental
control and life support systems (ECLSS), and structural thermal model.
	
	III. INPUTS

a) Pressure Model
	PrevAirPressure: Double: previous pressure values from memory, 112x1 (Pa)

	Time: Double: Constant pertaining to simulation time used for logical
	determinations and application of initial conditions

	IPCS_Supply: Double: Constant supplied by ECLSS that represents mass
	flow of air being added to the system by the Pressure Control(kg/s)

	IPCS_Discharge: Double: Constant supplied by ECLSS that represents mass
	flow of air being removed from the system by the Pressure Control(kg/s)

	IEN_ADJ_HIEM: Double: 112x7 matrix with columns detailing the zone 
	number for the North, South, East, West, Top, and Bottom faces of each
	zone, with row 1 being the number of the zone of interest

	Damage: Double: number of damaged nodes as given by the SMM

	HIEMDamageElements: Double: Vector of zone numbers corrseponding to
	potentially damaged nodes according to mapping from the SMM

	temp0: Double: User-Defined initial temperature, constant (K)

	pres0: Double: User-Defined initial pressure, constant (K)

	interior_leak_rate: Double: User defined leak rate

b) Temperature Model
	
	PCell0: Double: Pressure Distribution, Pa

	HIEMDamageElements: Double: Vector of zone numbers corrseponding to
	potentially damaged nodes according to mapping from the SMM

	RefTemp: Double: User-Defined Reference Temperature for the Exterior
	Environment in case of leak scenario (K)

	pres0: Double: User-Defined initial pressure, constant (Pa)

	temp0: Double: User-Defined initial temperature, constant (K)

	Damage: Double: number of damaged nodes as given by the SMM

	HCAirFlow: Double: Constant supplied by ECLSS that represents mass
	flow of air being added to the system from the temperature control(kg/s)

	WallTemp: Double: Mapped interior wall surface temperature from STM,
	64x1 (K)

	ThermalManHeatingInp: Double: Constant Total Heating Energy Input 
	from ECLSS Thermal Management (J) 

	ThermalManHeatingInpLoc: Double: Zone number corresponding to heating
	input location for ECLSS Thermal Management

	ThermalManCoolingInp: Double: Constant Cooling Temperature Setpoint
	Input from ECLSS Thermal Management (K) 

	ThermalManCoolingInpLoc: Double: Zone number corresponding to cooling
	input location for ECLSS Thermal Management

	Time: Double: Constant pertaining to simulation time used for logical
	determinations and application of initial conditions

	dt: Double: constant representing the time step used for the model (s)

	IEN_ADJ_HIEM: Double: 112x7 matrix with columns detailing the zone 
	number for the North, South, East, West, Top, and Bottom faces of each
	zone, with row 1 being the number of the zone of interest

	HumanHeat: Double: Constant Total Heating Energy Input from Human 
	Agent Model (J) 

	HumanElement: Double: Zone number corresponding to heating input
	location for Human Agent Model

	air_specific_heat: Double: Specific Heat of Air, J/kg-K

	habitat_volume: Double: User-defined habitat volume, m^3

	IV. OUTPUTS

a) Pressure Model

	AirPressure: Double: 112x1 matrix representing the Air Pressure in
	each corresponding zone (Pa)

	IPCSAirflow: Double: Constant representing discharge mass flow to the
	ECLSS for purposes of air circulation (kg/s)

b) Temperature Model

	AirTemp: Double: 112x1 matrix representing the Air Temperature in
	each corresponding zone (K)

	AirTempWall: 20x1 matrix corresponding to the Air Temperature in
	zones in contact with the structural wall (K), sent to STM

	PSTemp: Double: Constant Zonal Temperature corresponding to zone in
	which ECLSS Cooling input is provided (K), provided to ECLSS Thermal
	Management

	TMSAirflow: Double: Constant representing discharge mass flow to the
	ECLSS Thermal Management for purposes of air circulation (kg/s)

	V. MODEL BLOCK ORGANIZATION

Within the MCVT Integrated Simulink model, Subsystem 8 is in a self-contained block. Within this subsystem block, there are two major matlab function blocks: "AirPressureDistribution" and "AirTemperatureDistribution". These are two major scripts that perform calculations for the Pressure Model and Temperature Model, respectively.

In addition to the two main matlab function blocks, there are various other minor matlab function and subsystem blocks contained within Subsystem 8. These remaining models and their respective functions are as follows:

Adjacent Element Data: 

	This function serves to provide a matrix that details the interactions between the finite zones of the HIEM. The matrix is 7 rows x n columns, where "n" is the number of finite zones. The first row corresponds to the number of the zone of interest. The remaining rows provide the zone number of the finite zone that is in contact with the zone of interest's East, West, North, South, Top, and Bottom faces, respectively.

STM2HIEM_mapping: 

	This function maps temperature values of the interior wall surface as given by the STM mesh to the nearest nodes of the HIEM mesh. This is determined by analyzing distance between the STM node in question and all nodes of the HIEM mesh, then applying the temperature as an input to the closest node.

Time_Function: 

	This function is used for logical determinations (whether or not to apply initial conditions) by analyzing the simulation time and sending a value of -1, 1, or 2 to the HIEM. (-1 = 0 sim time, 1 = dt sim time, 2 = every other sim time)

C2K(TempConversion): 

	This function block converts the Cooling input from the ECLSS from Celsius to Kelvin.

Humans2HIEM: 

	This function converts the energy input from the Human Agent model from Joules to Kelvin (corresponding to the total temperature change due to the Human Agent). It also maps this value to the HIEM mesh by comparing the current coordinate of the Human Agent and comparing to the coordinates of the HIEM nodes, similar to the other mapping functions. The calculated change in temperature is applied at this location within the HIEM Temperature Model.

K2C(tempConversionK2C): 

	This function block converts the single point output (used for calibration) to the ECLSS from Kelvin to Celsius.

Pressure Sensor Input: 

	This function is a placeholder for a future Pressure Sensor model. It currently checks Power input to the HIEM. If the Power input is 0, the sensor is considered non-functional and the output reading is NaN (Not a Number). Otherwise, if there is sufficient power, the functions ouputs the pressure value of the zone in which the sensor is place (arbitrary, can be changed to meet future needs).

HIEM2SMM_mapping: 

	This function maps pressure values adjacent to the interior wall surface as given by the HIEM mesh to the nearest nodes of the SMM mesh. This is determined by analyzing distance between the HIEM node in question and all nodes of the SMM mesh, then attaching that value to the closest node and sending the output to the SMM.

HIEM2STM_mapping: 

	This function maps temperature values adjacent to the interior wall surface as given by the HIEM mesh to the nearest nodes of the STM mesh. This is determined by analyzing distance between the HIEM node in question and all nodes of the STM mesh, then attaching that value to the closest node and sending the output to the STM.

Temperature Sensors-
	Resistance Temperature Detector (Sensors_RTD_ECLSS_InputLoc): 
		
		This subsystem block contains a series of logical checks and calculations that determines the temperature read by the RTD sensor at the location of the ECLSS input, with the sensor self-heat error included. If sufficient power is not provided, the sensor does not output a viable reading.

	Resistance Temperature Detector (Sensors_RTD_ECLSS_Zenith):

		This subsystem block contains a series of logical checks and calculations that determines the temperature read by the RTD sensor at a location near the top of the dome (currently arbitrary, can be moved to any other zone), with the sensor self-heat error included. If sufficient power is not provided, the sensor does not output a viable reading.

	Resistance Temperature Detector (Sensors_RTD_ECLSS_LeftBottom):

		This subsystem block contains a series of logical checks and calculations that determines the temperature read by the RTD sensor at a location near the bottom outer edge of the dome (currently arbitrary, can be moved to any other zone), with the sensor self-heat error included. If sufficient power is not provided, the sensor does not output a viable reading.

	Sensor Placement:

		This function block provides the HIEM element number corresponding to the sensor placements. These values have been chosen arbitrarily, and can be changed in future iterations. Note, the sensor placed by the ECLSS input should always be in the same HIEM zone as that input.

	Switch ON/OFF Control Number (multiple):

		These functions are used to assess whether power is being supplied to the sensor and provide that logical determination to the RTD sensor block.

	Sensor Input to CDCM:

		This function block packages the sensor readings into one output that is sent to the CDCM for safety control determinations.

All changes to the system can be made by modifying the scripts "MCVT_Input_File" and "MCVT_Habitat_Design_Input_File".