clear, clc, close all;
% if ~exist('imdsTest')
    load('detector.mat');
% end

work_dir = 'P:\_research\AVL\Data';
addpath('process_data_functions');
load('labels.mat');

vid_names = {label_struct(:).vid_name_no_ext};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%c%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%test decetor
% for i=1:10:length(testDataTbl.file_folder)
%     if i > length(testDataTbl.file_folder)
%         f = testDataTbl.file_folder{end};
%     else
%         f = testDataTbl.file_folder{i};
%     end
    
    
%     vid_name = get_vid_name_from_fr_file_name(f);
    vid_name = 'B1-4R3.avi';
    idx_label = strcmpi(vid_names, vid_name(1:end-4));
    cutoff = label_struct(idx_label).cutoff_frame;
    v = VideoReader([work_dir '\_videos\' vid_name]);
    
%     I = imread(f);
%     I = imresize(I,inputSize(1:2));
    
    j = 0;
    fig = figure;
    currAxes = axes;
    n = v.NumFrames;
    I =  zeros(1002,1002,3);
    while hasFrame(v)

        vidFrame = readFrame(v);
        I = preprocess_img(vidFrame, [224 224 3]);
        [bboxes,scores] = detect(detector, I);
        idx = scores > .5;
        bbox = preprocess_bbox(bboxes(idx,:), vidFrame);
        
%         data = preprocessData({vidFrame, bboxes},[1002 1002]);
        bbox_grd_trh = label_struct(idx_label).bbox_list;
        
        I = uint8(zeros(1002, 1002,3));
        I(:,:,1) = vidFrame;
        I(:,:,2) = vidFrame;
        I(:,:,3) = vidFrame;
        celt_str = {};
        for k=1:length(bbox_grd_trh(:,1))
            celt_str{end+1} = 'twist';
        end
        
        if j <= cutoff
            I_ann_gt = insertObjectAnnotation(I,'rectangle', bbox_grd_trh,celt_str,'Color','r');
        else
            I_ann_gt = I;
        end
        
        hold on;
            
%         imshow(I_ann_gt, 'Parent', currAxes);
        if ~isempty(find(idx,1))

            

            
            I_ann_model = insertObjectAnnotation(I_ann_gt,'rectangle', bbox, scores(idx));
            hold on;
            imshow(I_ann_model, 'Parent', currAxes);
        else
            imshow(I_ann_gt, 'Parent', currAxes);
        end
        fig.WindowState = 'maximized';
        title([vid_name ', fr. ' num2str(j)]);
%         imshow(vidFrame
%         currAxes.Visible = 'off';
        pause;
        j = j + 1;
        pause(0.2);
    end
%     close all;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%evaluate detector
% testData = transform(testData,@(data)preprocessData(data,inputSize));
% detectionResults = detect(detector,testData,'MinibatchSize',4);   
% [ap, recall, precision] = evaluateDetectionPrecision(detectionResults,testData);
% figure
% plot(recall,precision)
% xlabel('Recall')
% ylabel('Precision')
% grid on
% title(sprintf('Average Precision = %.2f', ap))

% function get_key_press(v)
%     k = waitforbuttonpress;
%     % 28 leftarrow
%     % 29 rightarrow
%     % 30 uparrow
%     % 31 downarrow
%     value = double(get(gcf,'CurrentCharacter'));
%     
%     switch(value)
%         case 28
%             v.CurrentTime = 0;
%     
%     
% end

function vid_name = get_vid_name_from_fr_file_name(fr_name)
   vid_name = regexprep(fr_name,'.*\','');  
   vid_name = regexprep(vid_name,'_frame.*','.avi');
end

