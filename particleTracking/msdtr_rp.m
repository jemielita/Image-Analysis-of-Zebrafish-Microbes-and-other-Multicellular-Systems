function msd = msdtr_rp(objs, fps, scale)
% msdtr : computes msds of tracks
%
% msd = msdtr(objs, ts)
%
% objs  : object matrix
% fps   : frame-rate (frames per second)
% scale : image scale, microns per pixel
%
% msd   : means square displacement matrix, stored thusly
% 
%    msd = {msd11, msd12, ... , msd21, ...;
%           std11, std12, ... , std21, ...;
%           tau11, tau12, ... , tau21, ...;
%           tr1,   tr1,   ... , tr2,   ...}
%   first index is track number, second is time-delay tau index
%   msd : mean mean-squared-displacement during the each time delay
%   std : standard deviation of msd during the each time delay
%   tau : the time step
%   tr  : the trackid, corresponding to the track id in objs.

% April 27, 2007
% Raghuveer Parthasarathy's commentary added to Andrew Demond's msdtr.m -- 
% The program calculates the mean-square displacement for each track for
% each "delay time" tau -- 1 frame, 2 frames, ..., N-1 frames, where N is
% the total number of frames for that track.
% 
% April 27, 2007
% Minor changes to program  -- RP
%    -- change second input from ts (timestamp vector) to fps (scalar
%    framerate, frames per second)
%    -- add third input, image scale (um/px)
%    -- avoid (incorrect?) use of i as index in both loops
%    -- avoid call to gettr to get track objects.
%
% May 15, 2007
% standard deviation incorporated
% August 2, 2007 -- error in time step corrected
% March 22, 2009 -- changed size of dtmp at initialization (minor fix)
% April 12, 2009 -- minor fix related to mean calculation
% September 21, 2009 -- minor fix to padvec
% Nov. 24, 2010 -- altered time output so first element is "1 frame," not 0

utrk = unique(objs(6,:));  % all the unique track ids
msd = [];

for i = utrk
    % loop through each track
    trtmp = objs(:, ismember(objs(6,:),i));  % objects that are part of track i
    if(size(trtmp,2) < 3)
        % skip tracks with < 3 pts
        continue;
    end
    msdtmp = zeros(4, size(trtmp, 2)-1);
    % What to do if the track is "lost" for some number of frames?  The
    % next two lines call the function nanpad (at the end of this .m file)
    % which fills in x and y from frames that are missing between the lowest and
    % highest frame numbers with NaN (not a number).  e.g. x info from 
    % frames 1 2 4 5 becomes x1 x2 NaN x4 x5.
    xtmp = nanpad(trtmp(1,:), trtmp(5,:));
    ytmp = nanpad(trtmp(2,:), trtmp(5,:));
    
    for j = 1:length(xtmp)-1
        dx = xtmp(1:end-j) - xtmp(1+j:end);
        %    e.g. if j=1, dx = [x_1-x_2 x_2-x_3 x_3-x_4 ... x_(N-1)-x_N ]
        %    e.g. if j=2, dx = [x_1-x_3 x_2-x_4 x_3-x_5 ... x_(N-2)-x_N ]
        dy = ytmp(1:end-j) - ytmp(1+j:end);
        dr = (dx.^2 + dy.^2)*scale*scale;  % dr has length N-i; units of um^2
        % we take the mean of the elements of dr that are not NaN, thus 
        % avoiding problems with lost frames
        if (sum(~isnan(dr)) > 0)
            msdtmp(1,j) = mean(dr(~isnan(dr)));
            msdtmp(2,j) = std(dr(~isnan(dr)));
        else
            msdtmp(1,j) = NaN;
            msdtmp(2,j) = NaN;
        end
    end
    ftmp = trtmp(5,1):trtmp(5,end);  % array of frame numbers
    msdtmp(3,:) = (ftmp(2:end)-ftmp(1))/fps;   % array of time steps, for N-1 frames
    msdtmp(4,:) = repmat(i, 1, size(msdtmp,2)); 
       % tile the value of i (i.e. the trackid) N-1 times
    msd = [msd msdtmp];
end



function padvec = nanpad(spvec, fmvec)
% pads spvec with NaNs based on fmvec

allfms = fmvec(1):fmvec(end);
padvec = NaN(size(allfms));
notmissing = ismember(allfms, fmvec); % find missing frames
padvec(notmissing) = spvec;
% padvec(padvec == 0) = NaN;  % No -- gives problems if padvec is really
%   supposed to have a zero value (e.g. in simulated noise-free data)!
