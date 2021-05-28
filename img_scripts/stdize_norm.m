function I_new = stdize_norm(I)
    I = double(I);
    I_new = (I - mean(I(:)))./std(I(:));
end