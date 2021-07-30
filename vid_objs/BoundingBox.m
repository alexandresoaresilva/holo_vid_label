classdef BoundingBox < handle
    %BOUNDINGBOX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        axes_obj_parent
        bbox_rect
        class_id
        class_no
        min_bbox_side_sz
        failed_to_create_bbox
        color
    end
    
    methods
        function self = BoundingBox(axes_obj_parent, bbox, class_id, min_bbox_side_sz)
            if nargin < 2
                bbox = [];
            end
            if nargin < 3
               class_id = 'feature'; 
            end
            if nargin < 4
               min_bbox_side_sz = 50; 
            end
            self.failed_to_create_bbox = true;
            self.class_id = class_id;
            self.min_bbox_side_sz = min_bbox_side_sz;
            self.axes_obj_parent = axes_obj_parent;
            self.add_bbox_to_selected_fr(bbox);
            if self.failed_to_create_bbox
                clear self;
            end
        end
        
        function self =  add_bbox_to_selected_fr(self, bbox)
            if nargin < 2
                bbox = [];
            end
            self.failed_to_create_bbox = true;
            
            if isempty(bbox)
                self.bbox_rect = drawrectangle(self.axes_obj_parent);
            end
            
            if self.bbox_sz_is_not_valid()
                self.bbox_rect.delete();
                self.bbox_rect = [];
            else
                self.failed_to_create_bbox = false;
                self.bbox_rect.Label = self.class_id;
            end
        end
    end
    methods(Access=private) 
        function not_valid = bbox_sz_is_not_valid(self)
           not_valid = all(self.bbox_rect.Position(3:4) <= self.min_bbox_side_sz); % feature is guaranteed to not be smaller than this 
        end
    end
%     function 
%         self.bbox_rect.Selected
%         r2.bbox_rect.Selected
%     end
end

