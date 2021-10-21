%         #=================================================#
%         #    Code developed for the RETH-Institute        #
%         #    By: Murali Krishnan Rajasekharan Pillai      #
%         #    PhD Student @ Purdue University              #
%         #    Funded by: NASA                              #
%         #    Last Modified: July 29, 2021                 #
%         #=================================================#
%         Purpose: Initializations for the socket APIs used for
%         communication between the Electro-Mechanical Systems and the
%         Health Management System applications.

%% Setup Communication
comms.Remote_IP = '127.0.0.1';
% base simulation time setp / freq
comms.dt_NRT_comm = 0.1; % secs
comms.fs_NRT_comms = 1/comms.dt_NRT_comm;
%% Send :: 1 SPG Dust FDD
comms.send.SPG.FDD_Dust.DBTableID = 1;
comms.send.SPG.FDD_Dust.LPORT = 30001;
comms.send.SPG.FDD_Dust.TOPORT = 10005;
comms.send.SPG.FDD_Dust.src=5;
comms.send.SPG.FDD_Dust.dest=1;
comms.send.SPG.FDD_Dust.type=0;
comms.send.SPG.FDD_Dust.prio=3;
comms.send.SPG.FDD_Dust.fsRatio = fs_3 / comms.fs_NRT_comms;
comms.send.SPG.FDD_Dust.PacketInfo= [...
        comms.send.SPG.FDD_Dust.src,  ...
        comms.send.SPG.FDD_Dust.dest, ...
        comms.send.SPG.FDD_Dust.type, ...
        comms.send.SPG.FDD_Dust.prio  ...
];

%% Send :: 2 ECLSS Dust FDD
comms.send.ECLSS.FDD_Dust.DBTableID = 2;
comms.send.ECLSS.FDD_Dust.LPORT = 30002;
comms.send.ECLSS.FDD_Dust.TOPORT = 10006;
comms.send.ECLSS.FDD_Dust.src = 6;
comms.send.ECLSS.FDD_Dust.dest = 1;
comms.send.ECLSS.FDD_Dust.type=0;
comms.send.ECLSS.FDD_Dust.prio=3;
comms.send.ECLSS.FDD_Dust.fsRatio = fs_5 / comms.fs_NRT_comms;
comms.send.ECLSS.FDD_Dust.PacketInfo = [...
            comms.send.ECLSS.FDD_Dust.src, ...
            comms.send.ECLSS.FDD_Dust.dest,...
            comms.send.ECLSS.FDD_Dust.type,...
            comms.send.ECLSS.FDD_Dust.prio ...
];



%% Send :: 3 ECLSS Paint FDD
comms.send.ECLSS.FDD_Paint.DBTableID = 3;
comms.send.ECLSS.FDD_Paint.LPORT = 30003;
comms.send.ECLSS.FDD_Paint.TOPORT = 10006;
comms.send.ECLSS.FDD_Paint.src = 6;
comms.send.ECLSS.FDD_Paint.dest = 1;
comms.send.ECLSS.FDD_Paint.type=0;
comms.send.ECLSS.FDD_Paint.prio=3;
comms.send.ECLSS.FDD_Paint.fsRatio = fs_5 / comms.fs_NRT_comms;
comms.send.ECLSS.FDD_Paint.PacketInfo = [...
            comms.send.ECLSS.FDD_Paint.src, ...
            comms.send.ECLSS.FDD_Paint.dest, ...
            comms.send.ECLSS.FDD_Paint.type, ...
            comms.send.ECLSS.FDD_Paint.prio
];

%% Send :: 4 Structure Impact FDD
comms.send.Str.FDD_Dmg.DBTableID = 4;
comms.send.Str.FDD_Dmg.LPORT = 30004;
comms.send.Str.FDD_Dmg.TOPORT = 10004;
comms.send.Str.FDD_Dmg.src=4;
comms.send.Str.FDD_Dmg.dest=1;
comms.send.Str.FDD_Dmg.type=0;
comms.send.Str.FDD_Dmg.prio=3;
comms.send.Str.FDD_Dmg.fsRatio = fs_2 / comms.fs_NRT_comms;
comms.send.Str.FDD_Dmg.PacketInfo = [...
            comms.send.Str.FDD_Dmg.src, ...
            comms.send.Str.FDD_Dmg.dest,...
            comms.send.Str.FDD_Dmg.type,...
            comms.send.Str.FDD_Dmg.prio
];

%% Send :: 5 NPG Dust FDD
comms.send.NPG.FDD_Dust.DBTableID = 5;
comms.send.NPG.FDD_Dust.LPORT = 30005;
comms.send.NPG.FDD_Dust.TOPORT = 10005;
comms.send.NPG.FDD_Dust.src=5;
comms.send.NPG.FDD_Dust.dest=1;
comms.send.NPG.FDD_Dust.type=0;
comms.send.NPG.FDD_Dust.prio=3;
comms.send.NPG.FDD_Dust.fsRatio = fs_3 / comms.fs_NRT_comms;
comms.send.NPG.FDD_Dust.PacketInfo = [...
            comms.send.NPG.FDD_Dust.src, ...
            comms.send.NPG.FDD_Dust.dest,...
            comms.send.NPG.FDD_Dust.type,...
            comms.send.NPG.FDD_Dust.prio
];

%% Send :: 6 Agents and Command & Control
comms.send.Agent.DBTableID = 6;
comms.send.Agent.LPORT = 30000;
comms.send.Agent.TOPORT = 10002;
comms.send.Agent.src=2;
comms.send.Agent.dest=1;
comms.send.Agent.type=0;
comms.send.Agent.prio=3;
comms.send.Agent.fsRatio = fs_6 / comms.fs_NRT_comms;
comms.send.Agent.PacketInfo = [...
            comms.send.Agent.src, ...
            comms.send.Agent.dest, ...
            comms.send.Agent.type, ...
            comms.send.Agent.prio
];

%% Receive :: 1 Agents and Command & Control
comms.recv.Agent.nD1=1;
comms.recv.Agent.LPORT = 10012; % hard-coded in Simulink
% comms.recv.Agent.LPORT = 30012; % as by default