function [bbox, scores] = suggest_bboxes(I, ref_score)
    if nargin < 2
       ref_score = 0.65; 
    end
    I_resized = imresize(I, [224 224]);
    persistent NN
    if isempty(NN)
        load('detector.mat');
        NN = detector;
    end
    [bboxes, scores] = detect(NN, I_resized);
    idx = scores > ref_score;
    bbox = preprocess_bbox(bboxes(idx,:), I);
    scores = scores(idx);
end