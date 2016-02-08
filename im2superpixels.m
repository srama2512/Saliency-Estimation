function imsegs = im2superpixels(im, method, seg_para )
    if nargin < 3
        % default parameters to generate superpixels
        seg_para.sigma = 0.8;
        seg_para.k     = 100;
        seg_para.min_size = 100;
        seg_para.num_superpixel = 300;
        
        if nargin == 1
            method = 'SLIC';
        end
    end

%     prefix = num2str(floor(rand(1)*10000000));
%     fn1 = ['./tmpim' prefix '.ppm'];
%     fn2 = ['./tmpimsp' prefix '.ppm'];
%     segcmd = ['E:\playerkk\code\MATLAB\segment\segment ', num2str(seg_para(1)),... 
%         ' ', num2str(seg_para(2)), ' ', num2str(seg_para(3))];
% 
%     imwrite(im, fn1);
%     system([segcmd ' ' fn1 ' ' fn2]);
    if isa(im, 'uint8')
        im = double(im);
    end
    
    if max(im(:)) < 10
        im = double(im * 255);
    end
    
    switch method
        case 'pedro'
            segim = mexSegment(im, seg_para.sigma, seg_para.k, int32(seg_para.min_size));
        %case 'SLIC'
        %    segim = uint8(mexSLIC(uint32(im), seg_para.num_superpixel));
        otherwise
            error( 'unknown method to generate superpixels.' );
    end
    imsegs = processSuperpixelImage(segim);
