% fit_logistic_growth.m
%
% Function to fit a logistic growth curve to population data.
% Three options:  fit r, K, N0, t_lag, i.e. include time lag  (e.g. early time data)
%                 fit r, K, N0; i.e. no time lag (e.g. late time data)
%                 fit r, K; manually input nucleation size and time lag
%
% ignores all population values <= 0
%
% See notes, 2, 4, 9 Oct. 2013;  30 Oct 2013 on weighting
%            Dec. 10-11, 2013
%
% uses boxcarpad.m
% uses logistic_N_t.m
%
% Inputs
%    t :  array of time points
%    N :  array of population values
%    alt_fit : if false (default), fit all four parameters (see below)
%                 if true, fit r, K, N0; don't fit time lag (NaN); useful for late time data
%                 if a two-element array, fix N0 as element 1, t_lag as element 2
%    halfboxsize : half-width of the box for determining the local std.
%         dev., for weighting the LS fit.  Default 2 time points.
%    tolN : tolerance in N for fitting (default 1e-4 if empty)
%    params0 : [optional] starting values of the parameters
%              If not input or empty, default values
%              1 - r, growth rate; default from simple linear fit
%              2 - K, carrying capacity; default max of N
%              3 - N0 (nucleation size)
%              4 - t_lag, lag time; default 0
%    LB     : [optional] lower bounds of search parameters
%              If not input or empty, default values
%              1 - r (0)
%              2 - K (0)
%              3 - N0 (1)
%              4 - t_lag (0)
%    UB     : [optional] upper bounds of search parameters
%              1 - r (Inf.)
%              2 - K (Inf.)
%              3 - N0  (max(N))
%              4 - t_lag  (max(t))
%    lsqoptions : [optional] options structure for nonlinear least-squares
%              fitting, from previosly running 
%              "lsqoptions = optimset('lsqnonlin');"
%              Inputting this speeds up the function, but this probably isn't important.
%
% Outputs
%   r  : initial (max) growth rate, in 1/time units
%   K  : carrying capacity
%   N0 : nucleation size
%   t_lag : lag time
%   sigr, sigK, sigN0, sigt_lag : uncertainties in the above parameters
%
% Raghuveer Parthasarathy
% October 2, 2013
% last modified Dec. 15, 2013

function [r, K, N0, t_lag, sigr, sigK, sigN0, sigt_lag] = ...
    fit_logistic_growth(t, N, alt_fit,...
                        halfboxsize, tolN, params0, LB, UB, lsqoptions)


% consider only values >0
t = t(N>0);
N = N(N>0);

% defaults for initial parameter values, and lower and upperbounds
if ~exist('alt_fit', 'var') || isempty(alt_fit)
    alt_fit = false;
end
if ~exist('halfboxsize', 'var') || isempty(halfboxsize)
    halfboxsize = 2;
end
if ~exist('tolN', 'var') || isempty(tolN)
    tolN = 1e-4;
end
if ~exist('params0', 'var') || isempty(params0)
    [~, ~, B, ~] = fitline(t, log(N));
    params0 = [B max(N) min(N) 0];
end
if ~exist('LB', 'var') || isempty(LB)
    LB = [0,0, 1, 0];
end
if ~exist('UB', 'var') || isempty(UB)
    UB = [inf, inf, max(N), max(t)];
end

if ~exist('lsqoptions', 'var') || isempty(lsqoptions)
    lsqoptions = optimset('lsqnonlin');
end


% More fitting options
lsqoptions.TolFun = tolN;  %  % MATLAB default is 1e-6
lsqoptions.TolX = 1e-5';  % default is 1e-6
lsqoptions.Display = 'off'; % 'off' or 'final'; 'iter' for display at each iteration

% fit logistic growth, weighting by local standard deviation to avoid
    %   the fit being totally determined by the high-N points
if length(alt_fit)==2
    % user input No, tlag 
    N0 = alt_fit(1);
    t_lag = alt_fit(2);
    fixparams = [N0 t_lag];
    % fit only r, K
    params0 = params0(1:2);
    LB = LB(1:2);
    UB = UB(1:2);
    [params,~,residual,~,~,~,J] = lsqnonlin(@(P) logisticfun(P,t,N,halfboxsize, fixparams),params0,LB,UB,lsqoptions);
else
    fixparams = [];
    if alt_fit
        % fit r, K, N0
        params0 = params0(1:3);
        LB = LB(1:3);
        UB = UB(1:3);
        [params,~,residual,~,~,~,J] = lsqnonlin(@(P) logisticfun(P,t,N,halfboxsize, fixparams),params0,LB,UB,lsqoptions);
        t_lag = 0.0;
    else
        % don't need to alter params0, etc.
        % fit r, K, N0, t_lag
        [params,~,residual,~,~,~,J] = lsqnonlin(@(P) logisticfun(P,t,N,halfboxsize, fixparams),params0,LB,UB,lsqoptions);
        t_lag = params(4);
    end
    N0 = params(3);
end
r = params(1);
K = params(2);

% Uncertainties
% http://www.mathworks.com/matlabcentral/answers/51136
% http://www.ligo-wa.caltech.edu/~ehirose/work/andri_matlab_tools/fitting/MatlabJacobianDef.pdf
varresid = var(residual);
cv = full(inv(J'*J)*varresid); % ignore the warning; I think inv is necessary

cv(1,1)
cv(1,2)
cv(2,1)
cv(2,2)
sigr = sqrt(cv(1,1));
sigK = sqrt(cv(2,2));

if length(diag(cv))>=3
    sigN0 = sqrt(cv(3,3));
    if length(diag(cv))>=4
        sigt_lag = sqrt(cv(4,4));
    else
        sigt_lag = NaN;
    end
else
    sigN0 = NaN;
    sigt_lag = NaN;
end

end


    function resids = logisticfun(params, t, N, halfboxsize, fixparams)
    % residual of fit to logistic growth curve, weighted by local std. 
    % in a sliding window
    % decides on various options (what to fit) by the length of the params
    % array
    % fixparams is optional; if not empty, should be 2-element array of
    % forced N0, tlag
        t = t(:);
        N = N(:);
        invwts = calclocalstd(N,halfboxsize);  % 1/weights = local std.
        switch length(params)
            case 4
                % Fitting r, K, N0, tlag
                r = params(1);
                K = params(2);
                N0 = params(3);
                tlag = params(4);
            case 3
                % Fitting r, K, N0;  force tlag = 0
                r = params(1);
                K = params(2);
                N0 = params(3);
                tlag = 0.0;
            case 2
                % Fitting r, K, N0; user-input N0 and tlag as fixparams(1,2);
                r = params(1);
                K = params(2);
                N0 = fixparams(1);
                tlag = fixparams(2);
        end
        Nth = logistic_N_t(t, r, K, N0, tlag);
        allresids = (Nth - N)./invwts;
        resids = allresids(halfboxsize+1:length(N)-halfboxsize);
    end
    
    function smstd = calclocalstd(N,halfboxsize)
    % local std. in a sliding window, to be used as weights
        N = N(:);
        Nbox = 2*halfboxsize+1;
        smN = boxcarpad(N, Nbox);
        smN2 = boxcarpad(N.*N, Nbox);
        smstd = sqrt(smN2 - smN.*smN);  % standard deviation in each boxcar window.
        % In case std. is zero, assume sqrt(N) uncertainty
        smstd(smstd==0) = sqrt(N(smstd==0));
    end