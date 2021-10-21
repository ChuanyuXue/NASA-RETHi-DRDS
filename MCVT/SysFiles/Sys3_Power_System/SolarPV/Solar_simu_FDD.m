classdef Solar_simu_FDD < matlab.System & matlab.system.mixin.Propagates    
    % Simulated solar PV dust FDD simulink system object.
    % Bases: matlab.System and matlab.system.mixin.Propagates
    % Purpose: generate a pmf of a health state variable based on the true
    %          health state variable value. It emulates the functionalities
    %          of a real FDD component.
    
    % Date Created: 1 March 2021
    % Date Last Modified: 1 September 2021
    % Modeler Name: Kairui Hao (Purdue)
    % Funding Acknowledgement: Space Technology Research Institutes Grant 
    %                          80NSSC19K1076 from NASA's Space Technology 
    %                          Research Grants Program.
    % Version Number: MCVT v5   
    
    properties
        timestep        % Update time step
        K               % Feedback gain
        noise           % Additive noise            
    end
    

    properties (Access = private, Nontunable)
        CatNum = 4          % Categorical number
    end
    properties (Access = private)
         
        A               % Linear dynamical system matrix A.
        B               % Linear dynamical system matrix B.
        x               % State variables
        
        % Compute the target equilibrium point matrix as a convex
        % combination of SimMat and FDDMat. SimMat: similarity matrix,
        % FDDMat detectability matrix. 
        
        SimMat = [6 4 0 0;
                 2 6 2 0;
                 0 2 6 2;
                 0 0 4 6];
        FDDMat = [10 0 0 0;
                 1 9 1 0;
                 0 1 9 1;
                 0 0 2 8];         
        TarMat 
        alpha = 0.8        
        
        ps_p = true         % power mode at the previous time step
        P_request = 1e-4;   % simulated FDD power consumption
        xfake_inv_softmax   % FDD state variables in the inverse softmax domain
    end
    
    methods (Access = protected)
        
        %% Initialize simulink system object block        
        function setupImpl(obj)
            % Purpose: initialize state variables.
            
            % Construct controllable canonical form of A
            obj.A = zeros(2*obj.CatNum,2*obj.CatNum);
            Ablock1 = [0 1;-1,-1];
            Ablock2 = [0,0;-1,-1];
            A1 = kron(eye(obj.CatNum),Ablock1);
            A2 = kron(ones(obj.CatNum)-eye(obj.CatNum),Ablock2);
            obj.A = A1+A2;
            
            % Construct controllable canonical form of B
            Bblock1 = eye(obj.CatNum)+triu(-1*ones(obj.CatNum),1);
            Bblock2 = [0;1];
            obj.B = kron(Bblock1,Bblock2);        
            
            % Define the Target matrix.
            obj.TarMat = (1-obj.alpha)*obj.SimMat+obj.alpha*obj.FDDMat;
            obj.TarMat(obj.TarMat==0) = 1e-3;
            
            % Initialize the catogerical probability simplex.
            % P(x=1)=1 and subtracted by small values to ensure the inverse
            % softmax domain to be valid. 
            p0 = [1-1e-2*(obj.CatNum-1);repmat(1e-2,obj.CatNum-1,1)]; 
            
            % Initial points of p0 in inverse softmax domain.
            obj.xfake_inv_softmax = reshape([log(p0)+10,zeros(obj.CatNum,1)]',[2*obj.CatNum,1]);
        end
        
        %% system output and state update equations.   
        function [xe, P_request] = stepImpl(obj,xtrue, EnableReset, P_supply)
            % Purpose: update system state variables and outputs.
            
            % Inputs:  1) xtrue (float; range [0, 1]): ture health state variables.
            %          2) EnableReset (boolean): reset the simulated FDD. True: reset. 
            %          3) P_supply (float): power supply to the simulated FDD.
            % Outputs: 1) xe (float): simulated pmf of the health state variables.
            %          2) P_request: simulated FDD power consumption. 
            
            %------------- Determine the FDD power_mode [start] -----------
            if P_supply >= obj.P_request
                
                if obj.ps_p == true
                    power_mode = 'On';
                    obj.ps_p = true;
                else % obj.ps_p == false
                    power_mode = 'StartUp';    
                    obj.ps_p = true;
                end
                
            else % P_supply < obj.P_request
                
                if obj.ps_p == true
                    power_mode = 'ShutDown';
                    obj.ps_p = false;
                else % obj.ps_p == false
                    power_mode = 'Off';
                    obj.ps_p = false;
                end
                
            end
            %------------- Determine the FDD power_mode [end] -------------
            
            %------------- Update the simulated pmf [start] ---------------
            switch power_mode
                
                case 'On'                       
                    if EnableReset
                        % Reset FDD state variables.
                        p0 = [1-1e-2*(obj.CatNum-1);repmat(1e-2,obj.CatNum-1,1)];
                        obj.xfake_inv_softmax = reshape([log(p0)+10,zeros(obj.CatNum,1)]',[2*obj.CatNum,1]);                        
                        xe = [1; 0; 0; 0];                        
                    else
                        % Set ode solver time span.
                        tspan = [0,obj.timestep]; 
                        
                        % Set equilibrium points according to the true catogerical variable value.
                        xr = reshape([log(obj.TarMat(xtrue,:)/sum(obj.TarMat(xtrue,:)))+10;zeros(1,obj.CatNum)],[2*obj.CatNum,1]);
                        
                        % Solve ode: dxdt=system(obj,t,x,xr)
                        [~,xfake_inv_softmax_TS] = ode45(@(t,x) system(obj,t,x,xr),tspan,obj.xfake_inv_softmax);
                        
                        % Store the updated FDD state variables.
                        obj.xfake_inv_softmax = xfake_inv_softmax_TS(end,:)';
                        
                        % Back to probability simplex
                        xep = bsxfun(@rdivide,exp(xfake_inv_softmax_TS(end,1:2:end)),sum(exp(xfake_inv_softmax_TS(end,1:2:end)),2));
                        
                        % Generate additive noises.
                        N = normrnd(0,obj.noise,[1,obj.CatNum-1]);
                        
                        % Compute outputs.
                        xe = (min(max(xep+[N,0-sum(N,2)],zeros(1,obj.CatNum)),ones(1,obj.CatNum)))';
                    end                    
                    
                case 'Off'
                    xe = zeros(4, 1);
                    
                case 'StartUp'
                    % Initialize FDD state variables.
                    p0 = [1-1e-2*(obj.CatNum-1);repmat(1e-2,obj.CatNum-1,1)];
                    obj.xfake_inv_softmax = reshape([log(p0)+10,zeros(obj.CatNum,1)]',[2*obj.CatNum,1]);                    
                    xe = [1; 0; 0; 0];
                
                otherwise % 'ShutDown'
                    xe = zeros(4, 1);
                    
            end
            %------------- Update the simulated pmf [end] -----------------          
            
            P_request = obj.P_request;
            
        end
        
        %% Define the linear dynamical system for the simulated FDD
        function dxdt=system(obj,t,x,xr)
            dxdt = obj.A*(x-xr)-obj.B*obj.K*(x-xr);
        end
        %%
        function num = getNumInputsImpl(~)
            num = 3;
        end      
        function num = getInputsSizeImpl(~)
            num = 1;
        end          
        
        function num = getNumOutputsImpl(~)
            num = 2;
        end
        
        function[o1,o2] = getOutputSizeImpl(~)
            o1 = 4;  
            o2 = 1;
            
        end
       
        function [o1, o2] = getOutputDataTypeImpl(~)
            o1 = 'double';
            o2 = 'double';
        end
         
        function [o1, o2] = isOutputFixedSizeImpl(~)
            o1 = true;    
            o2 = true;
        end
         
        function [o1, o2] = isOutputComplexImpl(~)
            o1 = false;   
            o2 = false;
        end
        
    end
    
    
end