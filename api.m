clear
remote_ip = '192.168.0.11';
sample_time = 1;
l_port = -1;
r_port = 10002;
fs = 1000;

% new protocol headers ⬇

src = 5;
dst = 1;
message_type = 1;
data_type = 0;
priority = 5;
physical_time = 33;
simulink_time = 33;
row = NaN;
col = NaN;
length = NaN;
option = 0;
flag = 0;
param = 3;
subparam = 0;
data = NaN;


header = [src,dst,message_type, data_type, priority, option,flag,param,subparam];