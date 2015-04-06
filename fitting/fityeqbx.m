% fityeqbx.m
%
% function to fit the equation y = bx to data sets [x], [y] (i.e. a line with
% intercept at the origin)
% Returns B and uncertainty in B.  Also returns minimal chi2, and 
% handle to (optional) figure.  If sigy is input, use this in determining
% the uncertainty in B; if not, use deviation from the line.
%
% Inputs:
%     x : x array
%     y : y array
%     sigy : array of uncertainties in y; optional 
%     plotopt : IF plotopt==1, plot the points, and the line
%               Can omit plotopt argument; then will not plot
% Outputs
%     A, sigA : intercept and uncertainty
%     B, sigB : intercept and uncertainty
%     chi2 : minimal chi^2 (calculated with /sigy^2 if sigy is input, without if not.)
%     h  : handle to figure (empty if plotopt==false)
%
% Raghu  18 April, 2004
% last modified March 14, 2012

function [B, sigB, chi2, h] = fityeqbx(x, y, sigy, plotopt)

if (length(x) ~= length(y))
    disp('Error!  x, y are not the same size!')
    input('Recommend Control-C. [Enter]');
end

% Deal with sigy input as in fitline.m
sigyinput = true;  % is the function called with uncertainty values? Default: true
if (nargin < 4)
    plotopt = false;
    if (nargin < 3)
       sigy = ones(size(x));  % irrelevant, uniform uncertainty
       sigyinput = false;
    else
       % There are three input arguments
       if (length(sigy(:))==1)
          % three arguments, and the third is just one number -- so this argument
          % is probably "plotopt", and the function is being called by something
          % written before the consideration of sigy
          plotopt = sigy;
          sigy = ones(size(x));
          sigyinput = false;
       end
    end
end
if isempty(sigy)
    % in case it's empty
    sigy = ones(size(x));
    sigyinput = false;
end

N = length(x);
sxx = sum(x.*x./sigy./sigy);
sxy = sum(x.*y./sigy./sigy);

if sxx < eps
    B = NaN;
    sigB = NaN;
    chi2 = NaN;
else
    B = sxy / sxx;
    if ~sigyinput
        sigy = (y - B*x);  % estimate uncertainty by deviation from the line
        chi2 = sum((y-B*x).*(y-B*x))/N;
    else
        chi2 = sum((y-B*x).*(y-B*x)./sigy./sigy)/N;
    end
    sigB = sqrt(sum(x.*x.*sigy.*sigy))/sxx;
end

if plotopt
    h = figure; plot(x, B*x, '-', 'Color', [0.5 0.5 0.5]);
    hold on;
    plot(x, y, 'ko');
else
    h = [];
end

