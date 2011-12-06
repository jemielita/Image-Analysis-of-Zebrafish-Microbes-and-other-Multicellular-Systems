img = double(imread('testImage.tif'));
[detectionResults, detectionMask] = spotDetector(img);

figure; 
subplot(1,2,1); imagesc(frame); colormap(gray(256)); axis image; title('Input');
subplot(1,2,2); imagesc(detectionMask); axis image; title('Detection');