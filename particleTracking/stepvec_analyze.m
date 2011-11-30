function stepvec = stepvec_analyze(objs)
% stepvec_analyze : computes "steps" of tracks -- displacement and angle
% Framework based on RP's version of Andrew Demond's msdtr.m -- 
%
% Input
% objs  : object matrix
% Position in px (like objs); time in frames (like objs)
% 
%
% Output
% stepvec   : displacement matrix, stored thusly
% 
% stepvec = {d11, d12, d13, ... , d21, ...;
%               theta11, theta12, theta13, ... , theta21, ...;
%               fr11, fr12, fr13, ... , fr21, ...;
%               tr1,   tr1,  tr1, ... , tr2,   ...}
%   first index is track number, second is frame index (runs from 1 to N-1,
%      where N is the number of frames of the track)
%   dij : magnitude of the displacement of track i between frames j, j+1
%      (pixels)
%   thetaij : angle of the displacement of track i between frames j,
%     j+1 (radians) 
%   fr  : the frame number.  If the track is present for all frames, this 
%     will be [2 3 4 5 ... N], corresponding to the steps of frame 1-2, 
%     2-3, 3-4, etc.  If the track starts at frame 15 and ends at 38, for
%     example, this will be [16 17 ... 38]
%   tr  : the trackid, corresponding to the track id in objs. 
% 
% March 22, 2009
% Raghuveer Parthasarathy
% last modified April 12, 2009

utrk = unique(objs(6,:));  % all the unique track ids
stepvec = [];

for i = utrk
    % loop through each track
    trtmp = objs(:, ismember(objs(6,:),i));  % objects that are part of track i
    if(size(trtmp,2) < 3)
        % skip tracks with < 3 pts
        continue;
    end
    % What to do if the track is "lost" for some number of frames?  The
    % next two lines call the function nanpad (at the end of this .m file)
    % which fills in frame numbers that are missing between the lowest and
    % highest frame numbers with NaN (not a number).  e.g. 1 2 4 5 becomes
    % 1 2 NaN 4 5.
    xtmp = nanpad(trtmp(1,:), trtmp(5,:));
    ytmp = nanpad(trtmp(2,:), trtmp(5,:));
    dtmp = zeros(3, length(xtmp)-1); 
    
    dx = xtmp(2:end) - xtmp(1:end-1);  % dx = [x_2-x_1  x_3-x_2 ... x_N-x_(N-1)]
    dy = ytmp(2:end) - ytmp(1:end-1);  
    dtmp(1,:) = sqrt(dx.*dx + dy.*dy);
    dtmp(2,:) = atan2(dy,dx);  % angle, radians (-pi to pi)
    dtmp(3,:) = min(trtmp(5,:))+1:max(trtmp(5,:));  % frame number
    dtmp(4,:) = repmat(i, 1, size(dtmp,2)); 
       % tile the value of i (i.e. the trackid) N-1 times
    stepvec = [stepvec dtmp];
end

function padvec = nanpad(spvec, fmvec)
% pads spvec with NaNs based on fmvec

allfms = fmvec(1):fmvec(end);
padvec = zeros(size(allfms));
notmissing = ismember(allfms, fmvec); % find missing frames
padvec(notmissing) = spvec;
padvec(padvec == 0) = NaN;
