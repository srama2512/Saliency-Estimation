    function output_feat = getColorTextFeat( imdata, spdata, spind )
            output_feat = zeros( 1, imdata.nrgb + imdata.nLab + imdata.nLabHist + ...
                imdata.nhhist + imdata.nshist + 2*imdata.ntext + imdata.ntexton );
            
            imsegs = imdata.imsegs;
            sumpixels = sum( imsegs.npixels(spind) );
            
            for k = 1 : length(spind)
                f = imdata.nrgb + imdata.nLab;
                s = spind(k);
                output_feat(1:f) = output_feat(1:f) + spdata(s, 1:f) * imsegs.npixels(s);
                
                output_feat(f+[1:imdata.nLabHist]) = output_feat(f+[1:imdata.nLabHist]) + spdata(s, f+[1:imdata.nLabHist]);
                f = f + imdata.nLabHist;
                
                output_feat(f+[1:imdata.nhhist]) = output_feat(f+[1:imdata.nhhist]) + spdata(s, f+[1:imdata.nhhist]);
                f = f + imdata.nhhist;
                
                output_feat(f+[1:imdata.nshist]) = output_feat(f+[1:imdata.nshist]) + spdata(s, f+[1:imdata.nshist]);
                f = f + imdata.nshist;
                
                output_feat(f+[1:imdata.ntext]) = output_feat(f+[1:imdata.ntext]) + spdata(s, f+[1:imdata.ntext]) * imsegs.npixels(s);
                f = f + imdata.ntext;
                
                output_feat(f+[1:imdata.ntext]) = output_feat(f+[1:imdata.ntext]) + spdata(s, f+[1:imdata.ntext]);
                f = f + imdata.ntext;
                
                output_feat(f+[1:imdata.ntexton]) = output_feat(f+[1:imdata.ntexton]) + spdata(s, f+[1:imdata.ntexton]);
            end
            
            f = imdata.nrgb + imdata.nLab;
            output_feat(1:f) = output_feat(1:f) / sumpixels;
            
            output_feat(f+[1:imdata.nLabHist]) = output_feat(f+[1:imdata.nLabHist]) / sum( output_feat(f+[1:imdata.nLabHist]) );
            f = f + imdata.nLabHist;
            
            output_feat(f+[1:imdata.nhhist]) = output_feat(f+[1:imdata.nhhist]) / sum( output_feat(f+[1:imdata.nhhist]) );
            f = f + imdata.nhhist;
            
            output_feat(f+[1:imdata.nshist]) = output_feat(f+[1:imdata.nshist]) / sum( output_feat(f+[1:imdata.nshist]) );
            f = f + imdata.nshist;
            
            output_feat(f+[1:imdata.ntext]) = output_feat(f+[1:imdata.ntext]) / sumpixels;
            f = f + imdata.ntext;
            
            output_feat(f+[1:imdata.ntext]) = output_feat(f+[1:imdata.ntext]) / sum( output_feat(f+[1:imdata.ntext]) );
            f = f + imdata.ntext;
            
            output_feat(f+[1:imdata.ntexton]) = output_feat(f+[1:imdata.ntexton]) / sum( output_feat(f+[1:imdata.ntexton]) );
    end % end of function getColorTextFeat