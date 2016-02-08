function [smap,smap1,smap2,smap3] = Saliency_DRFI( image, classifiers, para, textons, clutter )
    % image       [input] image with type of uint8, can be got using imread
    % classifiers [input] used for multi-level segmentation, and saliency
    %             regression
    % para        [input] parameters including the number of segmentations and
    %             saliency fusion weight
    % textons     [input] texture features. If not provided, will be computed 
    
    % smap        [output] saliency map with type of uint8
    
    num_segmentation = para.num_segmentation;
    
    % Boosted decision tree classifier for multiple segmentations, which will be used to compute
    % the similarity of two adjacent regions.
    % This part is not covered in details in the paper due to limited
    % space.
    same_label_classifier = classifiers.same_label_classifier;
    ecal = classifiers.ecal;
    
    % Random forest classifier for saliency regression
    segment_saliency_regressor = classifiers.segment_saliency_regressor;
    
    %Tthe approach to generate superpixels
    sp_method = 'pedro';        
    
    % Weights used for saliency fusion
    w = para.w;
    ind = para.ind;
    
    % Parameters for multiple segmentations
    k = [5:5:35 40:10:120 150:30:600 660:60:1200 1300:100:1800];
    k = k(ind(1 : num_segmentation)); 
    
    [imh imw imc] = size(image);
    
    % Generate superpixels
    imsegs = im2superpixels(image, sp_method );    
    
    % Get proprocessed features, which will be used in the following feature extraction steps 
    imdata = getImageData( image, textons, imsegs );
    spfeat = getSuperpixelData( imdata );

    % Generate the features to predict the similarity of two adjacent regions
    efeat = getEdgeData( spfeat, imdata );
    
    % predict the similarity of two adjacent regions
    same_label_likelihood = test_boosted_dt_mc( same_label_classifier, efeat );
    same_label_likelihood = 1 ./ (1+exp(ecal(1)*same_label_likelihood+ecal(2)));
    
    % contruct the graph on superpixels, where the adjacent regions are connencted. 
    % The graph-based segmentation algorithm (P. Felzenszwalb, D. Huttenlocher, 2004) 
    % is then exploited to produce multiple segmentations by varying the
    % parameter k. This approach is equivalent to the method described in
    % our CVPR paper to produce hierarichical segmentations. But is more
    % efficient since we have to compute the similarity of adjacent regions
    % once to construct the graph.
    nSuperpixel = imsegs.nseg;
    multi_segmentations = mexMergeAdjRegs_Felzenszwalb( imdata.adjlist, same_label_likelihood, nSuperpixel, k, imsegs.npixels );
    
    % a "segment" indicates a "region"
    nsegment = size(multi_segmentations, 2);
    
    % extract features of the pseudo-background
    pbgfeat = getPbgFeat( imdata );
    
    smap = zeros(imh, imw);
    smap1 = zeros(imh, imw);
   
    all_maps = struct;
    
    
    % extract segment (region) saliency features and run saliency
    % regression on multi-level segmentation
    for s = 1 : nsegment
        spLabel = multi_segmentations(:, s);
        segment = unique( spLabel );
        
        % discard those too fine segmentations
        if (length(segment) / nSuperpixel) > 0.5
            all_maps(s).image = zeros(imh, imw);
            continue;
        end
        
        % segment saliency features         
        saliency_feat = getSegmentSaliencyFeat( imdata, spfeat, pbgfeat, spLabel, segment );
        % saliency_feat(:, 27:52) = [];
        
        % saliency regression
        segment_saliency_probability = regRF_predict(saliency_feat, segment_saliency_regressor);
        
        % normalization
        segment_saliency_probability = (segment_saliency_probability - min(segment_saliency_probability)) / ...
                    (max(segment_saliency_probability) - min(segment_saliency_probability) + eps);
        
        % propogate saliency from segment to superpixels
        temp_smap = zeros(imh, imw);
        for sp = 1 : length(spLabel)
            ind = segment == spLabel(sp) ;
            temp_smap(imdata.spstats(sp).PixelIdxList) = segment_saliency_probability( ind );
        end
        
        % saliency map fusion
        % a little bit tricky, 
        % exp() is used to enhance the difference of the saliency between the object and the background
        smap = smap1 + w(s) * exp( 1.5 * temp_smap*(2*clutter)^(3*(nsegment - s)/nsegment));    
        %smap = smap + w(s) * exp(1.5*temp_smap); 
        
        all_maps(s).image = temp_smap;
        
        imname = strcat('smap',num2str(s),'.jpg');
        imwrite(temp_smap, imname);
        
    end
    
    for i = 1:nsegment
        for j=1:nsegment
            
            smap1 = smap1+(all_maps(i).image).*(all_maps(j).image);
        end;
    end;
    
    smap1 = smap1/(nsegment*nsegment);
    
    % post-processing
    smap = smap / num_segmentation;
    smap1 = smap1/num_segmentation;
    
    smap = (smap - min(smap(:))) / (max(smap(:)) - min(smap(:)) + eps) * 255;
    smap = uint8(smap);
    
    smap1 = (smap1 - min(smap1(:))) / (max(smap1(:)) - min(smap1(:)) + eps) * 255;
    smap2 = smap;
    smap( smap < 0.8*sum(smap(:))/size(smap(:),1)) = 0;
    smap( smap >= 0.8*sum(smap(:))/size(smap(:),1)) = 255;
   
    smap3 = smap1;
    smap1( smap1 < 0.8*sum(smap1(:))/size(smap1(:),1)) = 0;
    smap1( smap1 >= 0.8*sum(smap1(:))/size(smap1(:),1)) = 255;
    smap1 = uint8(smap1);
    smap3 = uint8(smap3);
    smap2 = uint8(smap2);
    
       
end
