% corr2pt_analyze.m
%
% Plot, analyze the 2-point correlation output of corr2pt.m
% Input:  Rbins, taubins -- same bins as input to corr2pt.m
%         Dpar, Dperp -- output of corr2pt.m
$ Output:  slopes of D ~ tau, for parallel and perpendicular correlations.
% Also, displays slope of log-log fit
% 
% Raghuveer Parthasarathy
% August 3, 2007


function [Dslopepar sigDslopepar Dslopeperp sigDslopeperp] = ...
    corr2pt_analyze(Dpar, Dperp, Rbins, taubins)


% Fit D(tau) for each R to a line and extract the slope
Dslopepar = zeros(size(Rbins));
sigDslopepar = zeros(size(Rbins));
Dslopeperp = zeros(size(Rbins));
sigDslopeperp = zeros(size(Rbins));
for k=1:length(Rbins)
    temptau = taubins(~isnan(Dpar(k,:)));
    tempD = Dpar(k,~isnan(Dpar(k,:)));
    [Dslopepar(k), sigDslopepar(k)] = fityeqbx(temptau, tempD);
    temptau = taubins(~isnan(Dperp(k,:)));
    tempD = Dperp(k,~isnan(Dperp(k,:)));
    [Dslopeperp(k), sigDslopeperp(k)] = fityeqbx(temptau, tempD);
end

[A sigA logDslopepar siglogDslopepar] = ...
    fitline(log(Rbins(Dslopepar>0.0)), log(Dslopepar(Dslopepar>0.0)), false);
[A sigA logDslopeperp siglogDslopeperp] = ...
    fitline(log(Rbins(Dslopeperp>0.0)), log(Dslopeperp(Dslopeperp>0.0)), false);


% Plots

figure;
plot(Rbins, Dpar(:,1)/taubins(1), 'bo')
hold on
plot(Rbins, Dperp(:,1)/taubins(1), 'ro')
title('D / \tau -- bin 1');
legend('D_R / \tau', 'D_\theta / \tau')

figure;
loglog(Rbins, Dpar(:,1)/taubins(1), 'bo')
hold on
loglog(Rbins, Dperp(:,1)/taubins(1), 'ro')
title('D / \tau -- bin 1');
legend('D_R / \tau', 'D_\theta / \tau')

figure; 
loglog(Rbins, Dslopepar, 'bx');
hold on
loglog(Rbins, Dslopeperp, 'rx');
title('slope of D vs \tau');
legend('D_R / \tau', 'D_\theta / \tau')


fs = sprintf('Slope of log(D_par/tau) vs. log(R): %.2e +/- %.2d', ...
    logDslopepar, siglogDslopepar); disp(fs)
fs = sprintf('Slope of log(D_perp/tau) vs. log(R): %.2e +/- %.2e', ...
    logDslopeperp, siglogDslopeperp); disp(fs)


