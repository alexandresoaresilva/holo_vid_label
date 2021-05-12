function bbox = preprocess_bbox(bbox, I)
    % Resize image and bounding boxes to targetSize.
    target_size = size(I,[1 2]);
    sz = [224 224];
    scale = target_size(1:2)./sz;
    
    % Resize boxes.
    bbox = bboxresize(bbox,scale);
    
    % Sanitize box data, if needed.
    bbox = helperSanitizeBoxes(bbox, target_size);
end