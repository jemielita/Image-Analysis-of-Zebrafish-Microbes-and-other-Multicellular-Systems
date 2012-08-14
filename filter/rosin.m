%
% T = RosinThreshold(imhist, picknonempty)
%
% Compute the Rosin threshold for an input histogram.
% T is the histogram index that should be used as a threshold.
% The optional second argument "picknonempty" is a binary variable
% indicating that the chosen bin should be non-zero.
%
% REF: Paul L. Rosin, "Unimodal thresholding", Pattern Recognition 34(11): 2083-2096 (2001)
%
function T = RosinThreshold(imhist, picknonempty)

% should I ensure the chosen(threshold) bin is non empty?
if (nargin < 2)
    picknonempty = 0;
end

% find best threshold

[mmax2, mpos] = max(imhist);
p1 = [mpos, mmax2];

% find last non-empty bin
L = length(imhist);
lastbin = mpos;
for i = mpos:L
    if (imhist(i) > 0)
        lastbin=i;
    end
end
    
p2 = [lastbin, imhist(lastbin)];
DD = sqrt((p2(1)-p1(1))^2 + (p2(2)-p1(2))^2);

if (DD ~= 0)
	best = -1;
	found = -1;
	for i = mpos:lastbin
        p0 = [i,  imhist(i)];
        d = abs((p2(1)-p1(1))*(p1(2)-p0(2)) - (p1(1)-p0(1))*(p2(2)-p1(2)));
        d = d / DD;
        
        if ((d > best) && ((imhist(i)>0) || (picknonempty==0)))
            best=d;
            found = i;
        end
	end
	
	if (found == -1)
        found = lastbin+1;
	end
else
    found = lastbin+1;
end


T = min(found, L);

