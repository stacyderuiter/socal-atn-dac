function    [S,fields] = combine_csv(recdir,prefix,suffix)
%
%    [S,fields] = combine_csv(recdir,prefix,suffix)
%     or
%    [S,fields] = combine_csv(recdir,prefix,suffix)
%
%     Combine time-series data from a set of CSV files. Each file must
%		contain the same number of columns and the first column must be
%		either a number or a date/time string. The other columns should only 
%		contain numbers.
%     The first line of the file can optionally be a header containing names
%     for the fields. If the first character of the first line is a number,
%     it is assumed that there is no header.
%     Inputs
%     recdir is the path to the directory containing the preprocessed
%      observations (files ending with gps.mat).
%     prefix is the shared first part of the file names, e.g., for
%      files called hs16_265bnnn.csv (where nnn is a three digit
%      number), the prefix would be 'hs16_265b'.
%     suffix is the end part of the file names after the decimal point. If
%      suffix is not specified, 'csv' is assumed.
%
%     Outputs
%     S is a matrix containing the combined file numeric contents. S has a
%      column for each field in the files.
%     fields is a cell array of field names taken from the header of the
%      files if there is one. If no header is found, fields is empty.
%
%		Note: to convert Dtag3/4 time numbers into Matlab time numbers use
%				T = datenum(d3datevec(S(:,1))) ;
%
%     markjohnson@st-andrews.ac.uk
%     Last modified: 9 May 2019
%			Added support for numeric-only CSV files e.g., vlog and tlog files.
%        5 June 2019, fixed small bugs

S = [] ; fields = [] ;

if nargin<3,
   suffix = 'csv' ;
end

if ~exist(recdir,'dir'),
   fprintf(' No directory %s\n', recdir) ;
   return
end

if length(recdir)>1 & ismember(recdir(end),['/','\']),
   recdir = recdir(1:end-1) ;
end

recdir = [recdir,'/'] ;       % use / for MAC compatibility
recdir(recdir=='\') = '/' ;
sp = [recdir,prefix,'*.' suffix] ;
ff = dir(sp) ;

if isempty(ff),
   fprintf(' No files with names %s found\n',sp) ;
   return
end

fields = [] ;
for k=1:length(ff),
	fprintf(' Reading file %s\n',ff(k).name) ;
   vstart = 1 ;
	s = read_csv([recdir ff(k).name],-1) ;
   if any(isstrprop(s{1,1},'alpha')),
      [ss,fields] = read_csv([recdir ff(k).name],1) ;
      vstart = 2 ;
   end
   x = [] ;
   if ~isempty(findstr(s{vstart,1},':')),
   	try
      	x = datenum(strvcat(s{vstart:end,1}),'yyyy/mm/dd HH:MM:SS') ;
      catch
         fprintf(' Unable to convert date string in file %s\n',ff(k).name) ;
         return
      end
   end
   hstart = 1+size(x,2) ;
	for kcol=hstart:size(s,2),
		x(:,kcol) = str2num(strvcat(s{vstart:end,kcol})) ;
	end
   if isempty(S),
      S = x ;
   else
	   if size(x,2)~= size(S,2),
			fprintf(' File %s has incompatible number of columns. Skipping.\n',ff(k).name) ;
			continue
		end
      S(end+(1:size(x,1)),:) = x ;
   end
end
