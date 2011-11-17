% calc_kappa.m
% 
% Function to determine bending modulus (kappa_c) and tension, extracting
% these from  previously-calculated Legendre polynomial coefficients 
% for edge autocorrelation xi(phi).
% Based on method described in 
% 1. Meleard, P., et al. Bending elasticities of model membranes: 
%   influences of temperature and sterol content. Biophys J 72, 2616-29 (1997).
% 2. Faucon, J. F. Bending elasticity and thermal fluctuations of lipid membranes...
%   J. Phys. France 50, 2389-2414 (1989).
%
% See notes Dec. 9-16, 2010
%
% Input
%    B_n : Array of Legendre coefficients, from legendre_kn.m
%         Rows correspond to different images
%    nrange: [optional] array of min and max Legendre coeffs to consider;
%         leave empty to consider all (i.e. nrange = [1 n_terms]).
%         Don't use the convention from the
%         above papers; use the convention from legendre_kn.m, so the
%         "lowest" non-trivial coefficient, the cos(theta) term, is n=1.
%    T   : temperature, Kelvin (leave empty, [], for T = 295K)
%    meanR : mean vesicle radius, *microns* (leave empty for "10e-6")
%    gaussth :  (optional) threshold for discarding  "bad" B_n; don't 
%         consider data points < gaussth*maximum in the probability 
%         distribution of B_n values (default 0.2) [Uses gasusfitPx.m]
%    fps  : frames per second during imaging
%    plotopt : [optional; default = false] make plots (1 == true)
%
% Output
%    kc : bending modulus (J) 
%    sigkc : uncertainty in kc, from linear fit
%    sigma : membrane tension (N/m)
% 
% Raghuveer Parthasarathy
% November 13, 2010
% last modified January 11, 2010

function [kc, sigkc, sigma, sigsigma] = ...
    calc_kappa(B_n, nrange, T, meanR, gaussth, fps, plotopt)

k_B = 1.381e-23;  % Boltzmann's constant, J/K
if isempty(T)
    T = 295.0;
    fs = sprintf('Using T= %.1f K', T); disp(fs)
end
if isempty(meanR)
    disp('Using R= 10 microns');
    meanR = 10e-6;
end
if isempty(gaussth)
    gaussth = 0.2;
end
if nargin<7
    plotopt = false;
end



% --------------------------------------------------------------

% Look at B_n values (Legendre coefficients)

% Delete rows from B_n that have NaNs
sn = false(size(B_n,1),1);
for j=1:size(B_n,1)
    sn(j) = sum(isnan(B_n(j,:)))>0;
end
B_n = B_n(~sn,:);


% --------------------------------------------------------------

% medB = median(B_n, 1);  % median of all the Legendre coeffs, averaged across frames (rows)
mB = mean(B_n, 1);  % mean of all the Legendre coeffs, averaged across frames (rows)
stdB = std(B_n,1);  % standard dev.

sB2 = length(mB);  % the number of legendre coefficients that were calculated
if isempty(nrange)
    nrange = [1 sB2];
end

% Display (normalized) Legendre coefficients, Offset by std. devs.
figure; hold on
for j=1:sB2
    plot(1:size(B_n,1), sum(2*stdB(1:j)./mB(1:j)) + B_n(:,j)/mB(j), 'o-', 'color', ...
        j/sB2*0.2*[1 1 1], 'markerfacecolor', [1-j/sB2 j/sB2 0.0]);
end
xlabel('Frame no.')
ylabel('Normalized B_n')

% --------------------------------------------------------------------

n = (1:sB2)+1;  % Coefficient indexes, with numbering convention as in above 
                % papers (i.e. n=2 is the cos(theta) term)
                

% -----------------------------------------------------------------------
% Get mean B_n, discarding outliers by looking at the probability
% distribution

Nfr = size(B_n,1);  % number of frames
goodmB = zeros(1,size(B_n,2));
goodstdB = zeros(1,size(B_n,2));
Nctrs = 41;  % number of bins for histogram
for j=1:size(B_n,2);
    dB = (max(B_n(:,j))-min(B_n(:,j)))/Nctrs;
    Bctrs = (min(B_n(:,j))+dB/2):dB:(max(B_n(:,j))-dB/2);
    [goodmB(j), goodstdB(j)] = gaussfitPx(B_n(:,j), Bctrs, 0.2, false);
    % [goodmB(j), goodstdB(j)] = gaussfitPx(B_n(:,j), Bctrs, 0.2, true);
    % disp('Press a key');
    % pause
end

% Show histograms of B_n values
if plotopt
    nsq = ceil(sqrt(size(B_n,2)));
    figure; subplot(nsq, nsq, 1);
    for j=1:size(B_n,2)
        subplot(nsq, nsq, j); hist(B_n(:,j),Nctrs)
        title(num2str(j));
    end
end


figure('Name', 'B_n x n terms');
plot(n, goodmB.*(n-1).*(n+2)./(2*n+1), 'rs');
title('B_n x n terms'); xlabel('n')

% ---------------------------------------------------------------------

% Relaxation times (just considering fluid flow)
% see Henriksen 2004 (Eq. 12) and other papers (Milner and Safran 1987)
eta = 0.9e-3; % water viscosity, Pa.s
tau = (4*pi*eta*meanR*meanR*meanR*1e-18/k_B/T)*(2 - 1./n./(n+1)).*goodmB; % seconds
figure('Name', 'relaxation times')
plot(n, tau, 'ko');
hold on
plot(n, ones(size(n))/fps, 'k:')
xlabel('n'); ylabel('\tau (s)');

% std of the mean of B -- see Henriksen 2004 Eq. 13
truestdB = goodstdB.*sqrt(2*tau*fps/Nfr);

if plotopt
    figure('Name', 'Legendre coefficients');
    plot(n, mB, 'ko', 'markerfacecolor', [0.2 0.6 0.9]);
    xlabel('Legendre index n')
    ylabel('mean B_n')
    hold on
    errorbar(n, goodmB, truestdB, 'ks', 'markerfacecolor', [0.9 0.6 0.2]);
end

% --------------------------------------------------------------
% Display parameters
fs = sprintf('Mean radius: %.2f microns', meanR); disp(fs)
fs = sprintf('Frames per second: %.1f ', fps); disp(fs)
fs = sprintf('Total number of frames: %d (= %.1f seconds) ', Nfr, Nfr/fps); disp(fs)
fs = sprintf('Range of Legendre indexes (start numbering at 1): %d to %d',...
    nrange(1), nrange(2)); disp(fs)

% -----------------------------------------------------------------

% some plots -- see Dec. 31, 2010 notes

figure('Name', 'B_n plots');
subplot(1,2,1)
plot(n, mB./((2*n+1)./(n-1)./(n+2)), 'ko', 'markerfacecolor', [0.9 0.6 0.2]);
xlabel('n')
ylabel('mean B_n ./((2*n+1)./(n-1)./(n+2))')
title('Tension dominated')

subplot(1,2,2)
plot(n, mB./((2*n+1)./(n-1)./(n+2)./n ./(n+1)), 'ks', 'markerfacecolor', [0.9 0.6 0.2]);
xlabel('n')
ylabel('mean B_n./((2*n+1)./(n-1)./(n+2)./n ./(n+1))')
title('Low tension')
    
% ----------------
% Crudely determine kappa by minimizing the variance of a function of Bn and n
sbar = logspace(-1,4,200);
for j=1:length(sbar)
    pr = 4*pi*goodmB.*(n-1).*(n+2).*(sbar(j) + n.*(n+1))./(2*n+1);
    mpr(j) = mean(pr(nrange(1):nrange(2)));
    stdpr(j) = std(pr(nrange(1):nrange(2)));
end
ra = stdpr./abs(mpr);
figure('Name', 'ratio vs. sbar');
semilogx(sbar, ra, 'ko');  title('ratio vs. sbar')
[mra, ix] = min(ra);
kc = k_B*T/mpr(ix);
disp('From analyzing variance of "ratio":')
fs = sprintf('   Bending modulus: %.2e Joules', kc); disp(fs)
fs = sprintf('   Tension (sbar): %.2e', sbar(ix)); disp(fs)


% ----------------

% For linearlization
yy = (2*n+1)./(goodmB)./(n-1)./(n+2)/4/pi;
xx = n.*(n+1);
sigyy = truestdB .* yy ./ mB ;

if plotopt
    hfit = figure; 
    errorbar(xx(nrange(1):nrange(2)), yy(nrange(1):nrange(2)),...
        sigyy(nrange(1):nrange(2)), 'ko', 'markerfacecolor', [0.6 0.2 0.9]);
    xlabel('n(n+1)')
    title('yy w/ std')
    hold on
    errorbar(xx, yy, sigyy, 'kd', 'markerfacecolor', [0.8 0.7 1.0]);
end

% Fit w/ uncertainties
[A, sigA, B, sigB] = fitline(xx(nrange(1):nrange(2)), yy(nrange(1):nrange(2)),...
        sigyy(nrange(1):nrange(2)), false);
% Fit w/o uncertainties
% [A, sigA, B, sigB] = fitline(xx(nrange(1):nrange(2)), yy(nrange(1):nrange(2)), [], false);
if plotopt
    figure(hfit)
    plot(xx(nrange(1):nrange(2)), A + B*xx(nrange(1):nrange(2)),...
        'k-', 'color', [0.9 0.6 0.2]);
end

kc = B*k_B*T;   % Bending modulus, Joules
sigkc = sigB*k_B*T;
sigma = 1e12*A*k_B*T/meanR/meanR;  % tension, N/m
sigsigma = 1e12*sigA*k_B*T/meanR/meanR;

disp('From "linear fit":')
fs = sprintf('    Bending modulus %.2f +/- %.2f x 10^{-20} J', ...
    kc/1e-20, sigkc/1e-20); disp(fs);
fs = sprintf('    Tension %.3e +/- %.3e N/m', ...
    sigma, sigsigma); disp(fs);


% chi^2 minimization
sbar = logspace(-1,2,100);  % array of sbar values to examine
karray = (0.2:0.2:60)*1e-20;  % array of kappa values to examine, J
chi2 = zeros(length(sbar), length(karray));
minchi2 = 9e99; bestsb = 9e99; bestkc = 9e99;
narray = n(nrange(1):nrange(2));  
disp('Starting chi^2 calculation...')
for j=1:length(sbar)
    sb = sbar(j);
    for k=1:length(karray)
        kca = karray(k);
        Bcalc = (k_B *T / 4 / pi / kca)*(2*narray+1) ./ ...
            ( (narray-1).* (narray+2) .* (sb + narray.*(narray+1))  );
        chi2(j,k) = sum((Bcalc - goodmB(nrange(1):nrange(2))).^2./truestdB(nrange(1):nrange(2)));
        if chi2(j,k) < minchi2
            minchi2 = chi2(j,k);
            bestsb = sb;
            bestkc = kca;
        end
    end
end
disp('   ...done')

% quick look for plateau
kr = (1./goodmB/4/pi) .* (2*n+1) ./ ((n+2).*(n-1).*(bestsb + n.*(n+1)));
figure('Name', 'kr')
plot(n, kr, 'bs');
xlabel('n'); ylabel('k/k_BT');

disp('Need to check if min. is at the bounds of search.');
fs = sprintf('Best fit sigmabar: %.2f', bestsb); disp(fs)
fs = sprintf('Best fit kappa_c:  %.3f x 10e-20J', bestkc*1e20); disp(fs)

% disp('Plotting chi2 contours...');
% figure; contour(karray, log10(sbar), chi2, minchi2*(1:1:20)); ylabel('log10(sbar)'); xlabel('kappa');

 
