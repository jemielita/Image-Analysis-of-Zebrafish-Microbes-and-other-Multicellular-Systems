% corr_notes_25Jan2012.m
%
% 3D two color bacteria image correlations
% calls normxcorr3.m for correlation
% calls imagebinRP.m for binning
% calls getrdist.m to get radial distribution of (3D) correlation functions
%
% Raghuveer Parthasarathy
% Jan. 25-26, 2012

% Load images
% cd 'C:\Users\Raghu\Documents\Experiments and Projects\Zebrafish_Microbiota_Gut\Dec_8_2011_Aeromonas\from 8Dec11 fish1'
fname = 'composite scan30 region2 1024x2048x64.tif';
inf = imfinfo('composite scan30 region2 1024x2048x64.tif');
Nframes = length(inf);
w = inf(1).Width;
h = inf(1).Height;
im_gr = zeros(h, w, Nframes, 'uint8');
im_red = zeros(h, w, Nframes, 'uint8');
for j=1:Nframes
    im = imread(fname, j);
    im_gr(:,:,j) = im(:,:,2);  % green channel
    im_red(:,:,j) = im(:,:,1);  % red channel
    if mod(j,5)==0
        disp(j)
    end
end
figure; imshow(im_gr(:,:,12),[])

%% Fourier Transform method -- works!
%  But don't do this -- real-space is better, and also easier to think
%  about
do_fft = false;
if do_fft
    % Subtraction
    back_gr = 20;
    sub_gr = single(im_gr)-back_gr;
    mean_gr = mean(im_gr(:));
    sub_gr = sub_gr - mean_gr;
    whos
    
    tic;     fft_gr = fftn(sub_gr);     toc
    clear sub_gr
    
    back_red = 25;
    sub_red = single(im_red)-back_red;
    mean_red = mean(im_red(:));
    sub_red = sub_red - mean_gr;
    whos
    
    tic;     fft_red = fftn(sub_red);     toc
    
    clear sub_red
end

%%
% Procedure:
%    filter
%    downsample
%    do correlation
%    Should perhaps do more thresohlding or filtering...

% Bandpass filtering
disp('Bandpass filtering')
im_gr = single(im_gr);  % to avoid annoying warning in bpass
im_red = single(im_red);
objsize = 91;
for k = 1:size(im_gr,3)
    % over-write image array, to save memory
    im_gr(:,:,k) = bpass(im_gr(:,:,k),1,objsize);
    im_red(:,:,k) = bpass(im_red(:,:,k),1,objsize);
end
figure('Name', 'Bandpass filtered #12'); imshow(im_gr(:,:,12),[])

% Downsample -- to make smaller, and to make bins equal sizes
% Bin "properly" -- I don't trust imresize
disp('Downsample')
binsize = round(1/0.1625);  % = ratio of z/xy scales
size(im_gr)
im_gr_small = imagebinRP(im_gr, binsize);
figure('Name', 'Binned #12'); imshow(im_gr_small(:,:,12),[])
im_red_small = imagebinRP(im_red, binsize);

% a subset in z
% im_red_small = im_red_small(:,:,5:16);
% im_gr_small = im_gr_small(:,:,5:16);

% to save memory
clear im_gr im_red im

%% 
pause(1)  % helps figures load?
disp('Correlation...')

% Cross-correlation
disp('Cross correlation...')
Cgr =  normxcorr3(double(im_gr_small), double(im_red_small), 'same');
% Green autocorrelation
disp('green...')
Cgg =  normxcorr3(double(im_gr_small), double(im_gr_small), 'same');
% Red autocorrelation
disp('red...')
Crr =  normxcorr3(double(im_red_small), double(im_red_small), 'same');

% Figures
midy = round((size(Cgr,1)+1)/2);
midx = round((size(Cgr,2)+1)/2);
midz = round((size(Cgr,3)+1)/2);
figure('Name', 'slice 12, Cgr'); surf(Cgr(:,:,12)); shading interp
figure('Name', 'slice 12, Cgg'); surf(Cgg(:,:,12)); shading interp
% Very crude cuts
figure; plot(Cgr(midy,:,midz), 'k-')
hold on
plot(Cgg(midy,:,midz), 'g-')
plot(Crr(midy,:,midz), 'r-')
title('C along x')
figure; plot(squeeze(Cgr(midy,midx,:)), 'k-')
hold on
plot(squeeze(Cgg(midy,midx,:)), 'g-')
plot(squeeze(Crr(midy,midx,:)), 'r-')
title('C along z')

%%
% Correlation as a function of radial distance
% define center as the location of the peak in Cgg, since it may be ~1px
% offset from the array center
[cm.y, cm.x, cm.z] = ind2sub(size(Cgg),find(Cgg==max(Cgg(:))));
% cm.x = (size(Cgg,2)+1)/2;
% cm.y = (size(Cgg,1)+1)/2;
% cm.z = (size(Cgg,3)+1)/2;
dr = 0.5; % bin size
[rpos_gg, rint_gg] = getrdist(Cgg, cm, dr);
[rpos_rr, rint_rr] = getrdist(Crr, cm, dr);
[rpos_gr, rint_gr] = getrdist(Cgr, cm, dr);
hC = figure; 
plot(rpos_gg, rint_gg, 'o-', 'color', [0 0.6 0.1], 'linewidth', 2.0, ...
    'markeredgecolor', [0 0.6 0.1], 'markerfacecolor', [0.3 0.8 0.5])
hold on
plot(rpos_rr, rint_rr, 'o-', 'color', [0.8 0.1 0], 'linewidth', 2.0, ...
    'markeredgecolor', [0.8 0.1 0], 'markerfacecolor', [1 0.4 0.2])
plot(rpos_gr, rint_gr, 'ko-', 'linewidth', 2.0, ...
    'markeredgecolor', [0 0 0], 'markerfacecolor', 0.7*[1 1 1])
%xlabel('Radial distance (px)')
%ylabel('Correlation')
xlabel('\rho (\mum)', 'Fontsize', 28)
ylabel('Correlation', 'Fontsize', 28)
legend('C_{gg}', 'C_{rr}', 'C{gr}')
legend boxoff
axis([0 15 0 1.1])
    set(gca,'fontsize', 22)
    %The following will change the tick label sizes, not the previously-made axis labels
    set(gca,'fontsize', 18)
    set(gca,'FontWeight', 'normal')


% Semilog plot
figure; semilogy(rpos_gg, rint_gg, 'o-', 'color', [0 0.6 0.1], 'linewidth', 2.0, ...
'markeredgecolor', [0 0.6 0.1], 'markerfacecolor', [0.3 0.8 0.5])
hold on
semilogy(rpos_rr, rint_rr, 'o-', 'color', [0.8 0.1 0], 'linewidth', 2.0, ...
'markeredgecolor', [0.8 0.1 0], 'markerfacecolor', [1 0.4 0.2])
semilogy(rpos_gr, rint_gr, 'ko-', 'linewidth', 2.0, ...
'markeredgecolor', [0 0 0], 'markerfacecolor', 0.7*[1 1 1])
xlabel('Radial distance (px)')
ylabel('Correlation (normalized)')
legend('C_{gg}', 'C_{rr}', 'C{gr}')
legend boxoff
axis([0 30 0.1 1.1])


% save corr_bin_bpass185_26Jan2012
