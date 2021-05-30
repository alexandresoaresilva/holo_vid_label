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
        last_selected_bbox_idx
        ax_obj_parent %axes
        I_orig
        I_min_max_255
        I_stdized
        I_min_max_over_vid
        I_norm_0_to_1
        last_deleted_bbox
        imshow_obj
    end
    methods(Access=public)
        function self = Frame(fr_no, I, ax_obj_parent, sqr_fr_side_sz)
            if nargin < 2
                fr_no = [];
                I = [];
            end
            if nargin < 3
                ax_obj_parent = [];
            end
            if nargin < 4
                sqr_fr_side_sz = 1002;
            end
            self.last_deleted_bbox = [];
            self.fr_number = fr_no;
            self.bboxes = [];
            %             self.bbox_labels = {};
            self.ax_obj_parent = ax_obj_parent;
            self.is_principal = false;
            self.imshow_obj = [];
            if ~isempty(fr_no)
                self.store_I_into_Frame(I, sqr_fr_side_sz);
            end
            %             self.I_thumbnail = imresize(self.I_min_max_255,...
            %                     [thumb_side_sz thumb_side_sz]);
        end
        
        function clear_I_data(self)
            self.I_orig = [];
            self.I_min_max_255 = [];
            self.I_norm_0_to_1 = [];
            self.I_min_max_over_vid = [];
            self.I_stdized = [];
        end
        function store_I_into_Frame(self, I, sqr_fr_side_sz)
            if nargin < 3
                sqr_fr_side_sz = 1002;
            end
            I = pad2sqr_n_resize(I, sqr_fr_side_sz);
            I_norm = min_max_norm(I);
            self.I_orig = I;
            self.I_min_max_255 = uint8(round(I_norm*255));
            self.I_norm_0_to_1 = I_norm;
            self.I_stdized = uint8(min_max_norm(stdize_norm(self.I_orig),0,255));
        end
        
        function set_I_vid_norm(self, I)
            self.I_min_max_over_vid  = I;
        end
        function update_axes_with_frame(self, show_I_minmax_norm)
            if ~isempty(self.ax_obj_parent) &&  isvalid(self.ax_obj_parent)
                
                if show_I_minmax_norm == 1
                    if ~isempty(self.I_min_max_255)
                        if isempty(self.imshow_obj) || ~isvalid(self.imshow_obj)
                            self.imshow_obj = imshow(self.I_min_max_255, 'Parent', self.ax_obj_parent);
                        else
                            self.imshow_obj.CData = self.I_min_max_255;
                            %                             self.imshow_obj.Parent = self.ax_obj_parent;
                        end
                    end
                elseif show_I_minmax_norm == 0
                    if ~isempty(self.I_orig)
                        if isempty(self.imshow_obj) || ~isvalid(self.imshow_obj)
                            self.imshow_obj = imshow(self.I_orig, 'Parent', self.ax_obj_parent);
                        else
                            self.imshow_obj.CData = self.I_orig;
                            %                             self.imshow_obj.Parent = self.ax_obj_parent;
                        end
                    end
                elseif show_I_minmax_norm == 3 %experimental
                    if ~isempty(self.I_min_max_over_vid)
                        if isempty(self.imshow_obj) || ~isvalid(self.imshow_obj)
                            self.imshow_obj = imshow(self.I_min_max_over_vid, 'Parent', self.ax_obj_parent);
                        else
                            self.imshow_obj.CData = self.I_min_max_over_vid;
                            %                             self.imshow_obj.Parent = self.ax_obj_parent;
                        end
                    end
                end
            end
            self.load_stored_bboxes_into_fr_axes();
        end
        
        function set_parent_ax_obj(self, ax_obj_parent)
            self.ax_obj_parent = ax_obj_parent;
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
            
            if ischar(get_I_minmax_norm) && strcmpi(get_I_minmax_norm, 'vid_norm')
                I = self.I_min_max_over_vid;
            elseif get_I_minmax_norm
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
                for i=1:length(bbox_rect)
                    self.bboxes(end+1,1) = bbox_rect(i);
                end
            end
            self.unselect_current_bboxes();
            %             self.bboxes(end).Selected = true;
        end
        
        function replace_all_bboxes(self, new_bboxes)
            self.bboxes = new_bboxes;
            self.is_principal = true;
        end
        
        function bbox = get_last_added_bbox(self)
            if self.fr_has_at_least_one_bbox()
                bbox = self.bboxes(end).copy();
            end
        end
        
        function duplicate_selected_bbox(self)
            if self.fr_has_at_least_one_bbox()
                idx = self.get_selected_bbox_idx();
                if isempty(idx)
                   idx = self.last_selected_bbox_idx;
                end
                self.bboxes(idx).Selected =  false;
                bbox_copy = self.bboxes(idx).copy;
                bbox_copy = self.change_color_if_diff_from_def(bbox_copy);
                bbox_copy.Parent = self.ax_obj_parent;
                self.add_bbox_to_rect_array(bbox_copy);
            end
        end
        
        function bbox = change_color_if_diff_from_def(self, bbox)
            if nargin < 2
                idx = self.get_selected_bbox_idx();
                bbox = self.bboxes(idx);
            end
            if sum(bbox.StripeColor == bbox.Color) ~= 3
                bbox.StripeColor = bbox.Color;
            end
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
        function reload_last_deleted_bbox(self)
            if ~isempty(self.last_deleted_bbox)
                self.add_bbox_to_rect_array(self.last_deleted_bbox(end));
                self.last_deleted_bbox(end) = [];
                self.bboxes(end).Parent = self.ax_obj_parent;
            end
        end
        function del_all_bbox(self)
            for i=1:length(self.bboxes)
                self.bboxes(i).delete();
            end
            self.bboxes = [];
            self.is_principal = false;
        end
        function del_bbox(self)
            idx = self.get_selected_bbox_idx();
            if isempty(idx)
                if self.last_selected_bbox_idx <= length(self.bboxes)
                    idx = self.last_selected_bbox_idx;
                end
            end
            
            if ~isempty(idx)
                if isempty(self.last_deleted_bbox)
                    self.last_deleted_bbox = self.bboxes(idx).copy;
                else
                    self.last_deleted_bbox(end+1,1) = self.bboxes(idx).copy;
                end
                self.last_deleted_bbox(end).Parent = [];
                self.last_deleted_bbox(end).Selected = false;
                self.bboxes(idx).delete();
                self.bboxes(idx) = [];
                
                if isempty(self.bboxes)
                    self.is_principal = false;
                end
            end
        end
        function bboxes = get_all_rect_bboxes(self)
            bboxes = [];
            if self.fr_has_at_least_one_bbox()
                bboxes = [self.bboxes(:).copy];
            end
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
            idx = find(idx,1);
            if ~isempty(idx)
                self.last_selected_bbox_idx = idx;
                self.bboxes(idx).Selected = false;
            end
        end
        function unselect_current_bboxes(self)
            for i=1:length(self.bboxes)
                self.bboxes(i).Selected = false;
                % if i == length(self.bboxes)
                % self.bboxes(i).Selected = true;
                % end
                addlistener(self.bboxes(i), 'ROIMoved', @(x,y)detect_bbox_moving(self));
            end
        end
        function load_stored_bboxes_into_fr_axes(self)
            if isempty(self.ax_obj_parent) || ~isvalid(self.ax_obj_parent)
                errordlg('Frame::load_stored_bboxes_into_fr_axes: parent axes obj is needed for this operation');
            else
                if self.fr_has_at_least_one_bbox()
                    for i=1:length(self.bboxes)
                        self.bboxes(i).Parent = self.ax_obj_parent;
                    end
                end
            end
        end
        
        function detect_bbox_moving(self)
            self.change_color_if_diff_from_def();
        end
    end
end

