function I_new = pad2sqr_n_resize(I, sqr_side_sz)
    
    [row_sz, col_sz, channel_sz] = size(I);
    
    if channel_sz > 1
       I = uint8(rgb2gray(I));
    end
    largest_side = row_sz;
    if col_sz > row_sz
        largest_side = col_sz;
    end
    
    [diff_r0, diff_r1] = get_side_diff(row_sz, largest_side);
    [diff_c0, diff_c1] = get_side_diff(col_sz, largest_side);
    
    if diff_r0 ~= 0 || diff_c0 ~= 0
        I_new = uint8(zeros(largest_side));
        I_new(1+diff_r0:end-diff_r1, 1+diff_c0:end-diff_c1) = I;
    else
        I_new = I;
    end
    
    if col_sz > sqr_side_sz || row_sz > sqr_side_sz
        I_new = imresize(I_new, [sqr_side_sz sqr_side_sz]);
    end
end

function [diff_0, diff_1] = get_side_diff(dim_sz, sqr_side_sz)
    diff_0 = 0; %black pixels to be added at the begining of dimension
    diff_1 = 0; %black pixels to be added at the end of dimension
    if dim_sz < sqr_side_sz
        diff = sqr_side_sz - dim_sz;
        diff_1 = floor(diff/2);
        diff_0 = diff - diff_1;
    end
end

