% This script loads spike data recorded on a 252-electrode array and parses
% them according drifiting grating stimuli of varying wavelength, speed, and
% direction.

% By Daniel Kerschensteiner 2019

%% LOADING FILES & DEFINING PATH FOR SAVING PARSED DATA
% load spike data from a txt file exported from Neuroexplorer
[fileName, pathName] = uigetfile('*.txt','Select TXT_ file');
sp = nexread2019([pathName fileName]);
clear fileName pathName

% load stimulus data
[fileName, pathName] = uigetfile('*.mat', 'Select STIM_ file');
load([pathName fileName])
clear fileName pathName
clc

%define directory and file name for saving parsed data
[fileName, pathName] = uiputfile('*.mat', 'Save Results As');

%% IDENTIFYING RELEVANT TTL PULSES
analogCh = [1 2]; %these channels contain timestamps from TTL pulses marking different stimuli
analog = sp.data(:,analogCh);
firstTtl = find(analog(:,1) > 2980, 1, 'first'); %first timestamps of stimulus
lastTtl = find(analog(:,2) > firstTtl & analog(:,2) < 3990, 1, 'last'); %last timestamp of stimulus
ttls = analog(firstTtl:lastTtl,:);

%delete analog channels from spike data
sp = deletechannels (sp, analogCh);

%% USER-DEFINED ASSIGNMENTS
stimIn = DS_IN;
stimOut = DS_OUT;

%different stimulus directions
stimD = stimIn.direction;
dOrder = stimOut.direction';

%different stimulus speeds
stimS = stimIn.speed;
sOrder = stimOut.speed';

%different stimulus wavelengths (i.e., spatial pattern)
stimW = unique(sort(stimOut.wavelength(:)));
wOrder = stimOut.wavelength';

duration = stimIn.duration;
nRepeats = stimIn.nRepeats;
data = sp.data;
channel = sp.channels;
nChannels = size(data,2);

%% PARSING DATA
g = waitbar(0, 'channels...');
for h=1:nChannels
    ds(h).channel = channel(h); %#ok<*SAGROW>
    firstSpike = find(data(:,h) >= ttls(1,1), 1, 'first');
    lastSpike = find(data(:,h) <= ttls(end,2) & data(:,h) > 0, 1, 'last');
    if isempty(firstSpike) || isempty(lastSpike)
    else
        spikeTrain = data(firstSpike:lastSpike,h);
        for i=1:length(stimD)
            for j=1:length(stimS)
                for k=1:length(stimW)
                    stimIdx = find(dOrder==stimD(i) & sOrder==stimS(j) & wOrder==stimW(k));
                    for l=1:length(stimIdx)
                        if l==1
                            ds(h).drift(i,j,k).spikes =...
                                spikeTrain( spikeTrain >= ttls(stimIdx(l),1) &...
                                spikeTrain <= ttls(stimIdx(l),2) ) - ttls(stimIdx(l),1);
                        else
                            ds(h).drift(i,j,k).spikes = [ds(h).drift(i,j,k).spikes; ...
                                spikeTrain( spikeTrain >= ttls(stimIdx(l),1) &...
                                spikeTrain <= ttls(stimIdx(l),2) ) - ttls(stimIdx(l),1)...
                                + (l-1)*duration];
                        end
                    end
                end
            end
        end
    end
    waitbar(h/nChannels, g)
end
save([pathName fileName], 'ds', 'stimD', 'stimS', 'stimW', 'duration',...
    'nRepeats', 'stimIn', 'stimOut')
close (g)
