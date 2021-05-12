function I = preprocess_img(I,targetSize)
    % Resize image and bounding boxes to targetSize.
    sz = size(I, [1 2]);
    I = imresize(I, targetSize(1:2));
end