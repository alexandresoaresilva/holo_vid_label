function fr_struct = load_vid(vid_file_path, fr_sz, thumbnail_sz)
    if nargin < 2
       fr_sz = 1002; %default frame size
    end
    if nargin < 3
       thumbnail_sz = 80; %default thumbnail size
    end
    vid = VideoReader(vid_file_path);
    
    i = 1;
    while hasFrame(vid)
        I = readFrame(vid);
        I = check_n_resize(I, fr_sz);
        I_norm = min_max_norm(I);
        fr_dummy.I_orig = I;
        fr_dummy.I_min_max_255 = uint8(I_norm*255);
        fr_dummy.I_norm_0_to_1 = I_norm;
        fr_dummy.I_thumbnail = imresize(fr_dummy.I_min_max_255,...
                                           [thumbnail_sz thumbnail_sz]);
        fr_struct(i) = fr_dummy;
        i = i + 1;
    end
end

%size is alaways square
% function I_new = check_n_resize(I, size_it_should_have_been)
%     
%     [r, c] = size(I);
%     
%     diff_c1 = 0;
%     diff_c0 = 0;
%     if c < size_it_should_have_been
%         diff_c = size_it_should_have_been - c;
%         diff_c1 = floor(diff_c/2);
%         diff_c0 = diff_c - diff_c1;
%     end
%     diff_r0 = 0;
%     diff_r1  = 0;
%     if r < size_it_should_have_been
%         diff_r = size_it_should_have_been - r;
%         diff_r1 = floor(diff_r/2);
%         diff_r0 = diff_r - diff_r1;
%     end
%     
%     if diff_r0 ~= 0 || diff_c0 ~= 0
%         I_new = uint8(zeros(size_it_should_have_been));
%         I_new(1+diff_r0:end-diff_r1, 1+diff_c0:end-diff_c1) = I;
%     else
%         I_new = I;
%     end
% 
%     if c > size_it_should_have_been || r > size_it_should_have_been
%         I_new = imresize(I_new, [size_it_should_have_been size_it_should_have_been]);
%     end
% end
