% fit_logistic_growth.m
%
% Function to fit a logistic growth curve to population data.
% Two options:  fit with time lag  (early time data)
%               no time lag (late time data)
%
% ignores all population values <= 0
%
% See notes, 2, 4, 9 Oct. 2013;  30 Oct 2013 on weighting
%            Dec. 10, 2013
%
% uses boxcarpad.m
% uses logistic_N_t.m
%
% Inputs
%    t :  array of time points
%    N :  array of population values
%    alt_fit : if false (default), fit all four parameters (see below)
%                 if true, fit r, K, N0; don't fit time lag (NaN); useful for late time data
%                 if a two-element array, fix t_lag as element 1, N0 as element 2 
%    halfboxsize : half-width of the box for determining the local std.
%         dev., for weighting the LS fit.  Default 2 time points.
%    tolN : tolerance in N for fitting (default 1e-4 if empty)
%    params0 : [optional] starting values of the parameters
%              If not input or empty, default values
%              1 - r, growth rate; default from simple linear fit
%              2 - K, carrying capacity; default max of N
%              3 - t_lag, lag time; default 0
%              4 - N0 (nucleation size)
%    LB     : [optional] lower bounds of search parameters
%              If not input or empty, default values
%              1 - r (0)
%              2 - K (0)
%              3 - t_lag (0)
%              4 - N0 (1)
%    UB     : [optional] upper bounds of search parameters
%              1 - r (Inf.)
%              2 - K (Inf.)
%              3 - t_lag  (max(t))
%              4 - N0  (max(N))
%    lsqoptions : [optional] options structure for nonlinear least-squares
%              fitting, from previosly running 
%              "lsqoptions = optimset('lsqnonlin');"
%              Inputting this speeds up the function.
%
% Outputs
%   r  : initial (max) growth rate, in 1/time units
%   K  : carrying capacity
%   t_lag : lag time
%   N0 : nucleation size
%   sigr, sigK, sigt_lag, sigN0 : uncertainties in the above parameters
%
% Raghuveer Parthasarathy
% October 2, 2013
% last modified Dec. 11, 2013

function [r, K, t_lag, N0, sigr, sigK, sigt_lag, sigN0] = ...
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
    params0 = [B max(N) 0 min(N)];
end
if ~exist('LB', 'var') || isempty(LB)
    LB = [0,0,0, 1];
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

% fit logistic growth, weighting by local standard deviation to avoid
    %   the fit being totally determined by the high-N points
if length(alt_fit)==1
    if ~alt_fit
        % early time data; fit all parameters including (positive) time_lag
        [params,~,residual,~,~,~,J] = lsqnonlin(@(P) objfun_early(P,t,N,halfboxsize),params0,LB,UB,lsqoptions);
        varresid = var(residual);
        cv = full(inv(J'*J)*varresid); % ignore the warning; I think inv is necessary
        N0 = params(4);
        sigN0 = sqrt(cv(4,4));
        t_lag = params(3);
        sigt_lag = sqrt(cv(3,3));
    else
        % late time data; no time lag
        % input params 1, 2, 4 -- ignore t_lag parameter
        [params,~,residual,~,~,~,J] = lsqnonlin(@(P) ...
            objfun_late(P,t,N,halfboxsize),params0([1 2 4]),LB([1 2 4]),UB([1 2 4]),lsqoptions);
        varresid = var(residual);
        cv = full(inv(J'*J)*varresid); % ignore the warning; I think inv is necessary
        t_lag = NaN;
        sigt_lag = NaN;
        N0 = params(3);
        sigN0 = sqrt(cv(3,3));
    end
else
    % force t_lag and N0 to have user-input values
    t_lag = alt_fit(1);
    N0 = alt_fit(2);
    [params,~,residual,~,~,~,J] = lsqnonlin(@(P) ...
        objfun_rKonly(P,t,N,t_lag, N0,halfboxsize),params0([1 2]),LB([1 2]),UB([1 2]),lsqoptions);
    varresid = var(residual);
    cv = full(inv(J'*J)*varresid); % ignore the warning; I think inv is necessary
    sigt_lag = NaN;
    sigN0 = NaN;
end
r = params(1);
K = params(2);

% Uncertainties
% http://www.mathworks.com/matlabcentral/answers/51136
% http://www.ligo-wa.caltech.edu/~ehirose/work/andri_matlab_tools/fitting/MatlabJacobianDef.pdf
sigr = sqrt(cv(1,1));
sigK = sqrt(cv(2,2));

%     invwts = calclocalstd(N,halfboxsize);
%     figure;
%     errorbar(t,N,invwts, 'rx')

end


    function resids = objfun_early(params,t,N,halfboxsize)
    % fit logistic growth, weighted by local std. in a sliding window
        t = t(:);
        N = N(:);
        Nth = logistic_N_t(t, params(1), params(2), params(4), params(3));
        % Nth = params(4)./(params(4)/params(2) + (1-params(4)/params(2)).*exp(-params(1).*(t-params(3))));
        invwts = calclocalstd(N,halfboxsize);
        allresids = (Nth - N)./invwts;
        resids = allresids(halfboxsize+1:length(N)-halfboxsize);
    end
    
    function resids = objfun_late(params,t,N,halfboxsize)
    % fit logistic growth, weighted by local std. in a sliding window
    % No lag time (not a parameter); force to be zero
        t = t(:);
        N = N(:);
        % Note N0 is params(3), as input
        Nth = logistic_N_t(t, params(1), params(2), params(3), 0.0);
        % Nth = params(3)./(params(3)/params(2) + (1-params(3)/params(2)).*exp(-params(1).*t));
        invwts = calclocalstd(N,halfboxsize);
        allresids = (Nth - N)./invwts;
        resids = allresids(halfboxsize+1:length(N)-halfboxsize);
    end

    function resids = objfun_rKonly(params,t,N,t_lag, N0,halfboxsize)
    % fit logistic growth, weighted by local std. in a sliding window
    % No lag time or N0 (not parameters); user-input
        t = t(:);
        N = N(:);
        Nth = logistic_N_t(t, params(1), params(2), N0, t_lag);
        % Nth = N0./(N0/params(2) + (1-N0/params(2)).*exp(-params(1).*(t-t_lag)));
        invwts = calclocalstd(N,halfboxsize);
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