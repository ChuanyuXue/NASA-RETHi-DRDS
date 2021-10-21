classdef Triple_Junction_PVcell_test<handle
    % Triple junction solar cell model.
    % Bases: handle
    % Purpose: electrical, thermal, and optical models of triple junction 
    %          solar PV cell Ga51In49P/GaAs/Ge.
    
    % Date Created: 1 May 2020
    % Date Last Modified: 1 September 2021
    % Modeler Name: Kairui Hao (Purdue)
    % Funding Acknowledgement: Space Technology Research Institutes Grant 
    %                          80NSSC19K1076 from NASA's Space Technology 
    %                          Research Grants Program.
    % Version Number: MCVT v5
    
    
    properties
        timestep = 0.001    % time step [s]    
        sigma = 5.6697e-8    % Stefan-Boltzmann constant
    end    

    
    properties (Access = protected)
        %%               PV cell properties
        %----------- subcell current [A] ----------------------------------
        IGaInP
        IGaAs
        IGe
        
        %----------- subcell Photon generated current [A] -----------------
        IphGaInP; IphGaInP_n=0.5528;
        IphGaAs;  IphGaAs_n=0.4719;
        IphGe;    IphGe_n=0.9303;
        
        %----------- subcell voltage [V]-----------------------------------
        VGaInP;     VGaAs;       VGe
        
        %----------- subcell ideality factor ------------------------------
        aGaInP=1.1;   aGaAs=1.1;     aGe=1.1;   abd=1;
        
        %----------- subcell series resistance ----------------------------
        RsGaInP;    RsGaInP_n=0.1;
        RsGaAs;     RsGaAs_n=0.1;
        RsGe;       RsGe_n=0.01;
        
        %----------- subcell thermal voltage ------------------------------
        VtGaInP;    VtGaAs;      VtGe;      Vtbd;
        VtGaInP_n;  VtGaAs_n;    VtGe_n;    Vtbd_n;
        
        %----------- subcell shunt resistance -----------------------------
        RshGaInP;   RshGaInP_n=200;
        RshGaAs;    RshGaAs_n=200;
        RshGe;      RshGe_n=50;
        
        %----------- subcell energy bandgap [eV] at 300[K]/T[K]/0[K] -------
        EgGaInP;    EgGaInP_n=1.8500;     EgGaInP_0=1.9247; 
        EgGaAs;     EgGaAs_n=1.4224;       EgGaAs_0=1.519;
        EgGe;       EgGe_n=0.6700;        EgGe_0=0.7502;
        Egbd;       Egbd_n=1.12;  
        
        %---------- subcell energy bandgap temperature dependence parameters
        % a [eV/K]; b [K]
        a_EgGaInP=4.72e-4;  b_EgGaInP=269;
        a_EgGaAs=5.41e-4;   b_EgGaAs=204;
        a_EgGe=4.77e-4;     b_EgGe=235;
        
        %-----------nominal temperature [K]--------------------------------
        T;          Tn=300;
        
        %-----------nominal solar irradiance [W/cm2]-----------------------
        G;          Gn=1354.3;
        
        %-----------temperature coefficient--------------------------------
        % <relative> subcell short circuit current temperature change [%/C]
        % This parameter has a high freedom but kiR_GaInP> kiR_GaAs>kiR_Ge
        kiR_GaInP=0.07e-2; kiR_GaAs=0.06e-2; kiR_Ge=0.03e-2;
        % <absolute> subcell short circuit current temperature coefficient
        ki_GaInP;   ki_GaAs;    ki_Ge;  
        
        ki            % short-circuit current temperature coefficient
        kv            % open-circuit voltage temperature coefficient
        
        %-----------reverse saturation current at nominal condition--------
        I0GaInP;    I0nGaInP=1.9249e-24;
        I0GaAs;     I0nGaAs=4.2057e-17;
        I0Ge;       I0nGe=0.0036;
        I0bd;       I0nbd=2e-9;   % bypass diode reverse saturation current      
        
        
        %%                thermal properties
        
        
        %----------- material density [kg/m3] -----------------------------
        rho_g=2700                   % density of glass
        rho_EVA=960                 % density of EVA
        rho_cell=2300                % density of cell
        rho_b=1370                   % density of back sheet(Tedlar)
        
        %----------- layer thickness [m] ----------------------------------
        e_g=3.2e-3                     % thickness of glass
        e_EVA=0.5e-3                   % thickness of EVA
        e_cell                          % thickness of cell
        e_b=0.3e-3                     % thickness of back sheet
        
        %----------- specific heat capacity [J/(kg*K)] --------------------
        c_g=750                     % specific heat of glass
        c_EVA=2090                   % specific heat of EVA
        c_cell=836                  % specific heat of cell
        c_b=1760                     % specific heat of back sheet
        
        %--------------- absorptance --------------------------------------
        al_g=0                   % absorptance of glass
        al_EVA=0.0597                  % absorptance of EVA
        al_cell=0.8619                 % absorptance of cell
        al_b=0.94               % absorptance of the back sheet
        
        %--------------- reflectance --------------------------------------
        r_g=0.0422                    % reflectance of glass
        r_EVA=0                  % reflectance of EVA
        r_cell=0.025                  % reflectance of cell
        r_b=0.06
        
        %-------------- transmittance -------------------------------------
        tau_g=0.9578                  % transmittance of glass
        tau_EVA=0.9403                % transmittance of EVA
        tau_cell=0.1131               % transmittance of cell
        
        %-------------- emissivity ----------------------------------------        
        ep_g= 0.9                   % emissivity of glass
        ep_b=0.9                    % emissivity of back sheet

        %-------------- thermal conductivity [W/(m*K)] --------------------
        k_g=1.8                     % thermal conductivity of glass
        k_EVA=0.35                   % thermal conductivity of EVA
        k_cell=149                  % thermal conductivity of cell
        k_b=0.35                     % thermal conductivity of back sheet
        
        %-------------- convective exchange coefficient ------------------- 
        h_g=0                     % convective exchange coefficient of glass
        h_b=0                     % convective exchange coefficient of back sheet
        
        %-------------- temperatures of solar PV module layers [K] --------
        T_g                     % glass temperature 
        T_EVA                   % EVA temperature 
        T_cell                  % cell temperature 
        T_b                     % back sheet temperature 
        
        %-------------- refractive index ----------------------------------
        n_g=1.5168              % refractive index of glass
        n_EVA=1.4912            % refractive index of EVA
        n_cell                  % refractive index of cell
        n_vacuum=1              %
        
        %-------------- absorption coefficient [cm^-1] --------------------
        a_g=0.0020857           % absorption coefficient of glass 
        a_EVA=0.12304           % absorption coefficient of EVA 
        a_cell                  % absorption coefficient of cell
        
        %%              Geometric Parameters           
        A=27                       % cell area [cm^2]        
        % thickness of emitter [micrometer]
        xe1=0.1;        xe2=0.1;        xe3=0.05;
        % thickness of depletion region [micrometer]
        w1=0;           w2=0;           w3=0;
        % thickness of base [micrometer]
        xb1=0.4;        xb2=10;         xb3=140;

        %%             PV module properties
        ns=60          % number of series connected PV cell in a PV module
        Amodule       % PV module area [m^2]
        np=1            % number of parallel connected PV cell in a PV module
        Rs_module=0.1   % series resistance of a PV module  
        Rsh_module=1000 % shunt resistance of a PV module 
        FF = 0.864;     % Fill factor
        beta=deg2rad(0)% tilted slope angle of PV Module        
        solar_I         % Solar radiation data
        DRatio         %dust cover ratio
        % constant
        h=6.626070e-34  % Plank constant
        c=2.998e8       % Speed of light
        q=1.60217646e-19% electron charge [C]
        k=1.3806503e-23 % Boltzmann constant [J/K]
        
    end

    
    methods
        %% Constructor
         function obj=Triple_Junction_PVcell_test()                      
                                     
             % compute thermal voltage at 300[K].
             obj.VtGaInP_n=obj.aGaInP*obj.k*obj.Tn/obj.q;
             obj.VtGaAs_n=obj.aGaAs*obj.k*obj.Tn/obj.q;
             obj.VtGe_n=obj.aGe*obj.k*obj.Tn/obj.q;
             obj.Vtbd_n=obj.abd*obj.k*obj.Tn/obj.q;             
            
             % compute subcell absolute short circuit current temperature
             % coefficient.
             obj.ki_GaInP=obj.IphGaInP_n*obj.kiR_GaInP;
             obj.ki_GaAs=obj.IphGaAs_n*obj.kiR_GaAs;
             obj.ki_Ge=obj.IphGe_n*obj.kiR_Ge;
             
             % compute PV cell thickness.
             obj.e_cell=(obj.xe1+obj.xe2+obj.xe3+obj.w1+obj.w2+obj.w3+obj.xb1+obj.xb2+obj.xb3)*1e-6;
             
             % compute PV module area.
             obj.Amodule=obj.ns*27*1e-4; 
         end
         
        %% Combined electric and thermal model for a PV module
        function [P_mppmodule,T,DRatio]=solve_Triple_ElecTher_module(obj,Tamb,Tsky,Tground,G_in,T_ini,DRatio, dustrate, cleanrate)
            % Inputs:   1) Tamb (float): ambient temperature (K)
            %           2) Tsky (float): sky temperature (K)
            %           3) Tground (float): ground temperature (K)
            %           4) G_in (float): solar irradiance to the glass surface (W/m^2)
            %           5) P_module (float): PV module power (W)
            %           6) T_ini (float): solar PV module initial temperature (K). shape: (1,5) 
            %           7) DRatio (float): dust accumulation ratio
            %           8) dustrate (float): dust accumulation rate [1/s]
            %           9) cleanrate (float): dust cleaning rate [1/s]
            % Outputs:  1) P_mppmodule (float): single solar PV module power generation (W)
            %           2) T (float): solar PV module temperatures of five layers [K]            
            %           3) DRatio (float): dust cover ratio [0,1].
            % Update DRatio.
            DRatio=max(min(DRatio+obj.timestep*(dustrate-cleanrate),1),0);
            
            % Compute solar irradiance.
            G_cell=(1-DRatio)*G_in*obj.tau_g*obj.tau_EVA;
            
            % Compute single solar PV module power generation. 
            [P_mppmodule]=solve_Triplemodule_MPP_fzero(obj,G_cell,T_ini(3));
            
            % Update solar PV module temperatures of five layers.
            tspan=[0,obj.timestep];                      
            [~,Tstates]=ode45(@(t,T) obj.solve_Triple_thermal_module(t,T,Tamb,Tsky,Tground,G_in,P_mppmodule),tspan,T_ini');
            T=Tstates(end,:);           
            
        end
        
         %% Fill factor to compute Pmpp of a PV module (fzero)
        function [P_mppmodule]=solve_Triplemodule_MPP_fzero(obj,G_in,T)
                % Inputs:   1) G_in(float): solar irradiance (W/m^2)
                %           2) T(float): solar PV cell temperature (K)  
                % Outputs:  1) P_mppmodule(float): solar PV module power output at MPP (W)
                
                fzero_ini = 0.1;    % fzero initial guess points.
                
                % compute short circuit current.
                IGaInP_sc=fzero(@(I) solar_IVplotGaInP(obj,I,0,G_in,T),fzero_ini);
                IGaAs_sc=fzero(@(I) solar_IVplotGaAs(obj,I,0,G_in,T),fzero_ini);
                IGe_sc=fzero(@(I) solar_IVplotGe(obj,I,0,G_in,T),fzero_ini);
                I_sc=min([IGaInP_sc,IGaAs_sc,IGe_sc]);
                
                % compute open circuit voltage.
                VGaInP_oc=fzero(@(V) solar_IVplotGaInP(obj,0,V,G_in,T),fzero_ini);
                VGaAs_oc=fzero(@(V) solar_IVplotGaAs(obj,0,V,G_in,T),fzero_ini);
                VGe_oc=fzero(@(V) solar_IVplotGe(obj,0,V,G_in,T),fzero_ini);
                V_oc=VGaInP_oc+VGaAs_oc+VGe_oc;
                
                % estimate power generation rate.
                P_mppmodule=I_sc*V_oc*obj.FF*obj.ns;
        end        
        
    end
    
    methods (Access = protected)
         %% The lumped continuous thermal model for a PV module 
        function [dT]=solve_Triple_thermal_module(obj,t,T,Tamb,Tsky,Tground,G_in,P_module)
            % Inputs:   1) Tamb (float): ambient temperature (K)
            %           2) Tsky (float): sky temperature (K)
            %           3) Tground (float): ground temperature (K)
            %           4) G_in  (float): solar irradiance to the glass surface (W/m^2)
            %           5) P_module (float): PV module power (W)
            % Outputs:  1) dT (float): derivative of temperature
            
            P_module=P_module/obj.Amodule;
            dT=zeros(5,1);            
            Tgu=T(1);
            TEu=T(2);
            Tc=T(3);
            TEl=T(4);
            Tb=T(5);
            F_g2sky=0.5*(1+cos(obj.beta));
            F_g2ground=0.5*(1-cos(obj.beta));
            F_b2sky=0.5*(1+cos(pi-obj.beta));
            F_b2ground=0.5*(1-cos(pi-obj.beta));
            dT(1)=(obj.al_g*G_in -(Tgu-TEu)/(obj.e_g/(2*obj.k_g)+obj.e_EVA/(2*obj.k_EVA))+obj.h_g*(Tamb-Tgu)-...
                obj.ep_g*F_g2sky*obj.sigma*(Tgu^4-Tsky^4)-obj.ep_g*F_g2ground*obj.sigma*(Tgu^4-Tground^4))/(obj.rho_g*obj.e_g*obj.c_g);
            dT(2)=(obj.al_EVA*obj.tau_g*G_in +(Tgu-TEu)/(obj.e_g/(2*obj.k_g)+obj.e_EVA/(2*obj.k_EVA))-...
                (TEu-Tc)/(obj.e_EVA/(2*obj.k_EVA)+obj.e_cell/(2*obj.k_cell)))/(obj.rho_EVA*obj.e_EVA*obj.c_EVA);
            dT(3)=(obj.al_cell*obj.tau_g*obj.tau_EVA*G_in +(TEu-Tc)/(obj.e_EVA/(2*obj.k_EVA)+obj.e_cell/(2*obj.k_cell))-...
                (Tc-TEl)/(obj.e_cell/(2*obj.k_cell)+obj.e_EVA/(2*obj.k_EVA))-P_module)/(obj.rho_cell*obj.e_cell*obj.c_cell);
            dT(4)=(obj.al_EVA*obj.tau_g*obj.tau_EVA*obj.tau_cell*G_in +(Tc-TEl)/(obj.e_cell/(2*obj.k_cell)+obj.e_EVA/(2*obj.k_EVA))-...
                (TEl-Tb)/(obj.e_EVA/(2*obj.k_EVA)+obj.e_b/(2*obj.k_b)))/(obj.rho_EVA*obj.e_EVA*obj.c_EVA);
            dT(5)=(obj.al_b*obj.tau_g*obj.tau_EVA*obj.tau_cell*obj.tau_EVA*G_in +(TEl-Tb)/(obj.e_EVA/(2*obj.k_EVA)+obj.e_b/(2*obj.k_b))-...
                obj.h_b*(Tb-Tamb)-obj.ep_b*F_b2sky*obj.sigma*(Tb^4-Tsky^4)-obj.ep_b*F_b2ground*obj.sigma*(Tb^4-Tground^4))/(obj.rho_b*obj.e_b*obj.c_b);
        end
    end   
        
end

%% Define the IV equation to be plotted
function y=solar_IVplotGaInP(obj,I,V,G,T)
obj.VtGaInP=obj.aGaInP*obj.k*T/obj.q;
obj.IphGaInP=(obj.IphGaInP_n+obj.ki_GaInP*(T-obj.Tn))*G/obj.Gn;
obj.EgGaInP=E_GaInP(obj,T);
obj.I0GaInP=obj.I0nGaInP*(T/obj.Tn)^3*exp(obj.EgGaInP_n/obj.VtGaInP_n-obj.EgGaInP/obj.VtGaInP);
obj.RsGaInP=obj.RsGaInP_n;
obj.RshGaInP=obj.RshGaInP_n*obj.Gn/G;

y=I-obj.IphGaInP+obj.I0GaInP*(exp((V+obj.RsGaInP*I)/(obj.VtGaInP))-1)+(V+obj.RsGaInP*I)/obj.RshGaInP;
end

function y=solar_IVplotGaAs(obj,I,V,G,T)
obj.VtGaAs=obj.aGaAs*obj.k*T/obj.q;
obj.IphGaAs=(obj.IphGaAs_n+obj.ki_GaAs*(T-obj.Tn))*G/obj.Gn;
obj.EgGaAs=E_GaAs(obj,T);
obj.I0GaAs=obj.I0nGaAs*(T/obj.Tn)^3*exp(obj.EgGaAs_n/obj.VtGaAs_n-obj.EgGaAs/obj.VtGaAs);
obj.RsGaAs=obj.RsGaAs_n;
obj.RshGaAs=obj.RshGaAs_n*obj.Gn/G;

y=I-obj.IphGaAs+obj.I0GaAs*(exp((V+obj.RsGaAs*I)/(obj.VtGaAs))-1)+(V+obj.RsGaAs*I)/obj.RshGaAs;
end

function y=solar_IVplotGe(obj,I,V,G,T)
obj.VtGe=obj.aGe*obj.k*T/obj.q;
obj.IphGe=(obj.IphGe_n+obj.ki_Ge*(T-obj.Tn))*G/obj.Gn;
obj.EgGe=E_Ge(obj,T);
obj.I0Ge=obj.I0nGe*(T/obj.Tn)^3*exp(obj.EgGe_n/obj.VtGe_n-obj.EgGe/obj.VtGe);
obj.RsGe=obj.RsGe_n;
obj.RshGe=obj.RshGe_n*obj.Gn/G;

y=I-obj.IphGe+obj.I0Ge*(exp((V+obj.RsGe*I)/(obj.VtGe))-1)+(V+obj.RsGe*I)/obj.RshGe;
end


%% Define energy band gap temperature dependence 
function E=E_GaInP(obj,T)
E=obj.EgGaInP_0-obj.a_EgGaInP*T^2/(T+obj.b_EgGaInP);
end
function E=E_GaAs(obj,T)
E=obj.EgGaAs_0-obj.a_EgGaAs*T^2/(T+obj.b_EgGaAs);
end
function E=E_Ge(obj,T)
E=obj.EgGe_0-obj.a_EgGe*T^2/(T+obj.b_EgGe);
end


