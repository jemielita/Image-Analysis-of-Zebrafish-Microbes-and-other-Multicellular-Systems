%Calculate the widths of multiple opercles

function [] = multipleOpWidth(varargin)
if nargin ==3
    fileDir = varargin{1};
    sMin = varargin{2};
    sMax = varargin{3};
elseif nargin==0
    fileDir = uigetdir('C:\Jemielita\markers', 'Select directory to load markers from');
    sMin = 1;
    sMax = 144;
end


for i=sMin:sMax
    
    fN = [fileDir filesep 'OP_Scan', sprintf('%03d', i), 'convex.mat'];
    varIn = load(fN);
    
    convexPt = varIn.convexPt;
    linePt = varIn.linePt;
    fN
    
    perim = opAverage(convexPt, 20, 'ave');
    
    conF = [fileDir, filesep,'OP_Scan', sprintf('%03d', i), 'convex.mat'];
    save(conF,'perim', '-append');
end

end