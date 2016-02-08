clear all;
close all;
clc;

name = '/home/santhosh/Desktop/Personal/Coding/MatlabCodes/Saliency/NewModel/Image';
name_anno = '/home/santhosh/Desktop/Personal/Coding/MatlabCodes/Saliency/NewModel/annotation';
addpath(genpath('/home/santhosh/Desktop/Personal/Coding/MatlabCodes/Saliency/BSR'));
addpath(genpath('/home/santhosh/Desktop/Personal/Coding/MatlabCodes/Saliency/randomforest-matlab/RF_Reg_C'));
addpath(genpath(name));
addpath('/home/santhosh/Desktop/Personal/Coding/MatlabCodes/Saliency/Gabor');
addpath(genpath('.'));

bandwidthRGB = 5:5:50;
bandwidthHSV = 1:1.5:14.5;
bandwidthLAB = 1:10;

load('./trained_classifiers/same_label_classifier_200_20.mat');
classifiers.same_label_classifier = same_label_classifier;
classifiers.ecal = ecal;

colorSpace = 'hsv'; %the colorspace can be 'hsv', 'rgb', or 'lab'.
numSP = 600;   %number of initial superpixels
spType = 'ERS'; %type of superpixel segmentation, 'ERS' or 'SLIC'.
bandwidthLvl = 3;   %can be from 1 ~ 10, basically it is the level of bandwidth from the 10 default values above.

if strcmp(colorSpace, 'hsv')
    bandwidthCS = bandwidthHSV;
elseif strcmp(colorSpace, 'rgb')
    bandwidthCS = bandwidthRGB;
else
    bandwidthCS = bandwidthLAB;
end

sp_method = 'pedro';

listing = dir(name);
gaborArray = gaborFilterBank(5, 8, 39, 39);

same_label_classifier = classifiers.same_label_classifier;
ecal = classifiers.ecal;
       
para = makeDefaultParameters();
num_segmentation = para.num_segmentation;
ind = para.ind;

% Parameters for multiple segmentations
k = [5:5:35 40:10:120 150:30:600 660:60:1200 1300:100:1800];
k = k(ind(1 : num_segmentation)); 

features_train = [];
labels_train = [];

for i1=3:length(listing)
    foldPath = (listing(i1).name);
    images = dir(fullfile([name, '/', foldPath], '*.jpg'));
    for i2=1:length(images)
        img = imread([name,'/', foldPath, '/', images(i2).name]);
        name_annotation = [name_anno, '/', strrep(images(i2).name, 'jpg', 'png')];
        img_annotation = imread(name_annotation);
        
        textons = [];
        imsegs = im2superpixels(img, sp_method );
        imdata = getImageData(img, textons, imsegs);
        
        % Generate the features to predict the similarity of two adjacent regions
        
        spfeat = getSuperpixelData(imdata);
        pgbfeat = getPbgFeat(imdata);
        efeat = getEdgeData( spfeat, imdata );
        
        same_label_likelihood = test_boosted_dt_mc( same_label_classifier, efeat );
        same_label_likelihood = 1 ./ (1+exp(ecal(1)*same_label_likelihood+ecal(2)));
        
        nSuperpixel = imdata.imsegs.nseg;
        multi_segmentations = mexMergeAdjRegs_Felzenszwalb( imdata.adjlist, same_label_likelihood, nSuperpixel, k, imsegs.npixels );
        
        nsegment = size(multi_segmentations, 2);
                
        all_maps = struct;
        
        for s = 1 : nsegment
            spLabel = multi_segmentations(:, s);
            segment = unique( spLabel );
            
            % discard those too fine segmentations
            if (length(segment) / nSuperpixel) > 0.5
                all_maps(s).image = zeros(imh, imw);
                continue;
            end
            
            saliency_feat = getSegmentSaliencyFeat( imdata, spfeat, pgbfeat, spLabel, segment, gaborArray);
            
            features_train = [features_train; saliency_feat];
        end; 
    end;
end;
