%neutrophilLink: Link together segmented neutrophils to get a trajectory
%for them through the organism


function [] = neutrophilLink(dirName, minS, maxS,displayTrack)


%%Display all the found tracks
if(displayTrack==true)
   
    hF = figure;
   for nS=minS:maxS
       load([dirName filesep 'seg_' num2str(nS), '.mat']);

       axes;
       hMax = imshow(imMax,[0 1000]);
       hold on
       for n =1:size(neutPos,1)
           cM = jet(round(max(neutPos(:,3))));
       hP = plot(neutPos(n,1), neutPos(n,2), 'o', 'MarkerSize', 10, ...
           'Color',cM(round(neutPos(n,3)),:));
       
       end
       pause(2);
       cla
      
   end
   
   
    
    
end



end