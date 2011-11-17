% simpsonint.m
% 
% function to integrate y dx using Simpson's rule, where y is an array
%  ( y is the value of the integrand at n points, which include the ends)
% If there are an odd number of intervals (even number of points), calc.
%    the odd section using the trapezoidal rule.
%
% Raghuveer Parthasarathy
% Dec. 16, 2010
% based on earlier code by Kendra Nyberg and RP, Fall 2010

% notation similar to http://en.wikipedia.org/wiki/Simpson%27s_rule,
% except that the first index is 1, not 0; we have n-1 intervals

function integ = simpsonint(y, dx)

n = length(y);

% If there are an odd number of intervals (even number of points) determine
% whether to use trapezoidal integration on the beginning or ending segment
% based on which has a more steeply varying y.


if (mod(n,2)==0)
    % odd number of intervals (even number of points)
    if abs(y(n)-y(n-1)) < abs(y(2)-y(1))
        % variation is less at end
        ycut = y(1:n-1);
        oddinteg = (1/2.0)*(y(n)+y(n-1));
    else
        % variation is less at beginning
        ycut = y(2:n);
        oddinteg = (1/2.0)*(y(1)+y(2));
    end
else
    ycut = y;
    oddinteg = 0.0;
end
nint = length(ycut)-1;
sum1 = sum(ycut(3:2:nint-1));
sum2 = sum(ycut(2:2:nint));
integsum = (1/3)*(ycut(1) + 2*sum1 + 4*sum2 + ycut(nint+1)) + oddinteg;

integ = integsum*dx;
