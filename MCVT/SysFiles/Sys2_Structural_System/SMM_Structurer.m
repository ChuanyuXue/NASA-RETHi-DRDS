function[SMM_T0,SMM_T4_0,SMM_T1,SMM_T4_1,SMM_T2,SMM_T4_2,SMM_T3,SMM_T4]=SMM_Structurer

%% Purpose
%    This code Call SMM_Initialize and put the generated data into Structures
        % There are 4 Tiers
            % T0: Input parameters
            % T1: Derived from T0 parameters 
            % T2: Derived from T0, T1 parameters
            % T3: Derived from T0, T1, T2 parameters
            % T4: Derived from T0, T1, T2, T3 parameters

%% Outputs
% ----------------------------------------------------------------------------------------------------------------
% Structure container     Variable name	Variable description
% ----------------------------------------------------------------------------------------------------------------
% SMM_T0.                 MoE             Modulus of easticity (N/m^2)
% SMM_T0.                 PoRat           Poissons ratio
% SMM_T0.                 rho             Density
% SMM_T0.                 Tinit           0 stress temperature
% SMM_T0.                 Type            Contains element information
% SMM_T0.                 S_Type          Contains surface information for Pressure loading
% SMM_T0.                 Reg_Elems       Contains element information and Domain relation
% SMM_T0.                 Shape           Shape functions for different element types
% SMM_T0.                 DShape          Contains derivatives of shape functions
% SMM_T0.                 W               Contains weight for different element types
% SMM_T0.                 delta           Parameters for Newmark-beta scheme
% SMM_T0.                 alpha           Parameters for Newmark-beta scheme
% 		
% SMM_T4_0.               Nodes_M         Contains Node information
% SMM_T4_0.               IEN_M           Connectivity matrix
% SMM_T4_0.               P_N_M           Contains Impact node information
% 		
% SMM_T1.                 a-a7            Parameters for Newmark-beta scheme
% SMM_T1.                 nel             Number of elements
% SMM_T1.                 neq             Number of equations
% SMM_T1.                 nnp             Number of nodes
% SMM_T1.                 Shape           Contains shape information for different types of elements
% SMM_T1.                 DShape          Contains shape derivative information for different types of elements
% SMM_T1.                 W               Contains weight information for different types of elements
% SMM_T1.                 Dm              Constitutive matrix
% 		
% SMM_T4_1.               LM_M            A set of matrices for FEM computation
% SMM_T4_1.               IEN_Colm_M      A set of matrices for FEM computation
% 		
% SMM_T2.                 B               B matrix
% SMM_T2.                 dJB             Contains jacobian for each Gauss point
% SMM_T2.                 P_surf          Pressure to equivalent nodal force converter
% SMM_T2.                 IS_F            Internal stress to Force vector converter
% SMM_T2.                 TGP             Number of Gauss points
% SMM_T2.                 gp_X            x coordinate of Gauss points
% SMM_T2.                 gp_Y            y coordinate of Gauss points
% SMM_T2.                 gp_Z            z coordinate of Gauss points
% 		
% SMM_T4_2.               fB_M            Force vectors due to Gravity
% 		
% SMM_T3.                 Ke              Stiffness matrix for each element
% 		
% SMM_T4.                 C_M             Damping matrix
% SMM_T4.                 K_M             Stiffness matrices
% SMM_T4.                 Kbar_M          A set of matrices for FEM computation
% SMM_T4.                 M_M             Mass matrices
% SMM_T4.                 IKii_M          Precalculated matrices for Domain decomposition
% SMM_T4.                 Kbbr_M          Precalculated matrices for Domain decomposition
% SMM_T4.                 Kib_M           Precalculated matrices for Domain decomposition
% SMM_T4.                 fbr_M           Precalculated matrices for Domain decomposition
% SMM_T4.                 L               DOF after removing boundary
% SMM_T4.                 Li              Length of Kii


%% Load the required SMM model file
    load('SMM_Initialize', '-regexp', '^(?!dt)\w');
  
%% FEM parameters T0 ( Can be moved to Input)
    % Material properties
    SMM_T0.MoE=MoE;
    SMM_T0.PoRat=PoRat;
    SMM_T0.rho=rho;
    SMM_T0.Tinit=Tinit;

    
    % Geometric and FEM input properties (May require Tier 0 in-house code)
    SMM_T0.S_Type=S_Type;
    SMM_T0.Type=Type;
    SMM_T0.Reg_Elems=Reg_Elems;
    SMM_T0.Reg_Nodes=Reg_Nodes;
  
    % Time Integration scheme
    SMM_T0.delta=delta;
    SMM_T0.alpha=0.25;
    % SMM_T0.dt=dt;
    
    % T0 parameters with T4 modifications
    SMM_T4_0.IEN_M=IEN_M;
    SMM_T4_0.Nodes_M=Nodes_M;
    SMM_T4_0.P_N_M=P_N_M;

%% T1 Parameters (Require in-house Tier 1 code)

    % Dynamic run parameters
    SMM_T1.a0=a0;
    SMM_T1.a1=a1;
    SMM_T1.a2=a2;
    SMM_T1.a3=a3;
    SMM_T1.a4=a4;
    SMM_T1.a5=a5;
    SMM_T1.a6=a6;
    SMM_T1.a7=a7;

    % FEM parameters 
    SMM_T1.DShape=DShape;
    SMM_T1.Shape=Shape;
    SMM_T1.W=W;
    
    % Geometric and Material parameters
    SMM_T1.ndof=ndof;
    SMM_T1.nel=nel;
    SMM_T1.neq=neq;
    SMM_T1.nnp=nnp;
    SMM_T1.Dm=Dm;
    
    % T1 parameters with T4 modifications
    SMM_T4_1.IEN_Colm_M=IEN_Colm_M;
    SMM_T4_1.LM_M=LM_M;
    

%% T2 Parameters
    % FEM parameters
    SMM_T2.B=B;
    SMM_T2.dJB=dJB;
    SMM_T2.P_surf=P_surf;
    
    SMM_T2.IS_F=IS_F;

    SMM_T2.TGP=TGP;
    
    SMM_T2.gp_X=gp_X;
    SMM_T2.gp_Y=gp_Y;
    SMM_T2.gp_Z=gp_Z;
    SMM_T2.Reg_GP=Reg_GP;
    
    % T2 parameters with T4 modifications
    SMM_T4_2.fB_M=fB_M;

 %% T3 Parameters     
    SMM_T3.Ke=Ke;
    SMM_T3.L=L;
    
%% T4 Parameters    
    SMM_T4.C_M=C_M;
    SMM_T4.K_M=K_M;
    SMM_T4.Kbar_M=Kbar_M;
    SMM_T4.M_M=M_M;
    
    SMM_T4.Li=Li;

%% T4 parameters
    SMM_T4.fbr_M=fbr_M;
    SMM_T4.IKii_M=IKii_M;
    SMM_T4.Kbbr_M=Kbbr_M;
    SMM_T4.Kib_M=Kib_M;
    
end

    
    
    