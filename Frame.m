classdef Frame < handle
    %each frame of the holographic micros is an instance of this class
    properties(Access=public)
        fr_number
        is_principal
    end
    properties(Access=private)
        bboxes %Rectangle array
        orig_bboxes
        bbox_matrix %nx4 [x, y, w, h]
        bbox_labels
        parent_ax_obj %axes
        I_orig
        I_min_max_255
        I_norm_0_to_1
        bboxes_have_NOT_been_consolidated
    end
    methods(Access=public)
        function self = Frame(fr_no, I, parent_ax_obj, sqr_fr_side_sz)
            if nargin < 2
                fr_no = [];
                I = [];
            end
            if nargin < 3
                parent_ax_obj = [];
            end
            if nargin < 4
                sqr_fr_side_sz = 1002;
            end
            
            self.bboxes_have_NOT_been_consolidated = true;
            self.fr_number = fr_no;
            self.bboxes = [];
%             self.bbox_labels = {};
            self.parent_ax_obj = parent_ax_obj;
            self.is_principal = false;
            
            if ~isempty(fr_no)
                I = pad2sqr_n_resize(I, sqr_fr_side_sz);
                I_norm = min_max_norm(I);
                self.I_orig = I;
                self.I_min_max_255 = uint8(I_norm*255);
                self.I_norm_0_to_1 = I_norm;
            end
            %             self.I_thumbnail = imresize(self.I_min_max_255,...
            %                     [thumb_side_sz thumb_side_sz]);
        end
        function update_axes_with_frame(self, show_I_minmax_norm)
            if ~isempty(self.parent_ax_obj) &&  isvalid(self.parent_ax_obj)
                
                if show_I_minmax_norm
                    I = self.I_min_max_255;
                else
                    I = self.I_orig;
                end
                
                imshow(I, 'Parent', self.parent_ax_obj);
                
            end
            self.load_stored_bboxes_into_fr_axes();
        end
        
        function set_parent_ax_obj(self, parent_ax_obj)
            self.parent_ax_obj = parent_ax_obj;
        end
        function erase_axes_info_from_bboxes(self)
            if self.fr_has_at_least_one_bbox()
                for i=1:length(self.bboxes)
                    self.bboxes(i).Parent = [];
                end
            end
        end
        function I = get_fr_img(self, get_I_minmax_norm)
            if nargin < 2
                get_I_minmax_norm = false;
            end
            
            if get_I_minmax_norm
                I = self.I_min_max_255;
            else
                I = self.I_orig;
            end
        end
        %%%%%%%%% controlling bboxes
        function add_bbox_to_rect_array(self, bbox_rect)            
            self.is_principal = true;
            
            if self.fr_has_NO_bboxes()
                self.bboxes = bbox_rect;
            else
%                 for i=1:length(bbox_rect)
                    for i=1:length(bbox_rect)
                        self.bboxes(end+1,1) = bbox_rect(i);
                    end
%                 end
            end
%             self.bbox_labels{end+1} = 'conv';
%             self.bboxes(end).Selected = false;
            self.unselect_current_bboxes();
        end
        
        function bbox = copy_last_added_bbox(self)
            bbox = self.bboxes(end).copy();
        end
        
        function store_princip_bboxes_n_clear_bbox_array(self)
            if self.fr_has_at_least_one_bbox
                self.orig_bboxes = self.get_all_rect_bboxes();
                if self.fr_has_at_least_one_bbox()
                    for i=1:length(self.orig_bboxes)
                        if isvalid(self.orig_bboxes)
                            self.orig_bboxes(i).Parent = [];
                        else
                            self.orig_bboxes(i) = [];
                        end
                    end
                end
                self.bboxes = [];
            end
        end
        function del_bbox(self)
            idx = find(self.get_selected_bbox_idx(),1);
%             self.bbox_labels(idx) = [];
            self.bboxes(idx).delete();
            self.bboxes(idx) = [];
            
            if isempty(self.bboxes)
                self.is_principal = false;
            end
        end
        function bboxes = get_all_rect_bboxes(self)
            bboxes = [self.bboxes(:).copy];
        end
    end
    methods(Access=private)
        function ret = fr_has_at_least_one_bbox(self)
            ret = ~isempty(self.bboxes);
        end
        function ret = fr_has_NO_bboxes(self)
            ret = isempty(self.bboxes);
        end
        function idx = get_selected_bbox_idx(self)
            idx = [];
            if self.fr_has_at_least_one_bbox()
                idx = [self.bboxes(:).Selected];
            end
        end
        function unselect_current_bboxes(self)
            for i=1:length(self.bboxes)
                self.bboxes(i).Selected = false;
            end
        end
        function load_stored_bboxes_into_fr_axes(self)
            if isempty(self.parent_ax_obj) || ~isvalid(self.parent_ax_obj)
                errordlg('Frame::load_stored_bboxes_into_fr_axes: parent axes obj is needed for this operation');
            else
                if self.fr_has_at_least_one_bbox()
                    for i=1:length(self.bboxes)
                        self.bboxes(i).Parent = self.parent_ax_obj;
                    end
                end
            end
        end
    end
end

