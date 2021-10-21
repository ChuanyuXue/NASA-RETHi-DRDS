%% Documentation
% Purpose: Initialization for ECLSS
% Date Created: 10 June 2020
% Date Last Modified: 29 Aug 2021
% Modeler Name: Jaewon Park, CJ Pan (Purdue)
% Funding Acknowledgement: Funded by the NASA RETHi Project (80NSSC19K1076)

% Version Number: MCVT v1.4

% Subsystem Connections: No connection

%%% All inputs and outputs to this function are 1 dimensional %%%
% INPUTS %
% No inputs
    
% OUTPUTS %
% No ouputs 

% Function Dependencies: uses following functions stored in the same folder
% SVR_Ts.m
% SVR_hv.m
% SVR_hl.m
% SVR_rou_v.m

% No Data Depenencies
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%% Below is for thermal model %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parameters in the Radiator loop
%
ECLSS_radiatorLoop_totalLength = 0.5;                                     % Total length of the radiator, unit: m
ECLSS_radiatorLoop_discreteNumber = 50;                                   % Discretization number (number of elements in finite volume method) of the radiator along its length
Nhp = 12;                                                                 % Number of state variables of the HP system
ECLSS_radiatorLoop_nodeLocation = linspace(0,ECLSS_radiatorLoop_totalLength,ECLSS_radiatorLoop_discreteNumber);         % Discrete node location in z-direction
ECLSS_radiatorLoop_cellLength = ECLSS_radiatorLoop_nodeLocation(2)-ECLSS_radiatorLoop_nodeLocation(1);                  % Length of each cell, unit: m 
input_discretization(1) = dt_5;                                           % Discrete time step, unit: seconds;
input_discretization(2) = ECLSS_radiatorLoop_cellLength;                  % Length of a finite volume of the radiator loop. unit: m;
input_discretization(3) = Nhp;                                            % Number of variables in the heat pump loop;
input_discretization(4) = ECLSS_radiatorLoop_discreteNumber;              % Discrete points of the HTF flow channel of the radiator loop.


%% Radiator fin properties
w_radi = 2/100;                                                         % Thickness of the radiator, unit: m
ECLSS_radiator_width = 50/100;                                          % Width of the radiator, unit: m
ECLSS_radiator_conductivity = 220;                                      % Conductivity of the radiator, unit: W/(m*K)
rour = 2707;                                                            % Density of the radiator fin, unit: kg/m^3
cpr = 896;                                                              % specific heat of the radiator fin, unit: J/(kg*K)
ECLSS_radiator_tubeRadius = 1.5/100;                                    % Radius of HTF tube passing through the radiaor, unit: m 
eta_fin = 0.95;                                                         % Radiator fin efficiency
%% HTF properties
%
ECLSS_radiatorLoop_HTFTotalMassFlowRate = 0.25;                         % Total HTF mass flow rate, unit: kg/s;
ECLSS_radiatorLoop_parallelPanelCounts = 30;                            % Number of parallel radiator panels   
ECLSS_radiatorLoop_HTFMassFlowRate = ECLSS_radiatorLoop_HTFTotalMassFlowRate / ECLSS_radiatorLoop_parallelPanelCounts;    % Mass flowrate of the HTF in single channel, unit: kg/s
rouf = 640;                                                             % Density of the HTF, unit: kg/m^3
cpf = 4600;                                                             % HTF heat capacity, unit: J/(kg*K)
ECLSS_radiatorLoop_HTFvelocity = ECLSS_radiatorLoop_HTFMassFlowRate/(pi*ECLSS_radiator_tubeRadius^2*rouf);                % HTF velocity in a single tube, unit: m/s 
hcf = 1000;                                                             % Convective heat transfer coefficient of the HTF, unit: W/(mK)
%% Compiling inputs for radiator loop
%
input_radiatorLoop(1)=ECLSS_radiatorLoop_HTFTotalMassFlowRate;          % Total HTF mass flow rate, unit: kg/s;         
input_radiatorLoop(2)=cpf;                                              % HTF heat capacity, unit: J/(kg*K)
input_radiatorLoop(3)=rouf;                                             % Density of the HTF, unit: kg/m^3
input_radiatorLoop(4)=ECLSS_radiatorLoop_HTFvelocity;                   % HTF velocity in a single tube, unit: m/s
input_radiatorLoop(5)=hcf;                                              % Convective heat transfer coefficient of the HTF, unit: W/(mK)
input_radiatorLoop(6)=ECLSS_radiator_tubeRadius;                        % Radius of HTF tube passing through the radiaor, unit: m
input_radiatorLoop(7)=w_radi;                                           % Thickness of the radiator, unit: m
input_radiatorLoop(8)=ECLSS_radiator_width;                             % Width of the radiator, unit: m
input_radiatorLoop(9)=ECLSS_radiator_conductivity;                      % Conductivity of the radiator, unit: W/(m*K)
input_radiatorLoop(10)=rour;                                            % Density of the radiator fin, unit: kg/m^3
input_radiatorLoop(11)=cpr;                                             % specific heat of the radiator fin, unit: J/(kg*K)
input_radiatorLoop(12)=eta_fin;                                         % Radiator fin efficiency
%% Parameters for the evaporator
%
ECLSS_evaporator_surfaceArea = 2.0;                                     % Total heat transfer surface area, unit: m^2;
ECLSS_evaporator_heatTransferCoeff = 2000;                              % Total heat transfer coefficient, unit: W/(m^2*K)
ECLSS_evaporator_volume = 0.20;                                         % Total volume of evaporator, unit: m^3
Ye_set = 0.1;                                                           % Liquid volume fraction of evaporator

input_Evap(1) = ECLSS_evaporator_surfaceArea;                           % Total heat transfer surface area, unit: m^2;
input_Evap(2) = ECLSS_evaporator_heatTransferCoeff;                     % Total heat transfer coefficient, unit: W/(m^2*K)
input_Evap(3) = ECLSS_evaporator_volume;                                % Total volume of evaporator, unit: m^3
%% Parameters for the condensor
%
ECLSS_condensor_surfaceArea = 2.0;                                      % Total heat transfer surface area, unit: m^2;
ECLSS_condensor_heatTransferCoeff = 2000;                               % Total heat transfer coefficient, unit: W/(m^2*K)
ECLSS_condensor_volume = 0.20;                                          % Total volume of condensor, unit: m^3 

input_Cond(1) = ECLSS_condensor_surfaceArea;                            % Total heat transfer surface area, unit: m^2;
input_Cond(2) = ECLSS_condensor_heatTransferCoeff;                      % Total heat transfer coefficient, unit: W/(m^2*K)   
input_Cond(3) = ECLSS_condensor_volume;                                 % Total volume of condensor, unit: m^3 
%% Parameters for the expansion valve
%
CEV = 0.01;                                                             % Orifice coefficient of the expansion valve
aEV = 0.05;                                                             % Adjustable valve opening parameter
input_EV(1)=CEV;                                                        % Orifice coefficient of the expansion valve
input_EV(2)=aEV;                                                        % Adjustable valve opening parameter  

%% Parameters for the compressor
%
eta_v = 0.70;                                                           % Efficiency of the compressor;
ECLSS_compressor_maximumSuctionVolume = 120*1/1000000;                  % Maximum volume during suction process, unit: m^3
                                                                        % For a typical 5KW system,VD=80cm^3;
input_CP(1) = eta_v;                                                    % Efficiency of the compressor;
input_CP(2) = ECLSS_compressor_maximumSuctionVolume;                    % Maximum volume during suction process, unit: m^3 
%% Initilization:
% X=[Ta, xEV, Pe, Xe, Pc, Xc, Thp_out, me,  mc, mCP, mEV, Thp_in] in the
% ECLSS document (See NASA Annual Report) are initialized as X0_ATC. These 
% state variables are updated at each iteraion in Simulink. 
Tset0 = ECLSS_indoor_set_temperature-273.15;                            % Inital indoor set temperature, unit: C
Pe0=1.0;                                                                % Inital evaporator pressure, unit: bar
Ye0=0.1;                                                                % Inital liquid fraction in the evaporator
Yc0=0.1;                                                                % Initial liquid fraction in the condenser
Pc0=1.5;                                                                % Initial condensor pressure, unit: bar
Tf0=SVR_Ts(Pc0);                                                        % Initial temperature in the condenser, unit: C
Te0=SVR_Ts(Pe0);                                                        % Initial temperature in the evaporator, unit: C
Tf_in0=Tf0;                                                             % HTF inlet temperature to the condenser, unit: C

rou_e0=SVR_rou_v(Pe0);                                                  % Initial evaporator density, unit: kg/s
nCP0=20;                                                                % Initial compressor motor speed, unit: Hz
mCP0=eta_v*rou_e0*nCP0*ECLSS_compressor_maximumSuctionVolume;           % Initial mass flow rate from the compressor,unit: kg/s

               
mEV0=mCP0;                                                              % Initial mass flow rate through the expansion vavle, unit: kg/s
me0=mCP0;                                                               % Initial evaporated refrigerant mass rate, unit: kg/s
mc0=mCP0;                                                               % Initial condensed refrigerant mass rate, unit: kg/s

hle0=SVR_hl(Pe0);                                                       % Initial enthalpy of saturated liquid in evaporator, unit: kJ/kg 
hve0=SVR_hv(Pe0);                                                       % Initial enthalpy of saturated vapor in evaporator, unit: kJ/kg
hlc0=SVR_hl(Pc0);                                                       % Initial enthalpy of saturated liquid in condensor, unit: kJ/kg 
xEV0=(hlc0-hle0)/(hve0-hle0);                                           % Initial vapor mass fraction at the expansion valve outlet 

X0_ATC(1)=Te0;                                                          % Initial temperature in the evaporator, unit: C
X0_ATC(2)=xEV0;                                                         % Initial vapor mass fraction at the expansion valve outlet 
X0_ATC(3)=Pe0;                                                          % Inital evaporator pressure, unit: bar
X0_ATC(4)=Ye0;                                                          % Inital liquid fraction in the evaporator
X0_ATC(5)=Pc0;                                                          % Initial condensor pressure, unit: bar
X0_ATC(6)=Yc0;                                                          % Initial liquid fraction in the condenser
X0_ATC(7)=Tf0;                                                          % Initial temperature in the condenser, unit: C
X0_ATC(8)=me0;                                                          % Initial evaporated refrigerant mass rate, unit: kg/s
X0_ATC(9)=mc0;                                                          % Initial condensed refrigerant mass rate, unit: kg/s
X0_ATC(10)=mCP0;                                                        % Initial mass flow rate from the compressor,unit: kg/s
X0_ATC(11)=mEV0;                                                        % Initial mass flow rate through the expansion vavle, unit: kg/s
X0_ATC(12)=Tf0;                                                         % Initial temperature in the condenser, unit: C
X0_ATC(Nhp+1:Nhp+ECLSS_radiatorLoop_discreteNumber)=Tf0;                % Initial temperature in radiator loop, unit: C
X0_ATC(Nhp+ECLSS_radiatorLoop_discreteNumber+1:Nhp+2*ECLSS_radiatorLoop_discreteNumber-1)=Tf0-1; % Initial temperature of radiator panels, unit: C

X0_HP=X0_ATC(1:11);                                                     % Initial conditions pertaining to heat pump cycle
%% Parameters of air properties:
%Parameters for indoor air flow
Vair_in0 = 0.15;                                                        % Air volume flow, unit: m^3/s;             

input_air(1) = air.density;                                             % Density of air, unit: kg/m^3;     
input_air(2) = air.specific_heat;                                       % Specific heat of air, unit: J/kg*K;
%%  Heater
%
ECLSS_heater_capacity = HeaterHeat_capacity;                            % unit: kW   Heating capacity of the heater
%%  Implementing faults (paint damage and dust contanimation)
% Dust parameters  
dust_parameters(1) = dust.emissivity;                                   % Emissivity of dust
dust_parameters(2) = dust.absorptivity;                                 % Absorptivity of dust
dust_parameters(3) = dust.conductivity;                                 % Conductivity of the dust,unit: W/(m*K)

% Panels with healthy surface conditions
epsilon_p0(1:ECLSS_radiatorLoop_discreteNumber) = 0.886;                % Emissivity of thermal control paint,AZ-93 on Al
alpha_p0(1:ECLSS_radiatorLoop_discreteNumber) = 0.173;                  % Absorptivity of thermal control paint, AZ-93 on Al
panel_paint0(1,:) = epsilon_p0;                                         % Emissivity of thermal control paint,AZ-93 on Al
panel_paint0(2,:) = alpha_p0;                                           % Absorptivity of thermal control paint, AZ-93 on Al

% Time it takes to clean one panel
Exp_RepairTime_ECLSS_Dust_pp = 12;
Exp_RepairTime_ECLSS_paint_pp = 12;
ECLSS_dust_damage_repair_time  = Exp_RepairTime_ECLSS_Dust_pp;           % hrs, user defined
ECLSS_paint_damage_repair_time = Exp_RepairTime_ECLSS_paint_pp;          % hrs, user defined

% Thermal Scenario Specific 
impact_numbering = [0, 4];                                              % Scenario number lower and upper bounds 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% Below is for pressure model %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initial pressure level of stored air
Ps0 = 20*1000000;                                                       % Stored air pressure, unit: MPa
ECLSS_Vst = AirStorageTank_volume;                                      % Air storage tank volume, unit: 1L=0.001 m^3

%% Indoor pressure set point for air supply
ECLSS_IPS_setpointPressure = ECLSS_pressure_set_point;                  % Set indoor pressure, unit: Pa
%% Parameters for flow restrictor
ECLSS_IPS_restrictor.permeability = 100*10^(-12);                       % Permeability of the flow restrictor, unit: m^2
ECLSS_IPS_restrictor.length = 0.05;                                     % Length of the flow restrictor, unit:m
ECLSS_IPS_restrictor.channel_number = 15000;                            % number of small channels in restrictor
ECLSS_IPS_restrictor.cross_area = 1.2972*10^(-7);                       % Flow restrictor area (cross-section), unit: m^2

%% Parameters for the relief valve
Pset=1.2*ECLSS_IPS_setpointPressure;                                    % Relief valve opening set pressure, unit: Pa
Kref=1;                                                                 % Relief valve constant, unit: m^3/(s*Pa^0.5)
d_ref=2.2*2.54/100;                                                     % Diameter of the relief valve, unit: m
Aref=pi*(d_ref/2)^2;                                                    % Vavle cross area, unit: m^2
%% Parameters of air properties
rou_air=1.177;                                                          % Density of air, unit: kg/m^3;
%% Fault input
Valve_opening_factor=1;                                                 % Valve opening factor
%% Valve power consumption
ECLSS_IPS_valve.max_power = 5;                                          % control valve power consumption when fully opened, unit: W
ECLSS_IPS_valve.min_power = 0.015;                                      % control valve power consumption when fully closed, unit: W 

%% this is for human (Obsolete)

% duration_hman = Tend;%1450*60*dt_5; %sec
duration_hman= max(T_end, 84000*dt_5);

time_human = (1:dt_5:duration_hman)';
activity_column = zeros(numel(time_human),1);
activity_column(1:300*60) = 1;
activity_column(300*60+1:600*60) = 2;
activity_column(600*60+1:615*60) = 2;
activity_column(615*60+1:645*60) = 3;
activity_column(645*60+1:675*60) = 4;
activity_column(675*60+1:690*60) = 5;
activity_column(690*60+1:705*60) = 6;
activity_column(705*60+1:720*60) = 7;
activity_column(720*60+1:735*60) = 8;
activity_column(735*60+1:1260*60) = 2;
activity_column(1260*60+1:end) = 1;

Location_id = zeros(numel(time_human),3);
Location_id(:,1) = 1;
Location_id(735*60+1:1260*60,1) = 0;
Location_id(1:18000,2) = 2.2;
Location_id(18001:600*60,2) = 1.7;
Location_id(600*60+1:615*60,2) = 1;
Location_id(615*60+1:645*60,2) = 1;
Location_id(645*60+1:675*60,2) = 1;
Location_id(675*60+1:690*60,2) = 1;
Location_id(690*60+1:705*60,2) = 1;
Location_id(705*60+1:720*60,2) = 1;
Location_id(720*60+1:735*60,2) = 1;
Location_id(735*60+1:1260*60,2) = 0;
Location_id(1260*60+1:end,2) = 2.2;

Location_id(1:18000,3) = 0;
Location_id(18001:600*60,3) = 60;
Location_id(600*60+1:615*60,3) = 240;
Location_id(615*60+1:645*60,3) = 270;
Location_id(645*60+1:675*60,3) = 270;
Location_id(675*60+1:690*60,3) = 270;
Location_id(690*60+1:705*60,3) = 300;
Location_id(705*60+1:720*60,3) = 300;
Location_id(720*60+1:735*60,3) = 300;
Location_id(735*60+1:1260*60,3) = 180;
Location_id(1260*60+1:end,3) = 0;












