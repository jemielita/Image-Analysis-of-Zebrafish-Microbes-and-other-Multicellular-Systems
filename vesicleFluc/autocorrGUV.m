% autocorrguv.m
% 
% function to return the autocorrelation of the guv radial position 
% See notes Dec. 9, 2010
% DON'T call simpsonint for Simpson's rule integration -- see Notes Dec.
% 20, 2010.  Trapezoidal integration works much better; strange spikes with
% Simpson (?!)
%
% Repeats first element of arrays to account for periodicity
%
% The number of angular bins need not be the same for all images.
%
% INPUT
% guv -- structured array.  Number of elements determined by number of images
%       .file -- file number
%       .phi = corresponding phi to calculated radius/edge
%       .R = calculated edge of GUV for the given theta
% 
% OUTPUT
% xi -- structured array of angular autocorrelations.  Number of elements
%       determined by number of images
%       .gamma = angular lag values, same values as angles (phi) in guv array
%       .xi = autocorrelation; element 1 = angular lag 0; 2 = dgamma; col 3 = 2*dhpi...)
%
% To use this function other purposes, simply put R and phi values into 
% "guv" structure.
% Raghuveer Parthasarathy
% begun Dec. 9, 2010
% last modified Dec. 31, 2010

function xi = autocorrguv(guv)

Nframes = length(guv);                                   

% Allocate memory 
xi = repmat(struct('gamma', {[]}, 'xi', {[]}), Nframes, 1);


% For each frame, determine correlation integral (Simpson's rule)
progtitle = 'Progress calculating autocorrelations...'; 
progbar = waitbar(0, progtitle);  % will display progress
for j = 1:Nframes   
    Ngamma = length(guv(j).phi);  % number of angles evaluated in this frame
    dgamma = 2*pi/Ngamma;
    xi(j).gamma = guv(j).phi;
    rho = guv(j).R;
    if size(rho,1)<size(rho,2)
        rho = rho';  % make sure it's a row vector, for circshift below
    end
    % rhot = simpsonint([rho; rho(1)], dgamma)/2/pi;  % mean radius
    rhot = mean(rho);  % mean radius
%    term2 = simpsonint([rho; rho(1)], dgamma)/2/pi;  % repeat to cover [0,2*pi] & periodicity
    for gamma=0:(Ngamma-1)
        shiftrho = circshift(rho,-gamma);
        tointegrate = [rho; rho(1)].*[shiftrho; shiftrho(1)];
        
        % Simpson's integration [GIVES STRANGE SPIKES]
        % term1 = simpsonint(tointegrate, dgamma)/2/pi;
        % Simple sum
        %    term1 = sum(tointegrate)*dgamma/2/pi
        % Trapezoidal integration
        term1 = (sum(tointegrate(2:end-1))+0.5*tointegrate(1) + 0.5*tointegrate(end))*dgamma/2/pi;
        % term1 = simpsonint(rho.*shiftrho, dgamma)/2/pi; % neglects periodicity
        xi(j).xi(gamma+1) = (term1/rhot/rhot - 1);
%         figure(6); clf
%         plot([rho; rho(1)], 'ko-');
%         hold on
%         plot([shiftrho; shiftrho(1)], 'rx-');
%         pause
    end
    waitbar(j/Nframes, progbar, progtitle);
end
close(progbar)

