%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                MCVT v1.5 Saving and Plotting Data File                       
%                        Date: 9/7/2021                                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MCVT - version 1.5: Integrated Simulation
% MCVT Systems: 
% Structural, Power, ECLSS, Interior Env., Exterior Env., Agent & HMS

tic
%% Move System Simulation Outputs to MCVT Output Folder

movefile('Sys2_out.mat',Output_Folder);                 % System 2: Structural System
movefile('Sys3_out.mat',Output_Folder);                 % System 3: Power System
movefile('Sys5_out.mat',Output_Folder);                 % System 5: ECLSS
movefile('Sys6_out.mat',Output_Folder);                 % System 6: Agent & HMS
movefile('Sys8_out.mat',Output_Folder);                 % System 8: Interior Environment
movefile('Sys9_out.mat',Output_Folder);                 % System 9: Exterior Environment

%% Clear all simulation variables except the system simulation output folder

clearvars -except Output_Folder  
load([pwd '/' Output_Folder '/Sys2_out'])
load([pwd '/' Output_Folder '/Sys3_out'])
load([pwd '/' Output_Folder '/Sys5_out'])
load([pwd '/' Output_Folder '/Sys6_out'])
load([pwd '/' Output_Folder '/Sys8_out'])
load([pwd '/' Output_Folder '/Sys9_out'])

%% Plot MCVT Simulation Outputs
% NOTE: The data structure table for the MCVT simulation is provided in the manual
% In this script, we provide an example for plotting simulation outputs per
% system.

%% System 9: Exterior Environment

% Figure: Dust accumulation rate, damage case impact indicator, and ground acceleration
figure
subplot(3,1,1)
plot(sys9_out.DustAccu); ylabel('[mg/cm^2/s]'); title('Dust Accumulation Rate'); grid on;
subplot(3,1,2)
plot(sys9_out.dmg_caseo); ylabel('[-]'); title('Impact Indicator'); grid on;
subplot(3,1,3)
plot(sys9_out.GroundAcc_xyz); ylabel('[m/s^2]'); title('Ground Motion'); grid on;

% Figure: Solar flux for ECLSS and the power system, and the spatial solar flux for the structural system
figure
subplot(2,1,1)
plot(sys9_out.SolarFlux); ylabel('[W/m^2]'); title('Solar Flux - ECLSS & Power System'); grid on;
subplot(2,1,2)
plot(sys9_out.SolarFluxSpatial); ylabel('[W/m^2]'); title('Spatial Solar Flux - Structural System'); grid on;

%% System 2: Structural System

% Figure: Total damage, impact location probability, and damage detection probability
figure
subplot(3,1,1)
plot(sys2_out.Sys2_PhyO.Sys2_Total_Damage_to_Sys6); ylabel('Damage Factor [-]'); title('Total Damage Index'); grid on;
subplot(3,1,2)
plot(sys2_out.Sys2_CyberO.Sys2_out_DamageProbabilities.Sys2_Out_Impact_Location_Probabiilities); ylabel('Probability'); title('Impact Location Detection Results'); grid on; ylim([0,1.1]); 
legend('Dome Area 1','Dome Area 2','Dome Area 3','Dome Area 4','Dome Area 5');
subplot(3,1,3)
plot(sys2_out.Sys2_CyberO.Sys2_out_DamageProbabilities.Sys2_Out_Damage_Detection_Probabilities.Time, sys2_out.Sys2_CyberO.Sys2_out_DamageProbabilities.Sys2_Out_Damage_Detection_Probabilities.Data(:,[1,3,5,7,9])); ylabel('Probability'); title('Impact Damage Detection Results'); grid on; ylim([0,1.1]); 
legend('Dome Area 1','Dome Area 2','Dome Area 3','Dome Area 4','Dome Area 5');

% Figure: Outer wall and inner wall surface thermal boundaries
figure
subplot(2,1,1)
plot(sys2_out.Sys2_PhyO.Sys2_out_ExteriorWallSurfTemp); ylabel('Temperature [K]'); title('Outer Wall Surface Thermal Boundary'); grid on;
subplot(2,1,2)
plot(sys2_out.Sys2_PhyO.Sys2_out_InteriorWallSurfTemp); ylabel('Temperature [K]'); title('Inner Wall Surface Thermal Boundary'); grid on; %ylim([293.1,293.2]);

%% System 8: Interior Environment

% Figure: Interior wall temperature and pressure
figure
subplot(2,1,1)
plot(sys8_out.Sys8_PhyO.Sys8_Out_TempWall); ylabel(' Temperature [K]'); title('Interior Wall Temperature'); grid on; %ylim([295,297]);
subplot(2,1,2)
plot(sys8_out.Sys8_PhyO.Sys8_Out_PressureWall); ylabel('Pressure [Pa]'); title('Interior Wall Pressure'); grid on; 

% Figure: Interior environment temperature and pressure sensor measurement
figure
subplot(2,1,1)
plot(sys8_out.Sys8_CyberO.Sys8_Out_PSTemp + 273.15); title('Interior Environment Temperature Measurement'); ylabel('Temperature [K]'); grid on; %ylim([297,299]);
subplot(2,1,2)
plot(sys8_out.Sys8_CyberO.Sys8_Out_PCPressure); title('Interior Environment Pressure Measurement'); ylabel('Pressure [Pa]'); grid on; 

%% System 5: ECLSS

% Figure: ECLSS air supply and air ventilation
figure
subplot(2,1,1)
plot(sys5_out.Sys5_PhyO.Sys5_Air_Supply); title('ECLSS Air Supply'); ylabel('[kg/s]'); grid on;
subplot(2,1,2)
plot(sys5_out.Sys5_PhyO.Sys5_Air_Vent); title('ECLSS Air Ventilation'); ylabel('[m^3/s]'); grid on;

% Figure: ECLSS heating energy and cooling air temperature
figure
subplot(2,1,1)
plot(sys5_out.Sys5_PhyO.Sys5_Out_HeatingEnergy); title('ECLSS Heating Energy'); ylabel('Energy [kW]'); grid on; %ylim([0,22]);
subplot(2,1,2)
plot(sys5_out.Sys5_PhyO.Sys5_Out_Temp + 273.15); title('ECLSS Cooling Air Temperature'); ylabel('Temperature [K]'); grid on; 

%% System 3: Power System

% Figure: Power supply to the structural system, ECLSS, and the interior environment, and total power generated
figure
subplot(4,1,1)
plot(sys3_out.Sys3_PhyO.Sys3_Out_Power_Supply_to_Sys2_kW_); ylabel('[kW]'); title('Power Supply to the Structural System'); grid on; %ylim([0,5e-3]);
subplot(4,1,2)
plot(sys3_out.Sys3_PhyO.Sys3_Out_Power_Supply_to_Sys5_kW_); ylabel('[kW]'); title('Power Supply to ECLSS'); grid on;
subplot(4,1,3)
plot(sys3_out.Sys3_PhyO.Sys3_Out_Power_Supply_to_Sys8_kW_); ylabel('[kW]'); title('Power Supply to the Interior Environment'); grid on;
subplot(4,1,4)
plot(sys3_out.Sys3_PhyO.Sys3_Out_Total_Power_Generated_kW_); ylabel('[kW]'); title('Total Power Generated'); legend('Solar','Nuclear'); grid on;

% Figure: Power storage, power solar FDD, and power nuclear FDD
figure
subplot(3,1,1)
plot(sys3_out.Sys3_CyberO.Sys3_Out_PowerStorage); ylabel('Power [kWh]'); title('Power Storage Status'); grid on; 
subplot(3,1,2)
plot(sys3_out.Sys3_CyberO.Sys3_Out_PowerSystemDamageInformation.SolarPV_FDD); ylabel('Index [-]'); title('Solar PV FDD'); grid on; %ylim([0,2.2]);
subplot(3,1,3)
plot(sys3_out.Sys3_CyberO.Sys3_Out_PowerSystemDamageInformation.Nuclear_Dust_FDD); ylabel('Index'); title('Nuclear FDD'); grid on; %ylim([0,2.2]);

%% System 6: Agent and HMS Model

% Figure: Agent repair status - nuclear, solar, structural
figure
subplot(3,1,1)
plot(sys6_out.Sys6_PhyO.AgentComms.Repair_Comms_NPG); title('Nuclear Radiator Clean'); grid on; ylabel('Indicator [-]'); ylim([0,1]);
subplot(3,1,2)
plot(sys6_out.Sys6_PhyO.AgentComms.Repair_Comms_SPG); title('Solar Panel Clean'); grid on; ylabel('Indicator [-]'); ylim([0,1]);
subplot(3,1,3)
plot(sys6_out.Sys6_PhyO.AgentComms.Repair_Comms_Structure); title('Structural System Repair'); grid on; ylabel('Indicator [-]'); ylim([0,1]);

% Figure: Agent memory state, and action ID
figure
subplot(2,1,1)
plot(sys6_out.Sys6_CyberO.Agent_States.Agent_Memory_States.Filled_Memory_Slots); title('Command Memory State'); grid on; ylabel('Indicator [-]');
subplot(2,1,2)
plot(sys6_out.Sys6_CyberO.Agent_States.Agent_Program_Info.cActionID); title('Agent Action ID'); grid on; ylabel('Indicator [-]');

elapsedTime(5) = toc;
