function    FA = focal_follow_archive(depid, ffdir)

%    FA = sens_struct(depid)   % use default name
%
%    Generate a sound archive structure for a deployment.
%
%    Inputs:
%    depid is a string containing the deployment identifier.
%    ffdir is where the focal follow data files are located
%
%    Returns:
%    FA is a focal follow archive structure with metadata fields pre-populated. 
%		 Change these as needed to the correct values.
%
%
%    Valid: Matlab, Octave
%    markjohnson@st-andrews.ac.uk
%    sld33@calvin.edu
%    last modified: july 2021

FA = [] ;
if nargin < 1
   help focal_follow_archive
   return
end

X.depid = depid ;
X.type = 'ff_archive' ;
X.name = 'FA' ;
X.full_name = 'focal_follow_archive' ;
X.description = 'Focal follow archive listing' ;

files = dir([ffdir '/*.xlsx']) ;
all_cols = {} ; 
all_ff_data = table();
if isempty(files),
	fprintf('No focal follow files found in ffdir\n') ;
	return
else
    for f = [1:length(files)]
        ff_data = readtable([ffdir '/' files(f).name], 'VariableNamingRule', 'preserve') ;
        these_cols = ff_data.Properties.VariableNames ;
        all_cols = union(all_cols, these_cols) ;
        all_ff_data = [all_ff_data; ff_data];
    end
end

% doesn't work b/c cannot figure out how to write table as char
all_ff_data = convertvars(all_ff_data, all_ff_data.Properties.VariableNames, 'string') ;
all_ff_data = table2array(all_ff_data);
all_ff_data = convertStringsToChars(string(all_ff_data));

X.file_names = reshape([strvcat(files.name) repmat(',',length(files),1)]',1,[]) ;
X.file_number = length(files) ;
X.file_format = 'xlsx' ;
X.file_compression = 'none' ;
X.file_size = files.bytes ;
X.file_size_unit = 'bytes' ;
X.data = [] ;
SA.file_location = 'Cascadia Research Collective, 218 1/2 W 4th Ave., Olympia, WA 98501 USA; SEA, Inc., Aptos, CA 95003, USA';
SA.file_contact_email = 'calambokidis@cascadiaresearch.org, brandon.southall@sea-inc.net' ;
SA.file_contact_person = 'John Calambokidis , Brandon Southall';
SA.file_contact_url = 'https://www.cascadiaresearch.org/, https://sea-inc.net/';
X.file_url = '' ;
X.file_doi = '' ;
X.archive_status = 'complete' ;
X.sampling = 'irregular' ;
X.data_column_name = char(join(all_cols, ',')) ;
X.creation_date = datestr(now,'yyyy/mm/dd HH:MM:SS') ;
X.history = 'focal_follow_archive' ;
FA = orderfields(X) ;
