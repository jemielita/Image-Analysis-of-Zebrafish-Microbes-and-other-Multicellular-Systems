% fit_logistic_growth.m
%
% Function to fit a logistic growth curve to population data.
% Two options:  fit with time lag and noise floor, and N0=1 (early time data)
%               fit nucleation size (no lag, noise floor) (late time data)
%
% ignores all population values <= 0
%
% See notes, 2, 4, 9 Oct. 2013;  30 Oct 2013 on weighting
%
% uses boxcarpad.m
%
% Inputs
%    t :  array of time points
%    N :  array of population values
%    late_time_option : fit for late time data (fit nucleation size; no
%         lag); default false
%    halfboxsize : half-width of the box for determining the local std.
%         dev., for weighting the LS fit.  Default 2 time points.
%    tolN : tolerance in N for fitting (default 1e-4 if empty)
%    params0 : [optional] starting values of the parameters
%              If not input or empty, default values
%              1 - r, growth rate; default from simple linear fit
%              2 - K, carrying capacity; default max of N
%              3 - t_lag, lag time; default 0
%              4 - N_c; N_floor (noise floor) for early time option, 
%                       N0 (nucleation size) for late time option; default min of N
%    LB     : [optional] lower bounds of search parameters
%              If not input or empty, default values
%              1 - r (0)
%              2 - K (0)
%              3 - t_lag (0)
%              4 - N_c (1)
%    UB     : [optional] upper bounds of search parameters
%              1 - r (Inf.)
%              2 - K (Inf.)
%              3 - t_lag  (max(t))
%              4 - N_c  (max(N))
%    lsqoptions : [optional] options structure for nonlinear least-squares
%              fitting, from previosly running 
%              "lsqoptions = optimset('lsqnonlin');"
%              Inputting this speeds up the function.
%
% Outputs
%   r  : initial (max) growth rate, in 1/time units
%   K  : carrying capacity
%   t_lag : lag time
%   Nfloor :  N_floor (noise floor) for early time option, 
%          N0 (nucleation size) for late time option
%   sigr, sigK, sigt_lag, sigNfloor : uncertainties in the above parameters
%
% Raghuveer Parthasarathy
% October 2, 2013
% last modified Oct 30, 2013

function [r K t_lag N_floor, sigr, sigK, sigt_lag, sigNfloor] = ...
    fit_logistic_growth(t, N, late_time_option,...
                        halfboxsize, tolN, params0, LB, UB, lsqoptions)


% consider only values >0
t = t(N>0);
N = N(N>0);

% defaults for initial parameter values, and lower and upperbounds
if ~exist('late_time_option', 'var') || isempty(late_time_option)
    late_time_option = false;
end
if ~exist('halfboxsize', 'var') || isempty(halfboxsize)
    halfboxsize = 2;
end
if ~exist('tolN', 'var') || isempty(tolN)
    tolN = 1e-4;
end
if ~exist('params0', 'var') || isempty(params0)
    [~, ~, B, ~] = fitline(t, log(N));
    params0 = [B max(N) 0 min(N)];
end
if ~exist('LB', 'var') || isempty(LB)
    LB = [0,0,-max(t), 1];
end
if ~exist('UB', 'var') || isempty(UB)
    UB = [inf, inf, max(t), max(N)];
end

if ~exist('lsqoptions', 'var') || isempty(lsqoptions)
    lsqoptions = optimset('lsqnonlin');
end


% More fitting options
lsqoptions.TolFun = tolN;  %  % MATLAB default is 1e-6
lsqoptions.TolX = 1e-5';  % default is 1e-6
lsqoptions.Display = 'off'; % 'off' or 'final'; 'iter' for display at each iteration

% fit logistic growth, using logarithmic deviation as the residual, to avoid
%the fit being totally determined by the high-N points
 if late_time_option
    % late time data; fit nucleation size
    [params,~,residual,~,~,~,J] = lsqnonlin(@(P) objfun_late(P,t,N,halfboxsize),params0,LB,UB,lsqoptions);
    varresid = var(residual);
    cv = full(inv(J'*J)*varresid); % ignore the warning; I think inv is necessary
    t_lag = NaN;
    sigt_lag = NaN;
else
    % early time data; fit time_lag, noise floor
    [params,~,residual,~,~,~,J] = lsqnonlin(@(P) objfun_early(P,t,N,halfboxsize),params0,LB,UB,lsqoptions);
    varresid = var(residual);
    cv = full(inv(J'*J)*varresid); % ignore the warning; I think inv is necessary
    t_lag = params(3);
    sigt_lag = sqrt(cv(3,3));
end
r = params(1);
K = params(2);
N_floor = params(4);

% Uncertainties
% http://www.mathworks.com/matlabcentral/answers/51136
% http://www.ligo-wa.caltech.edu/~ehirose/work/andri_matlab_tools/fitting/MatlabJacobianDef.pdf
sigr = sqrt(cv(1,1));
sigK = sqrt(cv(2,2));
sigNfloor = sqrt(cv(4,4));

end


    function resids = objfun_early(params,t,N,halfboxsize)
    % fit logistic growth, weighted by local std. in a sliding window
        t = t(:);
        N = N(:);
        Nth = 1./(1/params(2) + (1-1/params(2)).*exp(-params(1).*(t-params(3))));
        modelfun = max(params(4), Nth);
        Nbox = 2*halfboxsize+1;
        smN = boxcarpad(N, Nbox);
        smN2 = boxcarpad(N.*N, Nbox);
        smstd = sqrt(smN2 - smN.*smN);  % standard deviation in each boxcar window.
        % In case std. is zero, assume sqrt(N) uncertainty
        smstd(smstd==0) = sqrt(N(smstd==0));
        allresids = (modelfun - N)./smstd;
        resids = allresids(halfboxsize+1:length(N)-halfboxsize);
        
        
    end
    
    function resids = objfun_late(params,t,N,halfboxsize)
    % fit logistic growth, weighted by local std. in a sliding window
        t = t(:);
        N = N(:);
        modelfun = params(4)./(params(4)/params(2) + (1-params(4)/params(2)).*exp(-params(1).*t));
        Nbox = 2*halfboxsize+1;
        smN = boxcarpad(N, Nbox);
        smN2 = boxcarpad(N.*N, Nbox);
        smstd = sqrt(smN2 - smN.*smN);  % standard deviation in each boxcar window.
        % In case std. is zero, assume sqrt(N) uncertainty
        smstd(smstd==0) = sqrt(N(smstd==0));
        allresids = (modelfun - N)./smstd;
        resids = allresids(halfboxsize+1:length(N)-halfboxsize);
    end
