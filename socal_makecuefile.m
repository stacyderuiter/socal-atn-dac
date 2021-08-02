function    cuefname = socal_makecuefile(recdir,prefix,suffix)
%
%    cuefname = makecuefile(recdir,prefix,suffix)
%     Forms a cue file 
%     Suffix can be 'wav' (the default) or 'swv' or any other suffix
%     assigned to a wav-format configuration.
%     Called by d2getcues.
%
%     markjohnson@st-andrews.ac.uk
%     Licensed as GPL, 2013
%     sld33@calvin.edu, july 2021, dtag2 version for SOCAL

cuefname = [] ;
if nargin<3 || isempty(suffix),
   suffix = 'wav' ;
end

[cuetab,ref_time, fs, fn, recdir] = d2getwavcues(recdir,prefix,suffix) ;
if isempty(cuetab)
   return ;
end

tempdir = gettempdir ;
cuefname = [tempdir '_' prefix suffix 'cues.mat'] ;

% ref time is time of 1st sample in the deployment
ctimes = (cuetab(:,2)-cuetab(1,2))+(cuetab(:,3)-cuetab(1,3))*1e-6 ;
cuetab = [cuetab(:,1) ctimes cuetab(:,4:5)] ;
vers = d3toolvers() ;

vv = version ;
if vv(1)>'6',
   save(cuefname,'-v6','ref_time','fn','fs','cuetab','recdir','vers') ;
else
   save(cuefname,'ref_time','fn','fs','cuetab','recdir','vers') ;
end

return
