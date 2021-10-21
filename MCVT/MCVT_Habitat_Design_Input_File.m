%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                MCVT v1.5 Habitat Design Input File                               
%                        Date: 9/7/2021                                  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MCVT - version 1.5: Integrated Simulation
% MCVT Systems: 
% Structural, Power, ECLSS, Interior Env., Exterior Env., Agent & HMS
% NOTE: This file should NOT be modified, ONLY IF needed.

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                INTEGRATED DESIGN PARAMETERS                           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic

%%% Lunar Environment Parameters for Habitat Design
space_temperature = 4;                          % Cosmic background space temperature [K]
ground_temperature = 373;                       % Lunar ground temperature [K]

air.density = 1.777;                            % Density of air [kg/m^3]
air.natural_convective_coefficient = 1000;      % Interior habitat air convective coefficient [W/(m.K)]
air.specific_heat = 1000;                       % Specific heat of air [J/(kg.K)]
air.viscosity = 18.37e-6;                       % Dynamic viscosity of air [Pa.sec]

dust.absorptivity = 0.76;                       % Absorptivity of lunar dust [-]
dust.conductivity = 0.0001;                     % Conductivity of lunar dust [W/(m.K)]
dust.density = 0.7;                             % Density of lunar dust [g/cm^3]
dust.emissivity = 0.93;                         % Emissivity of lunar dust [-]

%%% Habitat Design Variables
repair_temperature = 293.15;                % Initial temperature of the habitat when STM element is repaired [K]

%%% Habitat Design Constants
% Important Design Parameters
sb_sigma = 5.67e-08;                        % Stefan-Boltzmann constant [W/(m^2.K^4)]
foundation_temperature = 254.80;            % Lunar foundation temperature (boundary conditions) [K]

% Habitat Design Specs
habitat.volume = 32.725;                    % Volume of habitat interior [m^3]
habitat.inner_radius = 2.5;                 % Inner radius of the dome habitat [m]
habitat.dome_thickness = 0.4;               % Dome habitat thickness [m]
habitat.spl_thickness = 0.2;                % Structural protective layer thickness [m]

% Regolith Material Properties
regolith.emissivity = 0.97;                 % Emissivity of lunar regolith [-]
regolith.absorptivity = 0.87;               % Absorptance of lunar regolith [-]
regolith.density = 2000;                    % Density of lunar regolith [kg/m^3]
regolith.thermal_conductivity = 0.014;      % Thermal conductivity of lunar regolith [W/(m.K)]
regolith.specific_heat = 1053;              % Specific heat of lunar regolith [J/(kg.K)]

% Concrete Material Properties
concrete.emissivity = 0.85;                 % Emissivity of concrete [-]
concrete.absorptivity = 0.60;               % Absorptance of concrete [-]
concrete.density = 2400;                    % Density of concrete [kg/m^3]
concrete.thermal_conductivity = 1.000;      % Thermal conductivity of concrete [W/(m.K)]
concrete.specific_heat = 1000;              % Specific heat of concrete [J/(kg.K)]

elapsedTime(1) = toc;
disp(['-[2/6] Habitat Design Input File Loaded (' num2str(elapsedTime(1)) ' sec)']);
