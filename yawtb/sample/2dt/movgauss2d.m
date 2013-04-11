function [out] = movgauss2d(nt,n)
% \manchap
% 
% Create a three moving Gaussians on the 2-D plane.
%
% \mansecSyntax
% [out] = movgauss([nt] [,n])
%
% \mansecDescription
%
% This function creates three moving Gaussians on the plane with
% speeds equal to 1, 0.5, -1 pixel/frame in particular directions.
%
% \mansubsecInputData
% \begin{description}
% \item[nt, n] [INTEGERS]: the number of times and positions
% (default $64\times 64 \times 64$).
% \end{description} 
%
% \mansubsecOutputData
% \begin{description}
% \item[out] [DOUBLE VOLUME]: a nt $\times$ n $\times$ n volume containing the three
% moving Gaussians.
% \end{description} 
%
% \mansecExample
% \begin{code}
% >> mov = movgauss2d;
% >> %% Displaying it as levelset in a volume with yashow
% >> yashow(wav); 
% \end{code}
%
% \mansecReference
%
% \mansecSeeAlso
%
% \mansecLicense
%
% This file is part of YAW Toolbox (Yet Another Wavelet Toolbox)
% You can get it at
% \url{"http://www.fyma.ucl.ac.be/projects/yawtb"}{"yawtb homepage"} 
%
% $Header: /home/cvs/yawtb/sample/2dt/movgauss2d.m,v 1.1 2009-06-30 10:16:13 jacques Exp $
%
% Copyright (C) 2001, the YAWTB Team (see the file AUTHORS distributed with
% this library) (See the notice at the end of the file.)

%% Handling the inputs
if ~exist('nt')
  nt = 64;
end

if ~exist('n')
  n = 64;
end

%% Generating the sample
[X,Y,T] = meshgrid( 0:(n-1), 0:(n-1), 0:(nt-1));
Z = X + i*Y;
clear X Y;

nt_1  = nt-1;
n_1  = n-1;

% Initial position
z1    = 0;
z2    = n + i*n;
z3    = n;

% Velocities
v1    = 1 + i; v1 = v1/abs(v1);
v2    = -v1;
v3    = -1 + i; v3 = .5 * v3/abs(v3); 

% Gaussians' Sizes (If you want to modify them...)
s1    = 1;
s2    = 1; 
s3    = 1; 

% Seperated Gaussians
g1 = exp(-abs(Z - (z1 + v1*T)).^2/(2*s1^2));
g2 = exp(-abs(Z - (z2 + v2*T)).^2/(2*s2^2));
g3 = exp(-abs(Z - (z3 + v3*T)).^2/(2*s3^2));

% Mixing of the gs.
out = max(g1,g2);
out = max(out,g3);


% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
