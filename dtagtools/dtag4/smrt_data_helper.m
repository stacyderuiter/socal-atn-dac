depid = 'gm18_107a' ;
recdir=(['d:\' depid(1:4) '\' depid]) ;
ncname = [depid 'sens5']
X=d3readswv_commonfs(recdir,depid,5);		% have to do this first to make cuetab
info = make_info(depid,'SM',depid(1:2),'ra') ;
info.dephist_deploy_method = 'pin' ;
info.dephist_deploy_locality = 'Hawaii' ;
info.project_name = 'SMRT' ;
info.device_serial_alt = '17U3166' ;
info.depid_alt = '17U3166_SMRT1_04MAY2018' ;

[S,fields] = combine_csv(recdir,depid);
tp=etime(datevec(S(:,1)),repmat(get_start_time(info),size(S,1),1))+S(:,2)/1e6;  % seconds since tag on
% interpolate dive depth and temperature to regular sampling interval
fsp = 0.5 ;
t=(0.5/fsp:1/fsp:max(tp))';
p=interp1(tp,S(:,4),t);
tt=interp1(tp,S(:,5),t);
T = sens_struct(tt,fsp,depid,'temp') ;	% temperature
P = sens_struct(p,fsp,depid,'press') ;	% pressure
CAL = d4findcal(recdir,depid);

plott(P)    % plot dive profile

% if there is an offset or temperature effect in the pressure, do the following
[P,pc]=fix_pressure(P,T,2);
save_nc(ncname,info,P,T);

A = sens_struct([X.x{1:3}],X.fs(1),depid,'acc') ;	% acceleration
M = sens_struct([X.x{4:6}],X.fs(4),depid,'mag') ;	% magnetometer

Ac = auto_cal_acc(A,CAL.ACC);
% if Ac is acceptable, replace A:
A = Ac ;
add_nc(ncname,A);
J = d3rmsjerk(recdir,depid,CAL.ACC.poly,5);
add_nc(ncname,J);

Td=interp2length(T,M);
Pd=interp2length(P,M);
cal = CAL.MAG ; cal.poly = [1 0;1 0;1 0] ;

if length(X)==7,		% if there is an internal temperature channel (2019 tags)
	Tint=sens_struct(X.x{7}*4096+15,X.fs(7),depid,'temp');
	Tint.name = 'Tint' ;
	Tint.description='internal temperature from LIS44' ;
	add_nc(ncname,Tint);
	[Mc,cal1]=auto_cal_mag(M,cal,35,[Td.data Td.data Tint.data Pd.data/100],[60 600 0 0]);
	Mc.cal_tsrc='T,T,Tint,P/100' ;
else  % otherwise, approximate internal temperature by slowing down external temperature
	[Mc,cal1]=auto_cal_mag(M,cal,35,[Td.data Td.data Td.data Pd.data/100 sqrt(Pd.data/100)],[300 60 800 0 0]);
	Mc.cal_tsrc='T,T,T,Tsq,P/100,(T-20).^2' ;
end

% if Mc is acceptable, replace M:
M = Mc ;
add_nc(ncname,M);

PRH = prh_predictor1(Pd,A,200);
% generate OTAB from PRH then...
OTAB(:,3:5)=OTAB(:,3:5)*pi/180;
Aa=tag2animal(A,OTAB) ;
Ma=tag2animal(M,OTAB) ;
add_nc(ncname,Aa);
add_nc(ncname,Ma);
