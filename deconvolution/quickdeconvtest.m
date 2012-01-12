% quickdeconvtest.m
% Simple / quickly written script to call wfmpsf_SPIM and generate a point
% spread function for light sheet microscopy.
% 
% Raghuveer Parthasarathy
% Dec. 2011 -- Jan. 2012

% Parameters
sigmaz = 7000;   % nm, Gaussian width of sheet in z
numAper = 1.0;   % NA to use in the calculation
lambdaEm = 532;  % emission wavelength, nm
magObj = 28;  % Magnification.  Nominally 40; alter to deal with scale problem (see deconv. notes 1 Jan 2012); 
rindexObj = 1.33;
ccdSize = 6500;  % ccd pixel size, nm
rindex_sp = 1.44; % index of specimen.  Doesn't matter if depth = 0
dz = 1000;  % nm per slice
xysize = 64; % xy pixel dimension for psf
nslices = 2*round(2*sigmaz/dz + 2*lambdaEm/dz);  
depth = 0; % 10000;
nor = 1;   % normalize to max==1

%cd 'C:\Users\Raghu\Documents\Experiments and Projects\Light Sheet Microscope\Image Analysis\wfmpsf\wfmpsf'

% Calculate the psf
psf = wfmpsf_SPIM(sigmaz, lambdaEm, numAper, magObj, rindexObj,  ccdSize, dz, xysize, nslices, rindex_sp, depth, nor);

%cd 'C:\Users\Raghu\Documents\Experiments and Projects\Light Sheet Microscope\Image Analysis\Deconvolution'

% Intensity plots, through the midpoint along z and x
figure; plot(squeeze(psf(floor(xysize/2)+1, floor(xysize/2)+1, :)), 'ko-')
xlabel('z'); ylabel('Intensity'); title('intensity along depth')
figure; plot(squeeze(psf(:,floor(xysize/2)+1, round((nslices+1)/2))), 'bd-')
xlabel('x'); ylabel('Intensity'); title('intensity along x, at center depth')

% For outputting the PSF as an image stack
outputfile = false;
if outputfile
    mp = max(psf(:));  % not necessary, since function outputs max==1
    psffilename = 'psf_spim_sz7um_NA1p0_mag28.tif';
    for j=1:size(psf,3)
        imwrite(uint16(psf(:,:,j)*65536)/mp, psffilename, 'writemode', 'append');
    end
end
