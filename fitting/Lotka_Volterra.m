% Lotka_Volterra.m
%
% Lotka-Volterra two-species competition model
% simple integration of differential equation
%
% Inputs
% t : time (can be an array)
% r : growth rate (inverse units of t), 2-element array
% K : Carrying capacity, 2-element array
% N0 : initial population size, 2-element array
% t_lag : lag time (N = N0 for t <= t_lag); default 0; , 2-element array
% alpha : competition term.  first term is alpha_12 (effect on pop. 1 of
%         pop 2); second term is alpha_21
% Output
% N : population (array; row 1, 2 = population 1, 2)
%
% Raghuveer Parthasarathy
% Dec. 11, 2013

function N = Lotka_Volterra(t, r, K, N0, t_lag, alpha)

if ~exist('t_lag', 'var') || isempty(t_lag)
    t_lag = [0 0];
end
if ~exist('alpha', 'var') || isempty(alpha)
    alpha = [0 0];
end


t = t(:);

N = zeros(2, length(t));
N(1,1) = N0(1);
N(2,1) = N0(2);
for j=2:length(t)
    for k=1:2
        % each population
        if t(j) > t_lag(k)
            dNth = (t(j)-t(j-1)) * r(k)*N(k,j-1)*(1 - (N(k,j-1)/K(k)) - (alpha(k)*N(3-k,j-1)/K(k)));
            N(k,j) = N(k,j-1)+dNth;
        else
            % still in lag phase
            N(k,j) = N(k,j-1);
        end
    end
end
