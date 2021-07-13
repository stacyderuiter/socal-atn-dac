DEV = struct ;
DEV.ID='1D03191D'; % Needs to be upper case
DEV.NAME='D115';
DEV.BUILT=[2012 7 1];
DEV.BUILDER='TH';
DEV.HAS={'stereo audio'};
BBFILE = ['badblocks_' DEV.ID(1:4) '_' DEV.ID(5:8) '.txt'] ;
try,
   DEV.BADBLOCKS = readbadblocks(['c:/mystuff/d3/host/d3usb/' BBFILE]) ;
catch,
   fprintf(' No bad block file\n') ;
end

TEMPR = struct ;
TEMPR.TYPE='ntc thermistor';
TEMPR.USE='conv_ntc';
TEMPR.UNIT='degrees Celcius';
TEMPR.METHOD='none';

BATT = struct ;
BATT.POLY=[6 0] ;
BATT.UNIT='Volt';

PRESS=struct;
PRESS.POLY=[83.83 3021.82 -133.33];
PRESS.METHOD='rough';
PRESS.LASTCAL=[2012 8 6];
PRESS.TREF = 20 ;
PRESS.UNIT='meters H20 salt';
PRESS.TC.POLY=[0];
PRESS.TC.SRC='BRIDGE';
PRESS.BRIDGE.NEG.POLY=[3 0];
PRESS.BRIDGE.NEG.UNIT='Volt';
PRESS.BRIDGE.POS.POLY=[6 0];
PRESS.BRIDGE.POS.UNIT='Volt';
PRESS.BRIDGE.RSENSE=200;
PRESS.BRIDGE.TEMPR.POLY=[314.0 -634.7] ;
PRESS.BRIDGE.TEMPR.UNIT='degrees Celcius';

ACC=struct;
ACC.TYPE='MEMS accelerometer';
ACC.POLY=[-4.983 2.453; 4.889 -2.450; 4.989 -2.471] ;
ACC.UNIT='g';
ACC.TREF = 20 ;
ACC.TC.POLY=[0; 0; 0]; % added colons % added .POLY
ACC.PC.POLY=[0; 0; 0]; % added colons % added .POLY
ACC.PC.SRC = 'PRESS'; % added
ACC.XC=zeros(3);
ACC.MAP=[1 0 0;0 -1 0;0 0 1];
ACC.MAPRULE='front-right-down';
ACC.METHOD='flips';
ACC.LASTCAL=[2012 8 6];

MAG=struct;
MAG.TYPE='magnetoresistive bridge';
MAG.POLY=[700.122 -170.574; 633.874 -180.836; 635.240 -152.965] ;
MAG.UNIT='Tesla';
MAG.TREF = 20 ;
MAG.TC.POLY=[0;0;0];
MAG.TC.SRC='BRIDGE';
MAG.PC.POLY=[0;0;0]; % Added .POLY
MAG.PC.SRC = 'PRESS'; % Added
MAG.XC=zeros(3);
MAG.MAP=[0 1 0;1 0 0;0 0 1]; % Corrected
MAG.MAPRULE='front-right-down';
MAG.METHOD='';
MAG.LASTCAL=[2012 8 6];
MAG.BRIDGE.NEG.POLY=[3 0];
MAG.BRIDGE.NEG.UNIT='Volt';
MAG.BRIDGE.POS.POLY=[6 0];
MAG.BRIDGE.POS.UNIT='Volt';
MAG.BRIDGE.RSENSE=20;
MAG.BRIDGE.TEMPR.POLY=[541.91 -459.24] ;
MAG.BRIDGE.TEMPR.UNIT='degrees Celcius';

CAL=struct ;
CAL.TEMPR=TEMPR;
CAL.BATT=BATT;
CAL.PRESS=PRESS;
CAL.ACC=ACC;
CAL.MAG=MAG;

DEV.CAL = CAL ;
writematxml(DEV,'DEV','d115.xml')

