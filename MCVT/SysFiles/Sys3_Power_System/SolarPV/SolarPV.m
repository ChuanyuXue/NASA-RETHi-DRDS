classdef SolarPV < matlab.System & matlab.system.mixin.Propagates& Triple_Junction_PVcell_test 
    
    % Solar PV array simulink system object
    % Bases: matlab.System, matlab.system.mixin.Propagates, Triple_Junction_PVcell_test 
    % Purpose: A wrapper of Triple_Junction_PVcell_test.m.    
    %          Simulate and estimate solar PV array power generation(kW) as 
    %          a function of solar irradiance and dust cover ratio. The
    %          total solar PV array power generation is computated by
    %          scaling up a single solar PV module power generation.    

    % Date Created: 8 August 2020
    % Date Last Modified: 1 September 2021
    % Modeler Name: Kairui Hao (Purdue)
    % Funding Acknowledgement: Space Technology Research Institutes Grant 
    %                          80NSSC19K1076 from NASA's Space Technology 
    %                          Research Grants Program.
    % Version Number: MCVT v5     
    
    
    properties
        PVcapacity            % Initialize solar PV array power generation capacity [kW]          
        Tmodule_ini           % Initial PV module temperature [K]
        P_ini                 % Initial single solar PV module power generation [kW]
        DRatio_ini            % Initial Dust cover ratio [0, 1] 
        Module_number         % The number of PV modules
    end
    
    properties(Access = private)
        Tglass                  % Solar PV module glass temperature [K]
        TEVAupper               % Solar PV module upper EVA layer temperature [K]
        Tcell                   % Solar PV cell temperature [K]
        TEVAlower               % Solar PV module lower EVA layer temperature [K]
        Tbacksheet              % Solar PV module back sheet temperature [K]        
        Pmodulenominal          % Nominal single solar PV module power generation capacity [W]
        Tmodule                 % Solar PV module temperature [K]
        P                       % Single solar PV module power generation [W]
        scale_number            % Solar PV array power generation capcaity scaling number
    end
    
    properties(Constant,Access = private)
        kW2W = 1000             % kW -> W.
        dust_mg2p = 1/406;      % dust unit converstion mg/(cm^2*s) -> %/s
    end
    
    methods(Access = protected)
        %% Initialize simulink system object block 
        function setupImpl(obj)
            % Purpose: initialize state variables.                    
            
            % Initialize the superclass.
            Triple_Junction_PVcell_test(); 
            
            % Compute nominal single solar PV module power generation 
            % capacity[W] based on the nominal solar irradiance Gn and the 
            % the nominal solar PV cell temperature Tn.
            [obj.Pmodulenominal] = solve_Triplemodule_MPP_fzero(obj,obj.Gn,obj.Tn);
            
            % Initialize PV module five layer temperatures. shape (1, 5)
            obj.Tmodule = obj.Tmodule_ini;
            
            % Initialize PV module power generation. [kW] -> [W]
            obj.P = obj.P_ini * obj.kW2W;
            
            % Initialize dust cover ratio
            obj.DRatio = obj.DRatio_ini;
            
            
            % If Module_number is not provided by users (nan), compute PV module number.
            if isnan(obj.Module_number)
                obj.scale_number  = obj.PVcapacity * obj.kW2W / obj.Pmodulenominal; 
            else
                obj.scale_number = obj.Module_number;
            end
            
        end
        
        %% system output and state update equations            
        function [Pout,DRout] = stepImpl(obj,G_in,dustrate,cleanrate, Tamb, Tsky, Tground)
            % Purpose: update system state variables and outputs. Assume
            %          constant Tamb, Tsky, and Tground for the current
            %          version.
            
            % Inputs:  1) G_in  (float): solor irradiance (w/m^2).
            %          2) dustrate (float; range:[0, 1]): dust accumulation rate (1/sec).
            %          3) cleanrate (float; range:[0, 1]): dust cleaning rate (1/sec).
            %          4) Tamb (float; 4): Ambient temperature [K].
            %          5) Tsky (float; 4): Sky temperature [K].
            %          6) Tground (float; 373): Ground temperature [K].
            % Outputs: 1) Pout (float): solar power generation (kW).
            %          2) DRout (float; range: [0, 1]): Dust cover ratio.
            
            % dust unit converstion mg/(cm^2*s) -> %/s
            dustrate = dustrate * obj.dust_mg2p;
            cleanrate = cleanrate * obj.dust_mg2p;
            
            % Update single solar PV module power, solar PV module five
            % layer temperatures, and dust cover ratio.
            [obj.P,obj.Tmodule,obj.DRatio] = solve_Triple_ElecTher_module(obj,Tamb,Tsky,Tground,G_in ,obj.Tmodule,obj.DRatio,dustrate,cleanrate);
            
            % Scale up to get the solar PV array power; convert unit from W
            % to kW
            Pout = obj.P*obj.scale_number  /obj.kW2W ; % [W] -> [kW]
            
            % Solar PV module dust cover ratio
            DRout = obj.DRatio;
            
            % Solar PV module temperature (not outputs for the current version.)
            %Tout = obj.Tmodule;
        end
      
       
        function num = getNumInputsImpl(~)
            num = 6;
        end      
        
            
        function num = getNumOutputsImpl(~)
            num = 2;
        end
        
        function[o1,o2] = getOutputSizeImpl(~)
            o1=1;
            o2=1;
            
        end
         
        function [o1,o2] = getOutputDataTypeImpl(~)
            o1='double';
            o2='double';
            
        end
         
        function [o1,o2] = isOutputFixedSizeImpl(~)
            o1=true;
            o2=true;           
        end
         
        function [o1,o2] = isOutputComplexImpl(~)
            o1=false;
            o2=false;
          
        end               
    end
end
