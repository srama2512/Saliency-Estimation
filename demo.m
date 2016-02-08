addpath(genpath('/home/santhosh/Desktop/Personal/Coding/MatlabCodes/Saliency/BSR'));
addpath(genpath('/home/santhosh/Desktop/Personal/Coding/MatlabCodes/Saliency/randomforest-matlab/RF_Reg_C'));

addpath(genpath('.'));

%image_name = '/home/santhosh/Downloads/BenchmarkIMAGES/SM/i8.jpg';
image_name = '/home/santhosh/Desktop/Personal/Coding/MatlabCodes/Saliency/NewModel/DemoImages/foodimage1.jpg';
image = imread( image_name );
image = imresize(image, [1000, uint8(1000*size(image,2)/size(image,1))]);

bandwidthRGB = 5:5:50;
bandwidthHSV = 1:1.5:14.5;
bandwidthLAB = 1:10;

colorSpace = 'hsv'; %the colorspace can be 'hsv', 'rgb', or 'lab'.
numSP = 600;   %number of initial superpixels
toShow = 1;    %show intermediate results? 1 = yes, 0 = no.
spType = 'ERS'; %type of superpixel segmentation, 'ERS' or 'SLIC'.
bandwidthLvl = 3;   %can be from 1 ~ 10, basically it is the level of bandwidth from the 10 default values above.
labels = mex_ers(double(image),numSP);

if strcmp(colorSpace, 'hsv')
    bandwidthCS = bandwidthHSV;
elseif strcmp(colorSpace, 'rgb')
    bandwidthCS = bandwidthRGB;
else
    bandwidthCS = bandwidthLAB;
end

out = spMergeMS(image, [], labels, 0, bandwidthCS(bandwidthLvl), colorSpace, toShow );

meanPBSegments = out{1};     %a scalar: number of proto-objects using mean color

clutter = meanPBSegments/numSP;

% load classifiers
% classifier for multiple segmentations
load('./trained_classifiers/same_label_classifier_200_20.mat');
classifiers.same_label_classifier = same_label_classifier;
classifiers.ecal = ecal;

% classifier for saliency regression
load( './trained_classifiers/segment_saliency_regressor_48_segmentations_MSRA_200_15_compressed_rf.mat' );
classifiers.segment_saliency_regressor = segment_saliency_regressor;

% parameters including the number of segmentations and saliency fusion
% weight
para = makeDefaultParameters();

% textons are obtained from the gPb edge detector
% if textons are not provided, they will be computed automatically
%gpb_file_name = [image_name(1:end-4), '.mat'];
%gpb_data = load( gpb_file_name, 'textons' );
gpb_data = [];
t = tic;
[smap, smap1, smap2, smap3] = Saliency_DRFI_gen( image, classifiers, para, gpb_data, clutter );
% smap = Saliency_DRFI( image, classifiers, para, [] );
time_cost = toc(t);
fprintf( 'time cost for saliency computation using DRFI approach: %.3f\n', time_cost );
figure(1)
imshow(image);
figure(2)
imshow(smap);
figure(3)
imshow(smap1);
imwrite(image, 'image.png');
imwrite(smap, 'image_drfi_t.png');
imwrite(smap1, 'image_improved_t.png');
imwrite(smap2, 'image_drfi.png');
imwrite(smap3, 'image_improved.png');
