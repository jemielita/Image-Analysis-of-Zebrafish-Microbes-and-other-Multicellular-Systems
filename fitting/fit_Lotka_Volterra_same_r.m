% fit_Lotka_Volterra_same_r.m
%
% Function to fit a two-species Lotka-Volterra competition model to population data.
% Force same growth rate (r) for both groups
%
% Force N0, t_lag as user-input values
%
% See notes, 2, 4, 9 Oct. 2013;  30 Oct 2013 on weighting
%            Dec. 10, 2013
%
% uses boxcarpad.m
% uses Lotka_Volterra.m
%
% Inputs
%    t :  array of time points
%    N :  array of population values; rows 1, 2 = each population
%    N0 : initial populations, 2-element array
%    t_lag : time lag, 2-element array
%    halfboxsize : half-width of the box for determining the local std.
%         dev., for weighting the LS fit.  Default 2 time points.
%    tolN : tolerance in N for fitting (default 1e-4 if empty)
%    params0 : [optional] starting values of the parameters
%              If not input or empty, default values
%              1 - r, growth rate; default from simple linear fit ,average of each group.
%                  Assumed same for both groups!
%              2, 3 - K, carrying capacity; default max of N for each group
%              4, 5 - alpha (competition term)  first term is alpha_12 (effect on pop. 1 of
%                     pop 2); second term is alpha_21.  Default 0, 0
%    LB     : [optional] lower bounds of search parameters
%              If not input or empty, default values
%              1 - r (0)
%              2, 3 - K (0)
%              4, 5 - alpha (0)
%    UB     : [optional] upper bounds of search parameters
%              1 - r (Inf.)
%              2, 3 - K (Inf.)
%              4, 5 - alpha (Inf)
%    lsqoptions : [optional] options structure for nonlinear least-squares
%              fitting, from previosly running 
%              "lsqoptions = optimset('lsqnonlin');"
%              Inputting this speeds up the function.
%
% Outputs
%   r  : initial (max) growth rate, in 1/time units
%   K  : carrying capacity, 2 element array
%   alpha : competition term, 2 element array
%   sigr, sigK, sigalpha : uncertainties in the above parameters
%
% Raghuveer Parthasarathy
% October 2, 2013
% last modified Dec. 16, 2013

function [r, K, alpha, sigr, sigK, sigalpha] = ...
    fit_Lotka_Volterra_same_r(t, N, N0, t_lag,...
                        halfboxsize, tolN, params0, LB, UB, lsqoptions)



% defaults for initial parameter values, and lower and upperbounds
if ~exist('halfboxsize', 'var') || isempty(halfboxsize)
    halfboxsize = 2;
end
if ~exist('tolN', 'var') || isempty(tolN)
    tolN = 1e-4;
end
if ~exist('params0', 'var') || isempty(params0)
    [~, ~, B1, ~] = fitline(t, log(N(1,:)));
    [~, ~, B2, ~] = fitline(t, log(N(2,:)));
    B = [B1 B2];
    B(isnan(B))=[];
    params0 = [mean(B) max(N(1,:)) max(N(2,:)) 0 0];
end
if ~exist('LB', 'var') || isempty(LB)
    LB = [0,0, 0, 0, 0];
end
if ~exist('UB', 'var') || isempty(UB)
    UB = [inf, inf, inf, inf, inf];
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
% early time data; fit all parameters including (positive) time_lag

[params,~,residual,~,~,~,J] = lsqnonlin(@(P) LVfun(P,t,N,N0, t_lag, halfboxsize),params0,LB,UB,lsqoptions);
varresid = var(residual);
cv = full(inv(J'*J)*varresid); % ignore the warning; I think inv is necessary
r = params(1);
K(1) = params(2);
K(2) = params(3);
alpha(1) = params(4);
alpha(2) = params(5);


% Uncertainties
% http://www.mathworks.com/matlabcentral/answers/51136
% http://www.ligo-wa.caltech.edu/~ehirose/work/andri_matlab_tools/fitting/MatlabJacobianDef.pdf
sigr = sqrt(cv(1,1));
sigK = [sqrt(cv(2,2)) sqrt(cv(3,3))];
sigalpha = [sqrt(cv(4,4)) sqrt(cv(5,5))];


end


    function resids = LVfun(params,t,N,N0, t_lag,halfboxsize)
    % fit Lotka-Volterra model
    % fit to logarithm, no weighting, since std. weighting is very biased
    % to the smaller population
        t = t(:);
        Nth = Lotka_Volterra(t, params(1)*[1 1], [params(2)  params(3)],...
            N0, t_lag, [params(4) params(5)]);
        %invwts1 = calclocalstd(N(1,:),halfboxsize);
        %invwts2 = calclocalstd(N(2,:),halfboxsize);
        N(N==0)=1; % crude; to avoid zero errors if not
        allresids1 = log(Nth(1,:)) - log(N(1,:));
        allresids2 = log(Nth(2,:)) - log(N(2,:));
        resids1 = allresids1(halfboxsize+1:length(N)-halfboxsize);
        resids2 = allresids2(halfboxsize+1:length(N)-halfboxsize);
        resids = [resids1(:); resids2(:)];
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