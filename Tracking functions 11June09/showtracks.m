% showtracks.m
% 
% Program to plot the tracks of found objects.
% Colors the tracks with increasing brightness proportional to "frame"
%
% Input: 
%    objs = object matrix, in which row 6 contains the "track ids" for
%           the tracks found by (e.g.) nnlink_rp.m
%    Nmin = minimal track length -- only display tracks with >Nmin points
%           leave empty ("[]") or set equal to 0 to use all tracks
%    h (optional) = the handle to a figure window in which to draw the
%        tracks.  If h is not supplied, create a new figure window.
% 
% Raghuveer Parthasarathy
% 23 April, 2007
% last modified June 23, 2008

function showtracks(objs, Nmin, h)

unqtracks = unique(objs(6,:)); % get track numbers


if or((nargin < 2), isempty(Nmin))
    Nmin = 0;  % display all tracks
end

if (nargin < 3)
    figure;
else
    figure(h);
end

for j=unqtracks
    tr = objs(:, ismember(objs(6,:),j));  % object matrix only with track j
    Ntr = size(tr,2);
    if Ntr>Nmin
        for k=1:(Ntr-1),
            line([tr(1,k) tr(1,k+1)], [tr(2,k) tr(2,k+1)], ...
                'Color', [0.7 0.7 0.0] + 0.25*(k-1)/(Ntr-1));
            % strange -- not allowing broad range of colors
        end
    end
end
