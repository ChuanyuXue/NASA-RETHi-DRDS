classdef ECLSS_simu_FDD_dust < matlab.System & matlab.system.mixin.Propagates
    properties        
        timestep
        Ksingle
        noise=1e-2      
        num = 50       
    end
    properties (Access = private)
        bias=0.1        % stable bias of bernoulli variable parapmeter
        A 
        B
        K
        wd=1/10;            % default imaginary coordinate when zita is 0
        y                   % coordiante of imaginary parts of poles
        x                   % coordiante of real parts of poles
        wn
        poles         
        xfake_inv_sig       % state vector of the fake FDD; inverse sigmoid function image
    end

    
    methods(Access = protected)        
        function setupImpl(obj)
            if obj.bias==0
                % handle bias=0 case to make inverse sigmoid
                obj.bias=1e-3;
            else
                obj.bias=obj.bias;
            end   
            % initialization of A
            obj.A = kron(eye(obj.num), [0, 1; -1, -1]);
%             obj.B = kron(ones(obj.num,1), [0 ; 1]);
            obj.B = kron(eye(obj.num), [0;1]);
%             obj.K = kron(ones(1,obj.num), obj.Ksingle);
            obj.K = kron(eye(obj.num), obj.Ksingle);
            % initialization of state variables p = 1e-3
            obj.xfake_inv_sig=kron(ones(obj.num,1),[log(1e-3/(1-1e-3));0]); %work on inverse sigmoid 
        end
        
        function [xe]= stepImpl(obj,xtrue,EnableReset)
            
            
            if EnableReset
                obj.xfake_inv_sig=kron(ones(obj.num,1),[log(1e-3/(1-1e-3));0]);                
                xe = min(max(1 ./ (1 + exp(-obj.xfake_inv_sig(1:2:end) )) + normrnd(0, obj.noise,[50,1]), 0), 1) ;              
            else
                % set equilibrium points  
                xr_block_1 = kron(xtrue, [log((1-obj.bias)/(1-(1-obj.bias)));0]);
                xr_block_0 = kron(double(~xtrue),[log((0+obj.bias)/(1-(0+obj.bias)));0]);
                xr = xr_block_1 + xr_block_0;                
                
                tspan=[0,obj.timestep];
                % solve ode
                [~,xfake_inv_sig_TS]=ode45(@(t,x) system(obj,t,x,xr),tspan,obj.xfake_inv_sig);
                % save state vector
                obj.xfake_inv_sig=xfake_inv_sig_TS(end,:)';
                % back to probability simplex and output it
                xe = min(max(1 ./ (1 + exp(-obj.xfake_inv_sig(1:2:end) )) + normrnd(0, obj.noise,[50,1]), 0), 1) ;
            end
        end
        
        function dxdt=system(obj,t,x,xr)
            dxdt=obj.A*(x-xr)-obj.B*obj.K*(x-xr);
        end
        
        function num = getNumInputsImpl(~)
            num = 2;
        end      
        
        
        function num = getNumOutputsImpl(~)
            num = 1;
        end
        function[i1,i2] = getInputSizeImpl(~)
            i1=50;            
            i2=1;
        end
        
        function[o1] = getOutputSizeImpl(~)
            o1=50;            
            
        end
       
        function [o1] = getOutputDataTypeImpl(~)
            o1='double';            
        end
         
        function [o1] = isOutputFixedSizeImpl(~)
            o1=true;           
        end
         
        function [o1] = isOutputComplexImpl(~)
            o1=false;          
        end
    end
end
