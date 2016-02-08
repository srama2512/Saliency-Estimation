function para = makeDefaultParameters()
    % number of segmentations
    para.num_segmentation = 15;
    
    % saliency fusing weight
    load( './trained_classifiers/learned_fusion_weight.mat' );
    [sw ind] = sort(w, 'descend');
    w = sw(1 : para.num_segmentation );
    w = w / sum(w);     % normalization
    
    para.w = w;
    para.ind = ind(1 : para.num_segmentation);
end