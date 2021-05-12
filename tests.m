clear, clc, close all;
ax = uiaxes;
h = HoloVid('P:\_research\AVL\Data\_videos\B1-7R3.avi',ax);
ax.Parent.Position = [2750 1200 900 900]
ax.Position = [1 1 890 890];
h.toggle_show_I_minmax();
h.set_cutoff_fr(11);
h.add_bbox_to_selected_fr();
h.add_bbox_to_selected_fr();