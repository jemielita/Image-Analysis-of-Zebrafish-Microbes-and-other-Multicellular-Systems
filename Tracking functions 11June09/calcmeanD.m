% calcmeanD.m
%
% from the matrix of diffusion coefficient values for each track (e.g. from
% msdanalyze_rp.m) calculate a  mean diffusion coefficient (output: meanD)
% and its uncertainty (output: stdD).
% Input:
%    D -- matrix of diffusion coefficient values
%    Nmin -- consider only tracks with >Nmin points.  
%    Dmin -- consider only tracks with diffusion coefficient D > Dmin.  
%    dispopt -- display histogram of D values;  print mean, std to screen
% Output:
%    meanD
%    stdD
%    Ngood = number of tracks with > Nmin points
% Calculate mean D by simple average -- average weighted by uncertainty of
%    the D fit seems to severely overemphasize low-mobility tracks --
%    19July07
%
% Raghuveer Parthasarathy
% April 27, 2007
% last modified: March 27, 2009 (minor formatting change)


function [meanD stdD Ngood] = calcmeanD(D, Nmin, Dmin, dispopt)

if (nargin < 3)  % Assume user wants to plot
    dispopt=true;
end

D1 = D(1,:);  % D values
DN = D(3,:);  % number of points in track
goodDind = ((DN > Nmin) & ~isnan(D1));  % good indices
goodD = D(1,goodDind);
% goodstdD = D(2,goodDind);

%meanD = sum(goodD./goodstdD./goodstdD)./sum(1.0./goodstdD./goodstdD);
%stdDsq = sum((goodD-meanD).*(goodD-meanD)./goodstdD./goodstdD)./...
%    sum(1.0./goodstdD./goodstdD);
%stdD = sqrt(stdDsq);

% Apply minimum D cutoff
goodD = goodD(goodD>Dmin);
meanD = mean(goodD);
stdD = std(goodD);

Ngood = length(goodD);

if dispopt
    % Plot histogram
    figure; hist(goodD,50);
    title('Good D values -- histogram');
    xlabel('D \mum^2/s');

    fs = sprintf('%d tracks > %d frames, out of %d total', ...
        Ngood, Nmin, length(D1)); disp(fs)
    fs = sprintf('   Mean D value: %.3f +/- %.3f',  meanD, stdD);
    disp(fs);
end
