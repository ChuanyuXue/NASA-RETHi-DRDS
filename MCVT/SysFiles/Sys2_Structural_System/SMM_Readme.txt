________________________________________________________________________
                   Structural Mechanical Model documentation
                                               Version 1.4                  
Date Created:
Date Last modified: 08/25/2021
Funding acknowledgement: NASA 

This documentation contains 6 sections,
     1. Developers  
     2. Structural Mechanical Subsystem Model Description
     3. Model Files and Preloaded variables
     4. Model Inputs and outputs

Important notes:
    1. You can read and pick any Node or Gauss point from Section 6.
    2. And use codes described in Section 5 to extract output from SMM for that Node or Gauss point.
    3. The number assigned to nodes change with respect to Impact location. So, you need to extract node information for a specific MCVT run.


________________________________________________________________________
                         1. Developers

Developers: Adnan Shahriar, Ph.D student
            Contact: adnan.shahriar@utsa.edu
            Website: adnansh.com
            Department of Mechanical Engineering, UTSA Texas

     	    Sterling Reynolds , Undergraduate student
            Contact: icu327@my.utsa.edu
            Department of Mechanical Engineering, UTSA Texas

Advisor:    Arturo Montoya ,  Ph.D
            Contact: arturo.montoya@utsa.edu
            Department of Civil Engineering, UTSA Texas


________________________________________________________________________
             2. Structural Mechanical Subsystem Model Description

Purpose: Solve 3D Structural dynamics Equation: Md^2u/dt^2+Cdu/dt+Ku=F
Chapter in MCVT: RETHi_MCVT_Sub2_Structural_Subsystem

The SMM is a FE based model which has two calculation points, 
     1. Nodes:
        Displacement, Velocity and Acceleration are calculated at Nodes.
     2. Integration/Gauss points.
        Damage, Stress and Strain are calculated at Integration or Gauss points
        The number assigned to Gauss points does not change with respect to Impact location.

Domain decomposition on SMM:
    The SMM has been divided into multiple Domains. For each domain some Matrices has been Precalculated and Stored into Matrix Sets.
    During simulation, based on impact location, proper domain and Matrices will be selected from the Matrix Sets.
_______________________________________________________________________________
                      3. Model Files and Preloaded variables        

Files loaded in workspace:


----------------------------------------------------------------------------------------------------------------
Structure container     Variable name	Variable description
----------------------------------------------------------------------------------------------------------------
SMM_T0.                 MoE             Modulus of easticity (N/m^2)
SMM_T0.                 PoRat           Poissons ratio
SMM_T0.                 rho             Density
SMM_T0.                 Tinit           0 stress temperature
SMM_T0.                 Type            Contains element information
SMM_T0.                 S_Type          Contains surface information for Pressure loading
SMM_T0.                 Reg_Elems       Contains element information and Domain relation
SMM_T0.                 Shape           Shape functions for different element types
SMM_T0.                 DShape          Contains derivatives of shape functions
SMM_T0.                 W               Contains weight for different element types
SMM_T0.                 delta           Parameters for Newmark-beta scheme
SMM_T0.                 alpha           Parameters for Newmark-beta scheme
		
SMM_T4_0.               Nodes_M         Contains Node information
SMM_T4_0.               IEN_M           Connectivity matrix
SMM_T4_0.               P_N_M           Contains Impact node information
		
SMM_T1.                 a-a7            Parameters for Newmark-beta scheme
SMM_T1.                 nel             Number of elements
SMM_T1.                 neq             Number of equations
SMM_T1.                 nnp             Number of nodes
SMM_T1.                 Shape           Contains shape information for different types of elements
SMM_T1.                 DShape          Contains shape derivative information for different types of elements
SMM_T1.                 W               Contains weight information for different types of elements
SMM_T1.                 Dm              Constitutive matrix
		
SMM_T4_1.               LM_M            A set of matrices for FEM computation
SMM_T4_1.               IEN_Colm_M      A set of matrices for FEM computation
		
SMM_T2.                 B               B matrix
SMM_T2.                 dJB             Contains jacobian for each Gauss point
SMM_T2.                 P_surf          Pressure to equivalent nodal force converter
SMM_T2.                 IS_F            Internal stress to Force vector converter
SMM_T2.                 TGP             Number of Gauss points
SMM_T2.                 gp_X            x coordinate of Gauss points
SMM_T2.                 gp_Y            y coordinate of Gauss points
SMM_T2.                 gp_Z            z coordinate of Gauss points
		
SMM_T4_2.               fB_M            Force vectors due to Gravity
		
SMM_T3.                 Ke              Stiffness matrix for each element
		
SMM_T4.                 C_M             Damping matrix
SMM_T4.                 K_M             Stiffness matrices
SMM_T4.                 Kbar_M          A set of matrices for FEM computation
SMM_T4.                 M_M             Mass matrices
SMM_T4.                 IKii_M          Precalculated matrices for Domain decomposition
SMM_T4.                 Kbbr_M          Precalculated matrices for Domain decomposition
SMM_T4.                 Kib_M           Precalculated matrices for Domain decomposition
SMM_T4.                 fbr_M           Precalculated matrices for Domain decomposition
SMM_T4.                 L               DOF after removing boundary
SMM_T4.                 Li              Length of Kii
		
                        D_Eq            Preallocated Damage matrix
----------------------------------------------------------------------------------------------------------------
    
    _______________________________________________________________________________
                     4. Model Inputs and outputs

                  ____________________________________________
             TIn-|                  SMM                       |-U1
             PIn-|            Internal Blocks:                |-Vel1
          MQ_Acc-|Inputs      1. Domain selection      Outputs|-Acc1
          WN_Acc-|            2. Force Calculation            |-Damage_Status_O
           Imp_F-|            3. Solver                       |-D_EqO
   Repair_Status-|____________________________________________|-



----------------------------------------------------------------------------------
Input name        Physical meaning      Unit                 From            Size        
----------------------------------------------------------------------------------
TIn                 Temperature         Kelvin               STM             46x1
PIn                 Pressure            Pa                   IEM             17x1
MQ_Acc              Moonquake           m/s^2                EEM             3x1
WN_Acc              White noise         m/s^2                EEM             1x1
Imp_F               Impact force        N                    EEM             1x1
Repair_Status       Repair status       m^3/0.001sec         Agent model     4x1
----------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------
Output name        Physical meaning        Location        Unit                 Structure                                       Size 
-------------------------------------------------------------------------------------------------------------------------------------
U1                 Displacement            Node             m                   [u1x;u1y;u1z;u2x;u2y;u2z..unx;uyn;uz1;...]      90x1
                                                                                unx=displacement along x at node n
Vel1               Velocity                Node             m/s                                 ||                              90x1
Acc1               Acceleration            Node             m/s^2                               ||                              90x1
Damage_Status_O    Damage                  Gauss point      VL/VO               [D1;D2..;Dgp;...]                               324x4
                                                            VL=Volume lost      Dgp=Damage at gauss point gp
                                                            VO=Volume original
D_EqO              Damage (Matrix form)    Gauss point      VL/VO               [Dij]:i=element no i, j=Gauss point j           27x12
-------------------------------------------------------------------------------------------------------------------------------------


_______________________________________________________________________________
                  5. Method of extracting variable from SMM

For extraction, you may follow these steps:
    1. Create a Matlab function that includes the code with Input and Output
    2. Drag and link the desired variable from SMM to the Input of the Function block
    3. Drag and link the Output of the Function block to "To Workspace" or "Scope" block

Codes:
------------------------------------------------------------------------------------------------------------
Variable extraction                         Code                                        Size         Comment
------------------------------------------------------------------------------------------------------------
Displacement along x (for all nodes)        U1(1:3:end-2,1)                             30x1
Displacement along y (for all nodes         U1(2:3:end-1,1)                             30x1
Displacement along z (for all nodes         U1(3:3:end-0,1)                             30x1

Displacement along x at node n              U1(n*3-2,1)                                  1x1          n<=30
Displacement along y at node n              U1(n*3-1,1)                                  1x1          n<=30
Displacement along z at node n              U1(n*3-0,1)                                  1x1          n<=30

Velocity along y at node n                  Vel1(n*3-1,1)                                1x1          n<=30
Acceleration along y at node n              Acc1(n*3-1,1)                                1x1          n<=30

Damage information of element e             Damage_Status_O(27*(e-1)+1,27*e,1)          27x1          e<=12
Damage at Gauss point gp                    Damage_Status_O(gp,1)                        1x1          gp<=324

Lost volume at Gauss point gp of element e  D_EqO(gp,e)*(dJB(gp,e)*W(gp,Type(1,e)))      1x1          g<=324
------------------------------------------------------------------------------------------------------------


