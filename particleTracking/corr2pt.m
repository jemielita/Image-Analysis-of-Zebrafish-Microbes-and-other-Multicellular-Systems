% corr2pt.m
% 
% Program to perform two-point correlations on tracked object data.
% Input: objs, a linked object matrix, for example output by 
%        nnlink_rp.m and de-drifted be dedrift.m.
%        Using Andrew Demond's data structure forms
%        Each column of objs has the form
%                [    x;
%                     y;
%                     mass; 
%                     particleid; 
%                     frame; 
%                     trackid      ]
%        The function *can* deal with missing frames in any track of the
%        object matrix.  Inserts NaNs into missing frame coordinates, and
%        removes these after calculations.  (17 June 2007)
% Input:  scale -- image scale, microns / pixel
% Input:  fps -- image frame rate, frames / seconds
% Input:  maxtau -- maximum delay time to consider (frames).  Leave empty
%         ("[]") to consider all possible delays
% Input:  cutoff -- use only this fraction of the total possible delay times,
%         values, since larger tau are under-sampled.  See msdanalyze_rp.m, and
%         Saxton 1997. Recommend: cutoff = 0.25.  Uses whichever is
%         shorter: maxtau or cutoff*Noverlap
% Input:  Nmin -- consider only tracks with >Nmin points.  (Enforced: Nmin
%         must be at least 3)
% Input:  Rbins -- 1D array of bin centers, microns, for binning correlation data.
%               NOTE: values < min bin and > max bin will be in extremal bins
%               Recommend logarithmically spaced bin centers (e.g. using
%               "logspace")
% Input:  taubins -- 1D array of bin centers, seconds, for binning correlation data.
%               NOTE: values < min bin and > max bin will be in extremal bins
%
% Output:  Dpar, Dperp -- each is an array of binned correlation values.
%    Format:  D = [D(R1, tau1)  D(R1, tau2) ... D(R1, tauM);
%                  D(R2, tau1)  D(R2, tau2) ... D(R2, tauM);
%                  ...
%                  D(RN, tau1)  D(RN, tau2) ... D(RN, tauM)];
%
% Raghuveer Parthasarathy
% May 3, 2007
% last modified August 2, 2007
%
% Warnings:  Frame numbers for each track in objs must be increasing
% with column number.  (This is very unlikely to be a problem, if objs
% comes from nnlink_rp.m
%


function [Dpar Dperp] = ...
    corr2pt(objs, scale, fps, maxtau, cutoff, Nmin, Rbins, taubins)

if isempty(maxtau)
    % consider available delay times
    maxtau = 9e99;
end
Nmin = max(Nmin, 3); %  Nmin must be at least 3


% make sure Rbins, taubins are a row vectors
if (size(Rbins,2)<size(Rbins,1))
    Rbins = Rbins';
end
if (size(taubins,2)<size(taubins,1))
    taubins = taubins';
end


% Loop through each track; make a new object matrix -- 4 rows only, omitting
%   "mass" and "particleID" -- that keeps only tracks with >Nmin points
%   and pads missing x and y values (skipped frames) with NaN.
utrk = unique(objs(6,:));  % all the unique track ids
Ntracksorig = length(utrk);
k=1;
progtitle = sprintf('corr2pt Part1: padding object matrix with NaN...  '); 
progbar = waitbar(0, progtitle);  % will display progress
for j = utrk
    trtmp = objs(:, ismember(objs(6,:),j));  % objects that are part of track j
    if(size(trtmp,2) > Nmin)
        % skip tracks with < 3 pts
        % What to do if the track is "lost" for some number of frames?  The
        % next two lines call the function nanpad (at the end of this .m file)
        % which fills in frame numbers that are missing between the lowest and
        % highest frame numbers with NaN (not a number).  e.g. 1 2 4 5 becomes
        % 1 2 NaN 4 5.
        frtmp = min(trtmp(5,:)):max(trtmp(5,:));
        Nf = length(frtmp);
        xtmp = nanpad(trtmp(1,:), trtmp(5,:));
        ytmp = nanpad(trtmp(2,:), trtmp(5,:));
        newobjs(:,k:k+Nf-1) = [xtmp; ytmp; frtmp; repmat(j,1,Nf)];
        k = k+Nf;
    end
    waitbar(k/(size(objs,2)), progbar, progtitle);  % Approximate
end
close(progbar)
    
% Make an array "tracks" -- each column contains 
%                [trackid; 
%                 startframe; 
%                 endframe]
utrk = unique(newobjs(4,:));  % all the unique track ids (sorted)
Ntracks = length(utrk);
fs = sprintf('%d good tracks out of %d total', Ntracks, Ntracksorig); disp(fs)
tracks = zeros(3,length(utrk)); % preallocate memory for tracks array
for j=1:length(utrk),
    jframes = newobjs(3,newobjs(4,:)==utrk(j)); % frames corresponding to this track
    tracks(:,j) = [utrk(j); min(jframes); max(jframes)];
end
goodtracks = tracks(1,:);   % the good track numbers


% Dmat = [];
Dpar = zeros(length(Rbins),length(taubins));
Dperp = zeros(length(Rbins),length(taubins));
Npar = zeros(length(Rbins),length(taubins));
Nperp = zeros(length(Rbins),length(taubins));
maxR = 0.0;  % extremal value; initialize to be very small 
maxtausec = 0.0;  
minR = 1/eps;  % extremal value; initialize to be very large
mintausec = 1/eps;  
progtitle = sprintf('Correlations... APPROX progress '); 
progbar = waitbar(0, progtitle);  % will display progress
% Examine each pair of tracks
for j=goodtracks(1:Ntracks-1)
    for k = goodtracks(goodtracks > j)  % tracks > j
        % Now we have a pair of tracks, j and k.
        % Find overlapping frames of the two tracks
        startjk = max(tracks(2,tracks(1,:)==j), tracks(2,tracks(1,:)==k));
        endjk   = min(tracks(3,tracks(1,:)==j), tracks(3,tracks(1,:)==k));
        if (endjk>startjk)
            Noverlap = endjk - startjk + 1;
        else
            Noverlap = 0;
        end
%         fs = sprintf('Tracks %d and %d: %d frames overlap', ...
%             j, k, Noverlap); disp(fs);
        if (Noverlap > 1)
            % At least two overlapping frames; we can correlate these two tracks
            % Using the object positions of the overlapping frames, get
            % x and y positions of the overlapping tracks
            alljk = startjk:endjk;  % All frames, including missing ones
            colj = (newobjs(4,:)==j)&(ismember(newobjs(3,:),alljk));
                   % columns of newobjs that correspond to track j and
                   % frames between startjk and endjk
            colk = (newobjs(4,:)==k)&(ismember(newobjs(3,:),alljk));
            trackjx = newobjs(1,colj);
            trackjy = newobjs(2,colj);
            % Fill elements corresponding to missing frames with NaN
            trackkx = newobjs(1,colk);
            trackky = newobjs(2,colk);
                % trackjx = [x1  x2  x3 ... xN]

            % Now examine correlations -- various delays, tau
            for tau=1:min(cutoff*(Noverlap-1), maxtau)
                % All of the delay=tau pairs for this pair of tracks:
                dxj = trackjx(1:end-tau) - trackjx(1+tau:end);
                dyj = trackjy(1:end-tau) - trackjy(1+tau:end);
                % e.g. if tau=1, dx = [x_1-x_2 x_2-x_3 x_3-x_4 ... x_(N-1)-x_N ]
                dxk = trackkx(1:end-tau) - trackkx(1+tau:end);
                dyk = trackky(1:end-tau) - trackky(1+tau:end);
                % All of the initial track separations for this pair
                Rx = trackjx(1:end-tau) - trackkx(1:end-tau);
                Ry = trackjy(1:end-tau) - trackky(1:end-tau);
                % e.g. if tau=1, Rx = [xj1-xk1 xj2-xk2 ... xj(N-1)-xk(N-1) ]
                % e.g. if tau=2, Rx = [xj1-xk1 xj2-xk2 ... xj(N-2)-xk(N-2) ]
                magR = sqrt(Rx.*Rx + Ry.*Ry);  % magnitude of R
                nx = Rx./magR;  % unit vector component
                ny = Ry./magR;  % unit vector component
                % Component Parallel to R
                drj_par = dxj.*nx + dyj.*ny;
                drk_par = dxk.*nx + dyk.*ny;
                % Component Perpendicular to R (parallel to [-Ry,Rx])
                drj_perp = -dxj.*ny + dyj.*nx;
                drk_perp = -dxk.*ny + dyk.*nx;
                
                % "Final" results, in physical units
                % Each of these is an array, of length N-tau, except tausec
                R = magR*scale; % R, microns
                tausec = tau/fps; % tau, seconds
                Dpar_temp  = (drj_par.*drk_par)*scale*scale;
                   % this has length N-tau, units of um^2
                Dperp_temp = (drj_perp.*drk_perp)*scale*scale;
                   % this has length N-tau, units of um^2
                % Clean up any NaNs from missing frames
                goodD = (~isnan(Dpar_temp))&(~isnan(Dperp_temp));
                R = R(goodD); % R, microns
                Dpar_temp = Dpar_temp(goodD);
                Dperp_temp = Dperp_temp(goodD);
                
                % Determine R and tau bins for running sums.  Need to
                % consider each R of the overlapping pairs separately,
                % since they may differ.
                repR = repmat(R,length(Rbins),1);
                repRbin = repmat(Rbins', 1, length(R));
                [junkR, whichR] = min((repR - repRbin).*(repR - repRbin));
                % whichR is a vector that contains the index no. of Rbin to
                % which each  D value should correspond.  Note: likely to
                % contain many non-unique numbers!
                [uniqwR] = unique(whichR);
                uniqDpar_temp = zeros(1,length(uniqwR));
                uniqDperp_temp = zeros(1,length(uniqwR));
                nuniq = zeros(1,length(uniqwR));
                for kk=1:length(uniqwR),
                    w = (whichR==uniqwR(kk));
                    uniqDpar_temp(kk) = sum(Dpar_temp(w));
                    uniqDperp_temp(kk) = sum(Dperp_temp(w));
                    nuniq(kk) = sum(w);
                end
                % tau is a single number, which applies to all values in
                % this loop, so we don't need a matric to find which bin it
                % lies in
                difftau = tausec - taubins;
                [junktau, whichtau] = min(abs(difftau));
                Dpar(uniqwR, whichtau) = Dpar(uniqwR, whichtau) + uniqDpar_temp';
                Dperp(uniqwR, whichtau) = Dperp(uniqwR, whichtau) + uniqDperp_temp';
                Npar(uniqwR, whichtau) = Npar(uniqwR, whichtau) + nuniq';
                Nperp(uniqwR, whichtau) = Nperp(uniqwR, whichtau) + nuniq';
                % Check what are the extremal values of R and tau
                % encountered, so the user knows if the input bins were ok
                maxtausec = max(tausec, maxtausec);  % whichever is higher
                mintausec = min(tausec, mintausec);  % whichever is lower
                if ~isempty(R)
                    maxR = max(max(R), maxR);  % whichever is higher
                    minR = min(min(R), minR);  % whichever is lower
                end
            end
        end
    end
    fs = sprintf('  Track %d of %d', j, max(goodtracks));
    waitbar(j/max(goodtracks), progbar, strcat(progtitle, fs)); % *very* Approximate
end
close(progbar)
% Calculate average values
% Note that array bins that were not filled in by any data points will have
% N = 0, and so will result in NaN for those elements
Dpar = Dpar./Npar;
Dperp = Dperp./Nperp;

% Check that bins were probably ok:
if (maxR > max(Rbins))
    fs = sprintf('WARNING: max R value found = %.3e -- greater than max bin center %.3e.', ...
        maxR, max(Rbins));
    disp(fs);
end
if (minR < min(Rbins))
    fs = sprintf('WARNING: min R value found = %.3e -- less than min bin center %.3e.', ...
        minR, min(Rbins));
    disp(fs);
end
if (maxtausec > max(taubins))
    fs = sprintf('WARNING: max tausec value found = %.3e -- greater than max bin center %.3e.', ...
        maxtausec, max(taubins));
    disp(fs);
end
if (mintausec < min(taubins))
    fs = sprintf('WARNING: min tausec value found = %.3e -- less than min bin center %.3e.', ...
        mintausec, min(taubins));
    disp(fs);
end




% --------------------------------------------------

function padvec = nanpad(spvec, fmvec)
% pads spvec with NaNs based on fmvec

allfms = fmvec(1):fmvec(end);
padvec = zeros(size(allfms));
notmissing = ismember(allfms, fmvec); % find missing frames
padvec(notmissing) = spvec;
padvec(padvec == 0) = NaN;
