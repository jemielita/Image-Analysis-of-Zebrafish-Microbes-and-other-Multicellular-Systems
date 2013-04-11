function out = sphrichardson(wav, n, gamma, varargin)
% \manchap
%
% \mansecSyntax
%
% [] = sphrichardson()
%
% \mansecDescription
%
% \mansubsecInputData
% \begin{description}
% \item[] []: 
% \end{description} 
%
% \mansubsecOutputData
% \begin{description}
% \item[] []:
% \end{description} 
%
% \mansecExample
% \begin{code}
% >>
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
% $Header: /home/cvs/yawtb/frames/sphere/sphrichardson.m,v 1.1 2003-08-12 16:10:34 ljacques Exp $
%
% Copyright (C) 2001-2002, the YAWTB Team (see the file AUTHORS distributed with
% this library) (See the notice at the end of the file.)

g = getopts(varargin,'g',[]);

if isempty(g)
  g = ifwtsph(wav);
end

out = wav.img * 0;


for k = 1:n,
  
  if (k == 1) 
    Lout = 0;
  else
    Lout = ifwtsph(fwtsph(out, wav.wavname, wav.J, wav.extra{:}));
  end
  
  old_out = out;
  out = out + gamma*(g - Lout);
  converg_dist = max(abs(out(:) - old_out(:)));
  fprintf('Distance: %e\n', converg_dist);
end


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
