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
% last modified August 10, 2010 -- changes to colors, plotting 1-track

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

hold on
for j=unqtracks
    tr = objs(:, ismember(objs(6,:),j));  % object matrix only with track j
    Ntr = size(tr,2);
    if Ntr>Nmin
        if Ntr==1
            % just a single frame
            plot(tr(1), tr(2), '.', 'Color', [j/max(unqtracks) 1.0 0.5]);
        else
            for k=1:(Ntr-1),
                line([tr(1,k) tr(1,k+1)], [tr(2,k) tr(2,k+1)], ...
                    'Color', [j/max(unqtracks) 1.0 1.0-j/max(unqtracks) ]);
                % strange -- not allowing broad range of colors
                % using (k-1)/(Ntr-1) for the blue color leads to all black
                % images -- some problem with the color space.
            end
        end
    end
end
