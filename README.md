# holo video labeler


Matlab version required: 2021a.

![alt text](https://github.com/alexandresoaresilva/holo_vid_label/blob/main/docs/UI.png)

Holo Video Labeler is a MATLAB app that allows for labeling individual frames in a video. The app was created to label cotton twists (convolutions/folds) found in videos of the z-stack of microscopic holograms of cotton fibers. This app was developed for the Applied Vision Lab at Texas Tech University.

It allows for the placement of bounding boxes around objects of interest in frames of .avi video files.

Warning: The app was not tested with videos larger than one hundred frames, since it was created for videos that are 31 frames long, representing the z-stack of a hologram.

## running the holo video labeler

### Always start the app using the holo_vid_labeler.m script.

To load short videos, either:

1. Store the videos into the app's folder **\_videos**
    OR
2. Select videos from a folder using the **select video (s)** button.

Bounding boxes are saved into the folder **label_files** as .mat files. They represent HoloVid objects without the frame images stored.
