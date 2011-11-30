% msdanalyze_rp.m
%
% For each track, plot the mean-squared displacements v. time and 
%    extract a diffusion coefficient
% input: 
%    msd -- see msdtr_rp.m for its format.  
%       msd(1,:) are the mean Dx^2 values -- um^2, if msdtr_rp is run with the
%       proper scale
%       msd(2,:) are the standard deviations of the Dx^2 values -- um^2
%       msd(3,:) are the time step values -- seconds, if msdtr_rp is run with the
%       proper framerate
%       msd(4,:) are the track ids
%    cutoff -- use only this fraction of the total tau values, since larger
%       tau are under-sampled.  See Saxton 1997. Recommend: cutoff = 0.25.
% if plotopt==1, plot msds
% 
% CALLS fityeqbx.m to fit Dx2 = 4*D*t, getting uncertainty in D also
% output:  D
%    D(1,:) are the diffusion coefficient values -- um^2/s, if proper scales
%    D(2,:) are the uncertainty (sigma_D) of fit values 
%    D(3,:) are the number of points in the track's msd data
%    D(4,:) are the track ids
%
% Raghuveer Parthasarathy
% April 27, 2007
% last modified Aug. 2, 2007 (enforces a cutoff in linear fit range)

function D = msdanalyze_rp(msd, cutoff, plotopt)

if plotopt
    figure; hold on;
    xlabel('Time');
    ylabel('\Deltax^2');
end

utrk = unique(msd(4,:));  % all the unique track ids

D = zeros(4, length(utrk));  % allocate memory

k=1;
for i = utrk
    % loop through each track
    tau = msd(3,msd(4,:)==i);
    Dx2 = msd(1,msd(4,:) == i);
    sigDx2 = msd(2,msd(4,:) == i);
    % enforce cutoff:
    ct = round(cutoff*length(tau));
    [D4, sigD4] = fityeqbx(tau(1:ct), Dx2(1:ct), sigDx2(1:ct));
    tempD = [D4 / 4.0; 
        sigD4 / 4.0;
        length(Dx2);
        i];
    D(:,k) = tempD;
    k=k+1;
    if plotopt
        plot(tau(1:ct), Dx2(1:ct), 'Color', [mod(i,3)/2 mod(i,4)/3 mod(i,5)/4]);
        % somewhat random colors
    end
end

