% logistic_N_t.m
%
% N(t) for simple logistic growth
%
% Inputs
% t : time (can be an array)
% r : growth rate (inverse units of t)
% K : Carrying capacity
% N0 : initial population size
% t_lag : lag time (N = N0 for t <= t_lag); default 0
%
% Output
% N : population (can be an array)

function N = logistic_N_t(t, r, K, N0, t_lag)

if ~exist('t_lag', 'var') || isempty(t_lag)
    t_lag = 0;
end

N = N0./(N0/K + (1-N0/K)*exp(-r.*(t-t_lag))); 
N(t<=t_lag) = N0;
