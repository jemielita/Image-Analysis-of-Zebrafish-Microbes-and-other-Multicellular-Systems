% angleCorr_rp.m
%
% function to return the angular correlation function for tracks
% First use "stepvec_analyze.m" to get the frame-to-frame displacement
% 
% similar format to msdtr_rp.m
%
% Input: 
%   stepvec   : displacement matrix, created by stepvec_analyze.m
%       Row1 = displacement magnitude
%       Row2 = angle
%       Row3 = frame number.  If the track is present for all frames, this 
%         will be [2 3 4 5 ... N], corresponding to the steps of frame 1-2, 
%         2-3, 3-4, etc.  If the track starts at frame 15 and ends at 38, for
%         example, this will be [16 17 ... 38]
%       Row4 = track id
% fps   : frame-rate (frames per second)
%
% Output 
% thetacorr   : angular correlation matrix, stored thusly
%   thetacorr = {theta11, theta12, ... , theta21, ...;
%           std11, std12, ... , std21, ...;
%           tau11, tau12, ... , tau21, ...;
%           tr1,   tr1,   ... , tr2,   ...}
%   first index is track number, second is time-delay tau index
%   theta : normalized angular correlation (cos(theta)) during the each time delay
%   std : standard deviation of theta during the each time delay
%   tau : the time step
%   tr  : the trackid, corresponding to the track id in objs.
%
% Raghu Parthasarathy
% April 12, 2009
% Last modified: September 18, 2009 (deal better with NaN -- ignore for mean)

function thetacorr = angleCorr_rp(stepvec, fps) 


utrk = unique(stepvec(4,:));  % all the unique track ids
thetacorr = [];

if (nargin < 2)
    fps = 1;
end

progtitle = sprintf('Analyzing tracks...  '); 
progbar = waitbar(0, progtitle);  % will display progress
for i = utrk
    % loop through each track
	trtmp = stepvec(:,stepvec(4,:)== i);	% objects belonging to current track, i
    if(size(trtmp,2) < 3)
        % skip tracks with < 3 pts
        continue;
    end
    thetacorrtmp = zeros(4, size(trtmp, 2)-1);
    % What to do if the track is "lost" for some number of frames?  The
    % next line calls the function nanpad (at the end of this .m file)
    % which fills in frame numbers that are missing between the lowest and
    % highest frame numbers with NaN (not a number).  e.g. 1 2 4 5 becomes
    % 1 2 NaN 4 5.
    ttmp = nanpad(trtmp(2,:), trtmp(3,:));
    for k = 1:length(ttmp)-1
        dtheta = ttmp(1:end-k)-ttmp(1+k:end);
        % this dtheta is a 1D array. 
        % For k=1, it's [theta(1)-theta(2) theta(2)-theta(3) ... theta(N-1)-theta(N)]
        % For k=2, it's [theta(1)-theta(3) theta(2)-theta(4) ... theta(N-2)-theta(N)]
        goodt = ~isnan(dtheta);  % all the good elements
        if (sum(goodt) > 0)
%            thetacorrtmp(1,k) = mean(cos(dtheta));
%            thetacorrtmp(2,k) = std(cos(dtheta));
            thetacorrtmp(1,k) = mean(cos(dtheta(goodt)));
            thetacorrtmp(2,k) = std(cos(dtheta(goodt)));
        else
            thetacorrtmp(1,k) = NaN;
            thetacorrtmp(2,k) = NaN;
        end
                
    end
    ftmp = trtmp(3,1):trtmp(3,end);  % array of frame numbers
    thetacorrtmp(3,:) = (ftmp(2:end)-ftmp(2))/fps;   % array of time steps, for N-1 frames
    thetacorrtmp(4,:) = repmat(i, 1, size(thetacorrtmp,2)); 
       % tile the value of i (i.e. the trackid) N-1 times
    thetacorr = [thetacorr thetacorrtmp];
    waitbar(i/(max(utrk)), progbar, progtitle);
end
close(progbar)


function padvec = nanpad(spvec, fmvec)
% pads spvec with NaNs based on fmvec

allfms = fmvec(1):fmvec(end);
padvec = NaN(size(allfms));
notmissing = ismember(allfms, fmvec); % find missing frames
padvec(notmissing) = spvec;
% padvec(padvec == 0) = NaN;  % No -- gives problems if padvec is really
%   supposed to have a zero value (e.g. in simulated noise-free data)!
