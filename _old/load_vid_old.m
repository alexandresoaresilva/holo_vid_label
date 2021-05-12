clear, clc, close all;

v = VideoReader('P:\_research\AVL\Data\_videos\A2-10R1.avi');
no_frames = v.NumFrames;
frames = cell(1,no_frames);

i = 1;
thumbnail_sz = 80;
while hasFrame(v)
    I = readFrame(v);
    I = check_n_resize(I, 1002);
    I_norm = min_max_norm(I);
    frame_dummy.frame_no = i - 1;
    frame_dummy.I_orig = I;
    frame_dummy.I_min_max_255 = uint8(I_norm*255);
    frame_dummy.I_filt = imgaussfilt(frame_dummy.I_min_max_255,2);
    frame_dummy.I_norm = I_norm;
    frame_dummy.I_thumbnail = imresize(frame_dummy.I_min_max_255,...
                                       [thumbnail_sz thumbnail_sz]);
    frames{i} = frame_dummy;
    frames_struct(i) = frame_dummy;
    i = i + 1;
end

L = length(frames_struct); %

rows = ceil(L/11); %each row shows 11 images


% I_panel= [[frames_struct(1:11).I_thumbnail];...
%           [frames_struct(12:23).I_thumbnail];...
%           [frames_struct(24:end).I_thumbnail]];

no_imgs_per_row = 11;
panel_width = thumbnail_sz*no_imgs_per_row;
panel_height = thumbnail_sz*rows;
I_panel = uint8(zeros(panel_height, panel_width));

start_fr = 1;
end_fr = no_imgs_per_row;
for i=1:thumbnail_sz:panel_height
    dummy_row = uint8([]);
    if end_fr > L
        end_fr = L;
        dummy_row = [frames_struct(start_fr:end_fr).I_thumbnail];
        missing_units = panel_width - length([frames_struct(start_fr:end_fr).I_thumbnail]);
        dummy_row = [dummy_row uint8(zeros(thumbnail_sz, missing_units))];
    else
        dummy_row = [frames_struct(start_fr:end_fr).I_thumbnail];
    end
    
    I_panel(i:i-1+thumbnail_sz,:) = dummy_row;
    start_fr = start_fr + no_imgs_per_row;
    end_fr = end_fr + no_imgs_per_row;
end

%size is alaways square
function I_new = check_n_resize(I, size_it_should_have_been)
    [r, c] = size(I);
    
    diff_c1 = 0;
    diff_c0 = 0;
    if c < size_it_should_have_been
        diff_c = size_it_should_have_been - c;
        diff_c1 = floor(diff_c/2);
        diff_c0 = diff_c - diff_c1;
    end
    diff_r0 = 0;
    diff_r1  = 0;
    if r < size_it_should_have_been
        diff_r = size_it_should_have_been - r;
        diff_r1 = floor(diff_r/2);
        diff_r0 = diff_r - diff_r1;
    end
    
    if diff_r0 ~= 0 || diff_c0 ~= 0
        I_new = uint8(zeros(size_it_should_have_been));
        I_new(1+diff_r0:end-diff_r1, 1+diff_c0:end-diff_c1) = I;
    else
        I_new = I;
    end
    
    if c > size_it_should_have_been || r > size_it_should_have_been
        I_new = imresize(I_new, [size_it_should_have_been size_it_should_have_been]);
    end
end
%displaying frames
% currAxes = axes;
% imshow(vidFrame, 'Parent', currAxes);
% currAxes.Visible = 'off';
%     pause(1/v.FrameRate);


