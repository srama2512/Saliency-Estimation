function w = LearnSaliencyFusionWeight( train_dir, gt_dir, num_segmentation, is_resize )
    % Assume that all training images are placed under train_dir.
    % The saliency maps of ith segmentation are under the folder "i" (e.g., 
    % saliency maps of 3rd segmentation are under the folder "3").
    % Detailed introduction on learning the saliency fusion weight can be
    % found in our supplementary material.
    
    % Resize all training images to a fixed size 200*200
    sub_dir_list = dir(fullfile(train_dir, '*'));
    
    ind = [];
    for ix = 1 : length(sub_dir_list)
        if strcmp(sub_dir_list(ix).name, '.') || strcmp(sub_dir_list(ix).name, '..')
            ind = [ind ix];
            continue;
        end
    end
    
    % Remove '.' and '..'
    sub_dir_list(ind) = [];
    
    % Resize
    if is_resize
        for ix = 1 : length(sub_dir_list)
            image_list = dir(fullfile(train_dir, sub_dir_list(ix).name, '*.png'));

            for jx = 1 : length(image_list)
                image = imread(fullfile(train_dir, sub_dir_list(ix).name, image_list(jx).name));

                image = imresize(image, [200 200]);

                imwrite(image, fullfile(train_dir, sub_dir_list(ix).name, image_list(jx).name));

                if mod(jx, 500) == 0
                    fprintf( 'sub_dir: %s, jx: %d\n', sub_dir_list(ix).name, jx );
                end
            end
        end
    end
    
    image_list = dir(fullfile(train_dir, sub_dir_list(end).name, '*.png'));
    
    % prepare H and f
    H = zeros(num_segmentation, num_segmentation);
    f = zeros(num_segmentation, 1);
    
    for ii = 1 : num_segmentation * num_segmentation
        [ix jx] = ind2sub([num_segmentation num_segmentation], ii);
        for n = 1 : length(image_list)
            Ani = im2double(imread(fullfile(train_dir, sub_dir_list(ix).name, image_list(n).name)));
            Anj = im2double(imread(fullfile(train_dir, sub_dir_list(jx).name, image_list(n).name)));

            H(ix, jx) = H(ix, jx) + sum(sum(Ani .* Anj));
            % fprintf( 'ix: %d, jx: %d, n: %d\n', ix, jx, n );
        end
        fprintf( 'Computing H, ix: %d, jx: %d\n', ix, jx );
    end
    H = H * 2;

    for ix = 1 : num_segmentation   
        for n = 1 : length(image_list)
            Ani = im2double(imread(fullfile(train_dir, sub_dir_list(ix).name, image_list(n).name)));
            A = imread(fullfile(gt_dir, image_list(n).name));
            A = im2double(imresize(A, [200 200]));
            
            
            f(ix) = f(ix) - 2 * sum(sum(A .* Ani));
        end     
        
        fprintf( 'comupting f, ix: %d\n', ix );
    end   
    
    H = H / length(image_list);
    f = f / length(image_list);
    
    % Solve the quadratic programming problem
    w_init = ones(num_segmentation, 1) / num_segmentation;
    
    Aeq = ones(1, num_segmentation);
    beq = 1;
    
    lb = zeros(num_segmentation, 1);
    ub = ones(num_segmentation, 1);
    
    opt = optimset( 'Algorithm', 'active-set' );
    w = quadprog(H, f, [], [], Aeq, beq, lb, ub, w_init, opt );
    
    w( w < 1e-6 ) = 0;
end