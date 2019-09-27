function sp = nexread2019(filename)
% script for importing spike data from txt file

fid = fopen(filename, 'rt');

% Read strings between tabs one at a time until something that is not a label is
% encountered. Once one is found, back up.
nchan=1;
channames{nchan}=fscanf(fid,'%s\t',1);
% Check whether the last read matches a known label format.
while isempty(str2num(channames{nchan})) %#ok<*ST2NM>
    nchan=nchan+1;
    % Keep the current file position in case the next read is not a label.
    lastpos=ftell(fid);
    channames{nchan}=fscanf(fid,'%s\t',1);
end

% Hack for new Matlab.
lastpos=lastpos+1;

% The last read was not a label. Back up and drop the last read result.
fseek(fid, lastpos, 'bof');
nchan=nchan-1;
channames=channames(1:end-1);
sp.channels = channames;

%import options
opts = delimitedTextImportOptions('NumVariables', nchan);
opts.DataLines = [2, Inf];
opts.Delimiter = "\t";
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts = setvartype(opts,'double');

% Import the data
data = readtable(filename, opts);

% Convert to output type
data = table2array(data);
data(isnan(data)) = -1;
sp.data = data;

sp.nchan=nchan;
sp.x = zeros(1,nchan);
sp.y = zeros(1,nchan);
for i=1:nchan
    tmpChan = sp.channels{i};
    sp.x(i) = tmpChan(regexp(tmpChan,'[A-Z]')) - 64;
    if sp.x(i) > 10 && sp.x(i) < 17
        sp.x(i) = sp.x(i) - 1;
    elseif sp.x(i) > 17
        sp.x(i) = sp.x(i) - 2;
    else
    end
    sp.y(i) = str2double(tmpChan(regexp(tmpChan,'[0-9]')));
end