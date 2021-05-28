function [bbox, scores] = suggest_bboxes(I, ref_score)
    if nargin < 2
        ref_score = 0.55;
    end
    I_resized = imresize(I, [224 224]);
    persistent NN
    if isempty(NN)
        NN = download_detect_file_if_not_present();
    end
    [bboxes, scores] = detect(NN, I_resized);
    idx = scores > ref_score;
    bbox = preprocess_bbox(bboxes(idx,:), I);
    scores = scores(idx);
end

function NN = download_detect_file_if_not_present()
    script_folder = mfilename('fullpath');
    slash = '\\';
    if isunix()
        slash = '/';
    end
    script_folder = regexprep(script_folder,[slash '\w+(_*\w*)*$'],'');
    
    return_folder = cd(script_folder);
    NN = [];
    ME = MException.empty();
    
    if exist('detector.mat','file') ~= 2 %downloads from pcloud the detector    
        NN_path = [];
        try
            f = msgbox('Downloading detector from Dropbox link');
            NN_path = websave('detector.mat', 'https://www.dropbox.com/s/5ygxdjwzu6v7gmn/detector.mat?dl=1');
        catch ME
            errodlg('Holo Video Labeler: NN file not found on Dropbox. suggest bboxes is not going to work');
        end
    end
    
    if isempty(ME) %no errors
        load('detector.mat');
        NN = detector;
    end
    cd(return_folder);
end