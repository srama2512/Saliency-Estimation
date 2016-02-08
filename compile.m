cd ./multi-segmentation
disp( 'mex mexMergeAdjRegs_Felzenszwalb.cpp' );
mex mexMergeAdjRegs_Felzenszwalb.cpp
cd ..

cd ./segment
disp( 'mex mexSegment.cpp' );
mex mexSegment.cpp
cd ..

cd ./boosting
disp( 'mex treevalc.cpp' );
mex treevalc.cpp
cd ..
