function h = bpfilter(objsize)

% h = bpfilter(objsize)
% creates a bandpass filter for objects of diameter objsize
%
% R. Parthasarathy
% based on Andrew Demond's program, based on MATLAB examples
% 28 May 2007 -- remove 'hole' in intensity at low f
% last modified 28 May 2007

[f1,f2] = freqspace(objsize*2+1,'meshgrid');
Hd = ones(size(f1));
r = sqrt(f1.^2 + f2.^2);
%figure; surf(Hd)
%Hd((r<.1) | (r>.5)) = 0; % frequency space chosen more or less ad hoc
Hd(r>.5) = 0; % frequency space chosen more or less ad hoc
%figure; surf(Hd)
h = fsamp2(Hd);
