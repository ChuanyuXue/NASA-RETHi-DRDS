%% Documentation%% 
% Purpose: To provide the initialization of the parameters required for the 
%          Structural Mechnical Model (SMM)
%          Structural Thermal Model (STM) 
%          Meteorite Impact Model
%          FDD for System 2
% Funding Acknowledgement: Funded by the NASA RETHi Project
% Version Number: MCVT v4

% Initialize SMM
    % This code Call SMM_Initialize and put the generated data into Structures
    % Open the SMM_Structurer for detailed information
    [SMM_T0,SMM_T4_0,SMM_T1,SMM_T4_1,SMM_T2,SMM_T4_2,SMM_T3,SMM_T4]=SMM_Structurer;

% Call sensor location
    % This code reads the sensor/accelerometer location on the habitat
    SMM_Sensor_Location
    
% load impact force        
    load('MI_Initialize'); 

%load the SPL temperature values, vector, 4D (size 10*6*3*4)%    
    load('T_SPL_initialize'); 
    
%load the structural habitat temperature values, 4D (size 10*6*3*4)%    
    load('T_STM_initialize'); 

% Data for FDD    
    load('hanning_512')
    Time_duration = 5.12;
    Time_step = dt_2;
    mFRF = 512;
    noverlap = mFRF/2;
    ndelays = Time_duration/Time_step;
    trigger = 1/Time_step;
    Noise_power = 1e-11;
    Noise_level = 0.1; % Only for reference

% Damage Index SPLT - STM (based on meteorite impact location)
% Note: For intial conditions
initial_SPLT_damage_index = splt_damage_index(meteorite_impact_location_xyz);


