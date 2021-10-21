Header Info
•	Date Created: 7/28/2021
•	Date Last Modified: 8/29/2021
•	Developers: Jaewon Park, CJ Pan
•	Version Number: 1.4v
•	Funding Acknowledgement: Space Technology Research Institutes Grant #80NSSC19K1076 from NASA’s Space Technology Research Grants Program.


I.	Functional Requirement
	Purpose of this model is to simulate a life support system which monitors and regulate temperature and pressure of the interior environment. 
	A simple heat pump cycle with four basic components is implemented for Active Thermal Control System for cooling. 
	A control valve model with arbitrary valve coefficient and dimension coupled pressurized storage tank is implemented for Interior Pressure Control system.


II.	Introduction
	ECLSS is responsible for maintaining the well-being of the crew members in an extraterrestrial habitat environment. 
	Composed of an active thermal control system (ATCS) and an interior pressure control system (IPCS), ECLSS supports the interior habitat system so that its 
	temperature and pressure values remain within a preferable range for the human crew members. Interaction between ECLSS and the interior habitat system takes 
	place with the help of P&ID controller, which adjusts cooling and heating loads for temperature control and regulates supply and relief air flow for pressure control. 
	While in effect, ECLSS consumes energy from the power generation system to operate physical components such as pumps and valves. Even though ECLSS does not directly 
	interact with the structural system and exterior environment system, these systems indirectly influence the behavior of ECLSS through driving temperature and pressure 
	changes in the interior habitat system. 

	In terms of modeling of the physical systems, a simple heat pump cycle with four basic components is implemented for ATCS for cooling. Heat is removed from the 
	interior air, circulated through the heat pump, and ejected to the external environment by radiation. Heating is handled by a simple electric heater. As for IPCS, 
	a control valve model with arbitrary valve coefficient and dimension is implemented. Coupled with the interior habitat system and air storage tank, valve opening 
	determines the amount of air supplied to the habitat. A relief valve with similar characteristics is implemented to illustrate the pressure removal process. To 
	study performance degradation due to damaged components, two types of damage on a radiator panel are considered for ATCS. Thermal paint degradation and dust accumulation 
	on the surface of the panels due to external impacts are modeled. The severity of performance degradation is modeled by changing the material characteristics such as 
	emissivity, absorptivity, and dust layer thickness.


III.	Inputs
	Active Thermal Control System (ATCS)
		
		Exterior Environment
			Solar radiation: amount of solar radiation, data type: float, unit: W/m^2, 1-D
			Dust deposition rate: rate of dust deposition rate caused by meteorite or rocket, data type: float, unit: g/cm^2/s, 1-D
			Impact: thermal scenario number, data type: float, unit: none, 1-D
		
		Power System 
			Available Power: limited power supply, data type: float, unit: kW, 1-D
		
		Habitat interior environment
			Indoor temperature: indoor temperature of habitat environment, data type: float, unit: C, 1-D
			Air flow: air flow through the evaporator, data type: float, unit m^3/s, 1-D 
	
		Health Management System
			Dust repair: agent activity for dust repair, data type: float, unit: none, 1-D
			Paint repair: agent activity for paint repair, data type: float, unit: none, 1-D

	Interior Pressure Control System (IPCS)
	
		Habitat Interior Environment
			Indoor pressure: indoor pressure of habitat environment, data type: float, unit: Pa, 1-D


IV.	Outputs
	Active Thermal Control System (ATCS)
	
		Power System 
			Power request: power requested by ATCS for next iteration, data type: float, unit: kW, 1-D
			Power consumption: amount of power consumed by ATCS for the current iteration, data type: float, unit: kW, 1-D
		
		Habitat interior environment
			Air flow: air flow of evaporator, data type: float, unit: m^3/s, 1-D
			Evaporator temperature: temperature of air coming out of evaporator, data type: float, unit: C, 1-D
	
		Health Management System
			Paint health state: health state of radiator panels due to paint damage, data type: float, unit: none, 1-D
			Dust health state: health state of radiator panels due to dust damage, data type: float, unit: none, 1-D

	Interior Pressure Control System (IPCS)
	
		Power System
			Power consumption: amount of power consumed by IPCS for the current iteration, data type: float, unit: kW, 1-D
	
		Habitat Interior Environment
			Air venting: air released from interior environment by relief valve, data type: float, unit: kg/s, 1-D
			Air supply: air supplied to interior environment, data type: float, unit: kg/s, 1-D


V.	Simulink Model Block Organization
	Active Thermal Control System (ATCS)
		Active_Thermal_Control_System: solves states in heat pump cycle. Radiator panel states are also solved here. Newton’s method was used to iteratively solve for the states. 
		
		On_and_off_dynamics_enforcer: creates on/off dynamics of the heat pump when the pressure of evaporator is greater than the pressure of condenser. (still in progress)
		
		EV_control: controls valve opening ratio for expansion valve  
		
		Set_temperature_change: adjust setpoint temperature when the power demand is higher than what is supplied.
		
		Heater_capacity: compares supplied power to the capacity of electric heater and outputs appropriate heating power. 
		
		Tempadjust: assumes NAN inputs from interior environment to be the same as setpoint temperature. (to be removed when the error is fixed from interior environment system)
		
		Faulty Panels: subsystem which contains damageability features. 
		
			Dust_fix_with_agent: updates health states and physical states for the radiator panels with dust damage depending on the communication done with agents. 
					Also creates dust damage from natural dust deposition excluding meteorite impact. 
		
			Paint_fix_with_agent: updates health states and physical states for the radiator panels with paint damage. 
			
			Damage_factory_dust: randomly assigns which subsection of radiator panel is going to be damaged by dust deposition. Only triggered when there is a meteorite impact. 
		
			Damage_factory_paint: randomly assigns which subsection of radiator panel is going to be damaged by paint degradation. Only triggered when there is a meteorite impact. 
		
			Paint_damage: overwrites health states and physical parameters for paint-degraded panels, then prepares the data to be sent to dust_impact.
		
			Dust_impact: combines parameters from dust and paint damages. Passes the data to Active_Thermal_Control_System. 

	Interior Pressure Control System (IPCS)
			
		Air_storage_tank: models the pressure dynamics of air storage tank
	
		Flow_restrictor: solves for flow of supplied air depending on the pressure gradient between storage tank and interior environment
	
		Power_consumption: calculates power consumed by the control vales depending on valve opening ratio 
	
		Relief_valve_control: calculates for flow of released air from the interior environment


VI.	Steps to Run
	No special requirements yet. Just run “MCVT_Run_Scenarios.m”. In the future, there will be options to choose different sets of components for heat pump. (Todo)


VII.	Bug Reporting
	In the beginning of simulation, temperature data from interior environment system shows NAN values. This is taken care of temporarily from ECLSS side. This is needs to be fixed from the interior environment system. 
	Currently, safety mechanism has been applied for the damageability for the radiator panels. If the radiator panels (subsections of radiator panels) are damaged for more than 25 subsections, the model will crash 
	due to exceptionally high pressure. This can be solved by turning off the heat pump when the pressure is too high. Update is under progress.

