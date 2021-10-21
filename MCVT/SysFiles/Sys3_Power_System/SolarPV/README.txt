Header Info
	1) Date Created: 8/2/2021
	2) Date Last Modified: 8/11/2021
	3) Developers: Kairui Hao
	4) Version Number: MCVT_v 1.4
	5) Funding Acknowledgement: Space Technology Research
	   Institutes Grant #80NSSC19K1076 from NASA's Space
	   Technology Research Grants Program.

Functional Requirement
	Solar PV model is supposed to characterize solar PV array
        power generation capacities in variations of solar irradiance 
        and ambient temperature. 

Introduction
	This Solar PV model package includes the following files for solar PV,
		a) Triple_Junction_PVcell_test.m.
			""" Electrical, thermal , and optical models of triple junction solar PV cell Ga51In49P/GaAs/Ge """

			Base: handle

			Public properties:
				timestep (float): simulation time step.
				sigma (float): Stefan-Boltzman constant.
			
			Public methods:
				[P_mppmodule, T, DRatio] = solve_Triple_ElecTher_module(Tamb, Tsky, Tground, G_in, T_ini, DRatio, dustrate, cleanrate)

					""" Combined electric and thermal model for a PV module """
					
					Inputs:
						1) Tamb (float): ambient temperature (K). shape: (1)
						2) Tsky (float): sky temperature (K). shape: (1)
						3) Tground (float): ground temperature (K). shape: (1)
						4) G_in (float): solar irradiance to the glass surface (W/m^2). shape: (1)
						5) P_module(float): PV module power (W). shape: (1)
						6) T_ini (float): solar PV module initial temperature (K). shape: (1, 5)
						7) DRatio (float): dust accumulation ratio [0, 1]. shape: (1)
						8) dustrate (float): dust accumulation rate (1/s) [0, 1]. shape: (1)
						9) cleanrate (float): dust cleaning rate (1/s) [0, 1]. shape: (1)

					Outputs:
						1) P_mppmodule (float): single solar PV module power generation (W). shape: (1)
						2) T (float): solar PV module temperatures of five layers (K).  shape: (1, 5)
						3) DRatio (float): dust cover ratio [0, 1]. shape: (1)

				[P_mppmodule] = solve_Triplemodule_MPP_fzero(G_in, T)

					"""  Compute a single PV module power generation """	
		
					Inputs: 
						1) G_in (float): solar irradiance to the glass surface (W/m^2). shape: (1)
						2) T (float): solar PV cell temperature (K).  shape: (1)

					Outputs:
						1) P_mppmodule(float): solar PV module power generation (W). shape: (1)
			
		b) SolarPV.m.
			""" A wrapper of Triple_Junction_PVcell_test.m """			

			Base: Triple_Junction_PVcell_test & matlab.System &  matlab.system.mixin.Propagates

			Public properties:
				PVcapacity (float/nan): Solar PV array power generation capcity [kW]. shape: (1)
				Tmodule_ini (float): Initial PV module five layer temperatures [K]. shape: (1, 5)
				P_ini (float): Initial single PV module power generation [kW]. shape: (1)
				DRatio_ini (float): Initial dust cover ratio [0, 1]. shape: (1)
				Module_number (nan/int): The number of PV modules. Default value: nan.

			Public methods:

				[Pout, DRout] = step(G_in, dustrate, cleanrate, Tamb, Tsky, Tground)

					""" Update system outputs and states """
					
					Inputs:
						1) G_in (float): solar irradiance to the glass surface (W/m^2). shape: (1)
						2) dustrate (float): dust accumulation rate (1/s) [0, 1]. shape: (1)
						3) cleanrate (float): dust cleaning rate (1/s) [0, 1]. shape: (1)
						4) Tamb (float): ambient temperature (K). shape: (1)
						5) Tsky (float): sky temperature (K). shape: (1)
						6) Tground (float): ground temperature (K). shape: (1)

					Outputs:
						1) Pout (float): solar power generation (kW). shape: (1)
						2) DRout (float): Dust cover ratio. shape: (1)

	

		The base object 'Triple_Junction_PVcell_test.m' includes detailed solar 
		PV electrical, thermal, and optical models to characterize the power 
		generation as a function of solar irradiance and ambient temperature. 
		The system object 'SolarPV.m' is a wrapper of 'Triple_Junction_PVcell_test.m'.
		

	for simulated solar PV dust FDD,

		a) Solar_simu_FDD.m
			""" Simulated solar PV dust FDD. """

			Base: matlab.System & matlab.system.mixin.Propagates
			
			Public properties:
				timestep (float): simulation time step.
				K (float): Feedback gain.
				noise (float): Additive noise.
			
			Public methods:

				[xe, P_request] = step(xtrue, EnableReset, P_supply)

					""" Update system outputs and states. """

					Inputs: 
						1) xtrue (float): true health state variables [0, 1]. shape: (1)
						2) EnableReset (boolean): reset the simulated FDD. true: reset.
						3) P_supply (float): power supply to the simulated FDD (kW). shape: (1)

					Outputs:
						1) xe (float): simulated pmf of the health state variables. shape:(4, 1)
						2) P_request (float): simulated FDD power consumption (kW). shape: (1) 

		b) Solar_simu_FDD_pp.m
			""" Precompute simulated FDD feedback gain. """

			Inputs: 
				1) Ts (float): settling time of the simulated solar PV dust FDD. shape: (1).
				2) zita (float): damping ratio. shape: (1).

			Outputs:
				1) K (float): feedback gain.

		c) FDDdust.m (to be removed).	

		The system object 'Solar_simu_FDD.m' includes the simulated solar PV 
		dust FDD model.  'Solar_simu_FDD_pp.m' pre-computes the feedback gain 
		of the simulated solar PV dust FDD model. 'FDDdust.m' is the previous 
		version and will be removed in the future.


Simulink Model Block Organization
	The solar PV model script is contained in a single matlab system object block.

Steps to Run
	1) Set values of the public properties of SolarPV class.
		There are two ways to instantiate an instance of SolarPV class.
			a) set a desired PV array power generation value to solar.PVcapacity, and set nan to solar.Module_number.
		                      The program will internally compute scaling number that scales up the single PV module power output to the desired PV array power generation value.
			b) set a desired PV module number to solar.Module_number, and set nan to solar.PV capacity.
			    In this case, the PV array power generation value is computed by multiplying the single PV module power output by solar.Module_number.	

	2) Call Solar_simu_FDD_pp to pre-compute the desired feedback gain of the simulated FDD, and set values of the public  propeties of Solar_simu_FDD class. 
	2) Give input profiles of G_in, dustrate,  cleanrate, Tamb, Tsky, and Tgound.
	3) Run the simulation.

Bug Reporting
		
		
	
	

			