function		info = socal_prh2nc(depid,owner,project,df, ncdir, recdir,  vars)

%		info = prh2nc(depid,owner,project,df,vars)
%		Convert a 'PRH' Matlab file for a DTAG deployment
%		into an nc file. This function generates an info
%		structure from any CAL information it can find and
%		then makes sensor structures for each variable in
%		the PRH file. The sampling rate and data are not
%		changed.
%		Inputs:
%		depid is a string containing the name of a tag 
%		  deployment e.g., ml18_290a
%		owner is a string containing the initials of the data
%		  owner or curator. These initials should correspond
%		  to a person identified in your user/researchers.csv file.
%		project is an optional string containing the name of
%		  a script with instructions to change/add fields to the
%		  info structure. For example, this could add deployment
%		  specific information such as the location and attachment
%		  method that are not in the original PRH or CAL files.
%       ncdir is the directory in which to save nc files. If not provided,
%       they are saved in the current working directory.
%       recdir is the directory where wav and swv files are found. if not
%       provided the current working directory is used.
%
%		markjohnson@st-andrews.ac.uk
%		31 Oct. 2019
%       sld33@calvin.edu
%       july 2021

loadprh(depid)

if nargin<4 || isempty(df),
   df = 1 ;
else
   df = round(df) ;
end
if df > 1, fs = fs/df ; end

if nargin < 5 || isempty(ncdir)
    ncdir = '';
end

if nargin < 6 || isempty(recdir)
    recdir = '';
end

if ~isempty(ncdir) && ~ismember(ncdir(end),'/\'),
   ncdir(end+1) = '/' ;
end

ncdir(ncdir=='\') = '/' ;      % use / for MAC compatibility

if ~isempty(recdir) && ~ismember(recdir(end),'/\'),
   recdir(end+1) = '/' ;
end

recdir(recdir=='\') = '/' ;      % use / for MAC compatibility

% fname = sprintf('%s%ssens%d.nc',ncdir,depid,round(fs)) ;
fname = sprintf('%s%s.nc',ncdir,depid) ;


if nargin < 7
   vars = [] ;
end

if dtagtype(depid, 1) == 3,
    try
        [CAL, DEPLOY] =  d3loadcal(depid) ;
       % TAGON = DEPLOY.TAGON ;
        if isstruct(TAGON)
            TAGLOC = TAGON.POSITION ;
           % TAGON = TAGON.TAGON ;
        end
        OTAB = DEPLOY.OTAB ;
        TAGID = DEPLOY.ID ;
        [CUETAB,ref_time,fs,fn,recdir,recn] = d3getcues(recdir,[depid(1:2), depid(6:9)],'swv') ;
        info = make_info(depid, 'D3', depid(1:2), owner) ;
        TAGON = d3datevec(ref_time) ;
    catch
        fprintf('Trying short depid without year...\n')
        try
            % some tagouts have short name without year on dtg files
            [CUETAB,ref_time,fs,fn,recdir,recn] = d3getcues(recdir,[depid(1:2), depid(6:9)],'swv');
            TAGON = d3datevec(ref_time) ;
            info = make_info([depid(1:2) depid(6:9)], 'D3', depid(1:2), owner) ;
            info.depid = depid ;
        catch
            fprintf('No cal file found for this deployment\n')
            return
        end
    end

elseif dtagtype(depid,1)==2,
	try
		loadcal(depid) ;
        % note: DTAG2 TAGON is in LOCAL time
        % should have CAL variable GMT2LOC or UTC2LOC for conversion
        if exist('GMT2LOC', 'var')
            UTC2LOC = GMT2LOC ;
        end
        if exist('UTC2LOC', 'var') && exist('TAGON', 'var')
            % convert from local to UTC
            TAGON(4) = TAGON(4) - UTC2LOC ; 
        else % assume socal in summer, so UTC2LOC = -7
            TAGON(4) = TAGON(4) + 7 ;
        end
	catch
		fprintf('No cal file for this deployment\n')
		return
	end
	info = make_info(depid,'D2',depid(1:2),owner) ;
else
	[c,TAGON,s,ttype,ffs,TAGID,wavfname,ndigits]=tagcue(0,depid);
	info = make_info(depid,'D1',depid(1:2),owner) ;
	CUETAB = [] ;
end

ton = datestr(TAGON(:)',info.dephist_device_regset) ;
info.dephist_deploy_datetime_start = ton ;
info.dephist_device_datetime_start = ton ;
if strcmp(info.device_serial, 'UNKNOWN') % make_info should add this, if not try to fetch from cal file
    try
        info.device_serial = TAGID ;
    catch
        info.device_serial = 'UNKNOWN' ;
    end
end
if exist('CUETAB','var') && ~isempty(CUETAB)
   if isstruct(CUETAB)
      CUETAB = CUETAB.N ;
   end
	info.dtype_nfiles = size(CUETAB,1) ;
	info.dtype_source = [] ;
	for k=1:size(CUETAB,1),
		fn = sprintf('%s%03d,',depid,CUETAB(k,1)) ;
		if k==size(CUETAB,1),
			fn = fn(1:end-1) ;
		end
		info.dtype_source(end+(1:length(fn))) = fn ;
	end
	info.dtype_source = char(info.dtype_source) ;
end
if exist('TAGLOC','var'),
	info.dephist_deploy_location_lat = TAGLOC(1) ;
	info.dephist_deploy_location_lon = TAGLOC(2) ;
end

if exist('p','var') && (isempty(vars) || any(strcmp('p',vars)))
    % can not do in project file b/c need sensor data to do it
    % generate ISO 8601 duration string
    % "ISO 8601 Durations are expressed using the following format, 
    % where (n) is replaced by the value for each of the date and time
    % elements that follow the (n): P(n)Y(n)M(n)DT(n)H(n)M(n)S
    %  aaaargh Matlab could you not have a function for this?
    % (should save this as one...)
    dur = length(p) / fs ;
    ml_dur = calendarDuration(0,0,0,0,0,dur); %matlab caldur object
    dur_time = strsplit(string(time(ml_dur)), ':') ;
    dur_string = join(string({'P', num2str(calyears(ml_dur)), 'Y', ...
        num2str(calmonths(ml_dur)), 'M',...
        num2str(caldays(ml_dur)), 'DT', ...
        num2str(str2double(dur_time(1))), 'H', ...
        num2str(str2double(dur_time(2))), 'M', ...
        num2str(str2double(dur_time(3))), 'S'}), '') ;
    info.time_coverage_duration =  dur_string;
    info.time_coverage_duration_seconds = num2str(dur) ;
end

if ~isempty(project),
	run(project)
end


save_nc(fname,info) ;

if exist('p','var') & (isempty(vars) | any(strcmp('p',vars))),
   if df>1, p = decdc(p,df) ; end
	P = sens_struct(p,fs,depid,'press') ;
	P.history = ['prh2nc,',P.history] ;
    P.deploy_ID = P.depid ;
	add_nc(fname,P) ;
end

if exist('tempr','var') & (isempty(vars) | any(strcmp('tempr',vars))),
   if df>1, tempr = decdc(tempr,df) ; end
	T = sens_struct(tempr,fs,depid,'temp') ;
	T.history = ['prh2nc,',T.history] ;
    T.deploy_ID = T.depid ;
	add_nc(fname,T) ;
end

if exist('A','var') & (isempty(vars) | any(strcmp('A',vars))),
   if df>1, A = decdc(A,df) ; end
	A = sens_struct(A*9.81,fs,depid,'acc') ;
	A.history = ['prh2nc,',A.history] ;
    A.deploy_ID = A.depid ;
    add_nc(fname,A) ;
end

if exist('M','var') & (isempty(vars) | any(strcmp('M',vars))),
   if df>1, M = decdc(M,df) ; end
	M = sens_struct(M,fs,depid,'mag') ;
	M.history = ['prh2nc,',M.history] ;
    M.deploy_ID = M.depid ;
    add_nc(fname,M) ;
end

if exist('Aw','var') & (isempty(vars) | any(strcmp('Aw',vars))),
   if df>1, Aw = decdc(Aw,df) ; end
	Aa = sens_struct(Aw*9.81,fs,depid,'acc') ;
	Aa.frame = 'animal' ;
	Aa.name = 'Aa' ;
	Aa.history = ['prh2nc,',Aa.history] ;
    Aa.deploy_ID = Aa.depid ;
    if exist('OTAB','var')
		Aa.otab = reshape(OTAB',1,[]) ;
	else
		Aa.otab = 'unknown' ;
	end
	add_nc(fname,Aa) ;
end

if exist('Mw','var') & (isempty(vars) | any(strcmp('Mw',vars))),
   if df>1, Mw = decdc(Mw,df) ; end
	Ma = sens_struct(Mw,fs,depid,'mag') ;
	Ma.frame = 'animal' ;
	Ma.name = 'Ma' ;
	Ma.history = ['prh2nc,',Ma.history] ;
    Ma.deploy_ID = Ma.depid ;
    if exist('OTAB','var')
		Ma.otab = reshape(OTAB',1,[]) ;
	else
		Ma.otab = 'unknown' ;
	end
	add_nc(fname,Ma) ;
end
