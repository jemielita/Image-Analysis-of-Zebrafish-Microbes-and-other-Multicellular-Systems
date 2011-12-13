hFig = figure; 
hAxis = axes('Parent', hFig);

hold on
cData = jet(11);
for i=1:11
    
 p =    plot3(com(i,:,2), com(i,:,1), com(i,:,3));
    set(p, 'Color', cData(i,:));
    
end
hold off