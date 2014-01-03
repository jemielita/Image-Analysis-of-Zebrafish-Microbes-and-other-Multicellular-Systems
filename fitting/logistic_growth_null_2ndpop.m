% logistic_growth_null_2ndpop.m
%
% Null model, logistic growth, in which the population of the calculated
% group depends on the total population of two groups relative to an
% overall carrying capacity (K)
% Numerical integration
%
% See notes, Dec. 15-16, 2013
%
% uses logistic_N_t.m
%
% Inputs
%    t :  array of time points
%    Ksum : overall carrying capacity
%    N1 :  array of population value for population 1 (same size as t)
%          *OR* array of [r K N0 t_lag] for logistic growth curve
%          describing population 1
%    N0_2 : initial population of group 2 (default 1)
%    t_lag_2 : lag time of population 2.  (Could input, for example, to be
%              lag time of #1 + tdelay (default 0.0)
%
% Outputs
%   N2  : population 2
%
% Raghuveer Parthasarathy
% Dec. 16, 2013
% last modified Dec. 16, 2013

function [N2] = logistic_growth_null_2ndpop(t, Ksum, N1, N0_2, t_lag_2)

if ~exist('N0_2', 'var') || isempty(N0_2)
    N0_2 = 1;
end
if ~exist('t_lag_2', 'var') || isempty(t_lag_2)
    t_lag_2 = 0.0;
end

if length(N1)==4
    r = N1(1);
    K = N1(2);
    N0 = N1(3);
    t_lag = N1(4);
    N1 = logistic_N_t(t, r, K, N0, t_lag); % use model fit values
end

N2 = N0_2*ones(size(t));  % species 2
for j=2:length(t)
    if t(j) > t_lag_2
        dN2 = (t(j)-t(j-1)) * r * N2(j-1) * (1-(N2(j-1) + N1(j-1))/Ksum);
        N2(j) = N2(j-1)+dN2;
    else
        % still in lag phase
        N2(j) = N2(j-1);
    end
end

