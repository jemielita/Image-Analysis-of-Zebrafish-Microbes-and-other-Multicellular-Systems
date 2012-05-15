function f = plotOpResults(varargin)
figure;

if(nargin==2)
    minS = varargin{1};
    maxS = varargin{2};
else
    minS = 46;
    maxS = 144;
end

for i=minS:maxS
    
    convex = load(['OP_Scan', sprintf('%03d', i), 'convex.mat']);
   % outline = load(['OP_Scan', sprintf('%03d', i), 'perim.mat']);
    
    perim = convex.perim;
    
    %perimVal = outline.perimVal;
    %endpts = outline.endpts;
    
    h1 = subplot(1,2,1);
    if(i==minS)
        hP1 = plot3(perimVal(:,1), perimVal(:,2), perimVal(:,3), '*', 'MarkerSize',1);
        axis equal
        hold on
        hP2 = plot3(endpts(:,1), endpts(:,2), endpts(:,3), 'k-');
        
        h2 = subplot(1,2,2);
        hP3 = plot(perim);
        set(h2, 'YLim',[40 400]);
        
        set(h1, 'YLim', [81, 500]);
        set(h1, 'ZLim', [0 400]);
    else
       set(hP1, 'XData', perimVal(:,1));
       set(hP1, 'YData', perimVal(:,2));
       set(hP1, 'ZData', perimVal(:,3));
       
       set(hP2, 'XData', endpts(:,1));
       set(hP2, 'YData', endpts(:,2));
       set(hP2, 'ZData', endpts(:,3));
       
       set(hP3, 'XData', 1:length(perim));
       set(hP3, 'Ydata', perim);
    end
       
    f(i-1) = getframe;
    pause
    
end


end