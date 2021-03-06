# holo video labeler


Matlab version required: 2021a.

![alt text](https://github.com/alexandresoaresilva/holo_vid_label/blob/main/docs/UI.png)

Holo Video Labeler is a MATLAB app that allows for labeling individual frames in a video. The app was created to label features in cotton fibers found in videos of the z-stack of microscopic holograms of those fibers. This app was developed for the Applied Vision Lab at Texas Tech University.

The app allows for creation of multi-class bounding boxes around objects of interest in frames of .avi video files.

Warning: The app was not tested with videos larger than one hundred frames (it was created for videos that are 31 frames long, representing the z-stack of a hologram).

## running the holo video labeler

### Always start the app using the holo_vid_labeler.m script.

To load short videos, click on the upper-right button **select video (s)**.

Bounding boxes are stored inside the the folder where the labeled videos are, in a directory called **label_files**, during the app closing process.

Two types of files related to the labels are saved:

    1. <vid name>.mat files: they represent HoloVid objects without the frame images stored.
    
    2. <vid name>_fr<frame no.>.txt files: each line shows the class id (a number) followed by coordinates for the bounding box, with a delimiter of one whitespace.
    	
    	 <class id>: x y w h
         
         Example: 
         
            1: 257.91785 93.007645 167.68441 199.882305
         
         If the bounding box was produced by a model detection, the <class id> will be a decimal number with the class score. Example:
         
            .98: 837.08826 492.04996 153.99164 95.62204
   ### Using the pre-trained networks ###
   
   To use the Matlab-trained Faster RCNN, just run the app and download the model from the dropbox link copied to your clipboard. The app will give instructions on how to load the model.
   
   To run the Python-based Faster RCNN (detectron2/pytorch), install Docker on your Windows or Linux system (on Windows, Docker requires Windows Subsystem for Linux). It does not work on Mac OS.
   
   After installing Docker, pull the holo cotton feat detector container from the Docker Hub:
   
   https://hub.docker.com/r/alexandresoaresilva/holo_cotton_feat_detector
   
   After this setup, run the Holo Video Labeler app again; it will automatically detect the presence of the py_model and list it as one of the available networks for feature detection.
   
