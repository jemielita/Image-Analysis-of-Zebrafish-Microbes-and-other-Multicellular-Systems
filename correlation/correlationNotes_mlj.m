% Image correlations
%
% Matthew Jemielita
%
% I don't really understand how to interpete image correlations-going to
% go through some examples


%% 

% Digital image processing using MATLAB, Gonzalez and Woods , has a section
% on image correlation in chapter 13-and give a decent example, though the
% discussion is somewhat limited

im = zeros(100,100);

pos = randi(100*100,20,1);

%Evenly spaced points
clear pos
pos(1,:)  = 1:5:100;
pos(2,:) = 1:5:100;

im([pos(1,:), pos(2,:)]) = 1;

g = normxcorr2(im, im);

figure; imshow(im);
figure; imshow(g);



%% one single bright point in image

im = zeros(100,100);
im(20,20) = 1;
im(22,22) = 1;
im(20,22) = 1;
im(22,20) = 1;
t = zeros(5,5);
t(2,4) = 1;
t(4,2) = 1;
t(2,2) = 1;
t(4,4) = 1;


g = normxcorr2(t,im);

figure; imshow(g,[])

[maxcc, ind]  = max(abs(g(:)));

[ypeak, xpeak ] = ind2sub(size(g), ind(1));
 corr_offset = [ (ypeak-size(t,1)) (xpeak-size(t,2)) ];

 
 
 %% Image of random points. Correlate with points offset by some amount
 
 clear pos
 im = zeros(100,100);
 pos(:,1) = randi(100,1,100);
 pos(:,2) = randi(100,1,100);
 ind = sub2ind(size(im), pos(:,1), pos(:,2));
 im(ind) = 1;
 
 r = 20;
 theta = 2*pi*rand(100,1);
 trans = [r*cos(theta), r*sin(theta)];
  
 imOff = zeros(100,100);
 posOff = pos+trans;
 posOff(posOff>100) = 100;
 posOff(posOff<1) = 1;
 posOff = round(posOff);
 
 ind = sub2ind(size(im), posOff(:,1), posOff(:,2));
 imOff(ind) = 1;
 %Calculate correlation between these points
 cc = normxcorr2(imOff, im);
 
 
 %Ring around the center of the image clearly visible
 figure; imshow(cc,[])
 %figure; imshow(im,[])
 cm.x = 100; cm.y = 100;
 dr = 1; % bin size
 [rpos, rint] = getrdist(cc, cm, dr);
 
plot(rpos, rint, 'color', [0 0.6 0.1], 'linewidth', 2.0, ...
    'markeredgecolor', [0 0.6 0.1], 'markerfacecolor', [0.3 0.8 0.5])
 