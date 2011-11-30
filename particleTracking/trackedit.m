% trackedit.m
% 
% function to "edit" tracks, keeping only those that 
%  -- span a minimal number of frames
%  -- have at least a minimal amount of variance (i.e. aren't stuck)
%
% input
%   objs -- 6-row linked object matrix, from nnlink_rp.m  (See that file,
%           im2obj_rp for object structure)
%   minNframes -- minimal number of frames (optional; can input during analysis)
%   minstd -- minimal standard deviation, px (optional; can input during analysis)
%
% output
%   objs_out -- tracks that are kept (at least minNframes)
% 
% Method:
% identify tracks
% identify max. track length (frames)
% plot tracks -- lines from startframe to endframe
% keep only tracks that span at least minNframes frames; renumber track ids
%
% Raghuveer Parthasarathy
% March 10, 2009
% last modified April 21, 2009


function [objs_out] = trackedit(objs, minNframes, minstd)

allids = objs(6,:);
utrk = unique(allids);  % all the unique track ids

startframe = min(objs(5,:));  % minimal frame #
endframe = max(objs(5,:));  % maximal frame #
maxNframes = endframe - startframe;

if (nargin<2)
    minNframes = [];
    minstd = [];
elseif (nargin < 3)
    minstd = [];
end

if or((nargin < 2), isempty(minNframes))
    minNframes = maxNframes;  % user will assign later
    plotoptN = true;
else
    plotoptN = false;
end

if or((nargin < 3), isempty(minstd))
    minstd = 0.0;  % user will assign later
    plotoptV = true;
else
    plotoptV = false;
end

% --------------------------------------------------------------------
% Remove stuck tracks

stdtrk = zeros(1,length(utrk));
k=1;
for j = utrk
    % loop through each track
    trtmp = objs(:, allids==j);  % objects that are part of track j
    Nframej = size(trtmp,2);  % length of this track (frames)
    x = trtmp(1,:);  % all x positions
    x = x(~isnan(x));  
    y = trtmp(2,:);  % all y positions
    y = y(~isnan(y));
    stdtrk(k) = sqrt((var(x)+var(y))/Nframej);  
        % standard deviation of position, px per frame
    k = k+1;
end

if plotoptV
    [N, vx] = hist(stdtrk,round(length(utrk)/5));
    figure; semilogx(vx, N, 'ko');
    xlabel('standard deviation of position, pixels')
end

if ~(minstd > 0)
    minstd = input('Enter new standard dev. cutoff (px/frame): ');
end

objs_out1 = zeros(size(objs));  % the largest it could possibly be
k=1;  % for re-numbering tracks
nc = 1;  % number of columns, for re-sizing the array
progtitle = sprintf('trackedit: Editing tracks...  '); 
progbar = waitbar(0, progtitle);  % will display progress
for j=1:length(utrk)
    % loop through each track
    if stdtrk(j) >= minstd
        % keep this track
        trtmp = objs(:, allids==utrk(j));  % objects that are part of track j
        trtmp(6,:) = k;  % renumber track id
        objs_out1(:,nc:(nc+size(trtmp,2))-1) = trtmp; % keep these
        k = k+1;
        nc = nc + size(trtmp,2);
    end
    if (mod(j,100)==0)
        waitbar(j/length(utrk), progbar, progtitle);
    end
end
close(progbar)
fs = sprintf('Keeping %d out of %d tracks', k-1, length(utrk)); disp(fs);
objs_out1 = objs_out1(:,1:nc);  % "re-sizing" the array

% Recalculate...
allids = objs_out1(6,:);
utrk = unique(allids);  % all the unique track ids


% --------------------------------------------------------------------
% graph of track lengths

if plotoptN
    % For plotting "lines" of all tracks
    figure;
    axis([startframe endframe 0 max(utrk)]);
    xlabel('Frame');
    ylabel('Track id');
    hold on
    box on
    for j = utrk
        % loop through each track
        trtmp = objs_out1(:, ismember(objs_out1(6,:),j));  % objects that are part of track j
        plot([min(trtmp(5,:)) max(trtmp(5,:))], j*[1 1], '-', 'color', 0.3*mod(j,2)*[1 1 1]);
    end
end

if plotoptN
    disp('Pausing 2 seconds')
    pause(2)
end

% --------------------------------------------------------------------
% Remove short tracks (user input)

fs = sprintf('Cutoff frame no. = %d', minNframes'); disp(fs);
if plotoptN
    minNframes = input('Enter new cutoff (minimal number of frames): ');
end
objs_out = zeros(size(objs_out1));  % the largest it could possibly be
% oldminNframes = minNframes;
% if minNframes<0
%     minNframes = oldminNframes;
%     fs = sprintf('Cutoff frame no. = %d', minNframes'); disp(fs);
% end
k=1;  % for re-numbering tracks
nc = 1;  % number of columns, for re-sizing the array
progtitle = sprintf('trackedit: Editing tracks...  '); 
progbar = waitbar(0, progtitle);  % will display progress
for j = utrk
    % loop through each track
    Nframej = sum(allids==j);  % length of this track (frames)
    % Nframej = max(trtmp(5,:)) - min(trtmp(5,:));  % length of this track (frames)
    if Nframej >= minNframes
        % keep this track
        % trtmp = objs_out1(:, ismember(objs_out1(6,:),j));  % objects that are part of track j
        trtmp = objs_out1(:, allids==j);  % objects that are part of track j
        trtmp(6,:) = k;  % renumber track id
        objs_out(:,nc:(nc+size(trtmp,2))-1) = trtmp; % keep these
        k = k+1;
        nc = nc + size(trtmp,2);
    end
    if plotoptN
        c = 0.3*mod(j,2)*[1 1 1];  % for coloring
        plot([min(trtmp(5,:)) max(trtmp(5,:))], j*[1 1], '-', 'color', c);
    end
    if (mod(j,100)==0)
        waitbar(j/max(utrk), progbar, strcat(progtitle, sprintf('track %d of %d', j, max(utrk))));
    end
end
close(progbar)
fs = sprintf('Keeping %d out of %d tracks', k-1, length(utrk)); disp(fs);
objs_out = objs_out(:,1:nc);  % "re-sizing" the array


