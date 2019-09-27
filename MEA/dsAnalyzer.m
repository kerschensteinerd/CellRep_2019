% This script uses as input the file saves from dsParser.m. It computes
% direction selectivity indices (dsi) and preferred stimulus directions
% (pref). It classifies cells as ds and non-ds.

% By Daniel Kerschensteiner 2019

%% LOAD DS_... file
[filename, pathname] = uigetfile ('*.mat', 'Select DS_... file');
load([pathname filename])

%% ASSIGNMENTS
rateThresh = 4; %minimum preferred firing rate for assessing DS status
dsiThresh = 0.3; %DSI threshold for identifying a cell as DSGC was 0.3
nDirs = 1; %number of directions indexed for preferred and null
sIdx = 1; %index of stimIn.speed used for determining preferred direction
wIdx = 2:3; %index in stimIn.wavelength for determining preferred direction
duration = stimIn.duration;
nRepeats = stimIn.nRepeats;
direction = stimIn.direction;
radDir = deg2rad(direction)';

%% ANALYZE AVERAGE FIRING RATES AND DIRECTION SELECTIVITY
nChannels = size(ds,2);
counter = 1;
if isempty(ds(counter).drift)
    while isempty(ds(counter).drift)
        counter = counter + 1;
    end
else
end
[nD, nS, nW] = size(ds(counter).drift);

for i=1:nChannels
    if ~isempty(ds(i).drift)
        for j=1:nW
            for k=1:nS
                for l=1:nD
                    ds(i).rate(l,k,j) = numel(ds(i).drift(l,k,j).spikes) / (duration * nRepeats); %#ok<*SAGROW>
                end
                circVar = sum(ds(i).rate(:,k,j) .* exp(1i*radDir)) /...
                    sum(ds(i).rate(:,k,j));
                ds(i).dsi(k,j) = abs(circVar);
                ds(i).pref(k,j) = rad2deg(unwrap(angle(circVar)));
            end
        end
    else
    end
end

%% IDENTIFY DSGCs
for i=1:nChannels
    if ~isempty(ds(i).drift)
        maxRate = squeeze(max(ds(i).rate));
        testIdx = maxRate > rateThresh;
        if isempty(testIdx)
            ds(i).type = 'non-DS';
        else
            avDS = mean(ds(i).dsi(testIdx));
            if avDS >= dsiThresh
                ds(i).type = 'DS';
                testPref = ds(i).pref(sIdx,wIdx);
                testPref = testPref(:);
                testRad = deg2rad(testPref);
                medRad = circ_median(testRad);
                medPref = rad2deg(medRad);
                if medPref < 0
                    medPref = 360 + medPref;
                else
                end
                prefDist = abs(direction - medPref);
                [~, sortIdx] = sort(prefDist);
                ds(i).prefIdx = sortIdx(1:nDirs);
                ds(i).nullIdx = mod(ds(i).prefIdx + round(nD/2),nD);
                if any(ds(i).nullIdx == 0)
                    ds(i).nullIdx(ds(i).nullIdx==0) = nD;
                else
                end
            else
                ds(i).type = 'non-DS';
            end
        end
    else
        ds(i).type = 'non-DS';
    end
end


%% SAVE RESULTS
save([pathname filename], 'ds', 'stimW', 'stimD', 'stimS', 'duration',...
    'nRepeats', 'stimIn', 'stimOut')

