# open-batch-FFT-MASK
A DigitalMicrograph (DM) custom script which allows batch-FFT filtering using manually applied masks to all open STEM images




This script is a batch-adaptation of "FFT-MASK-Example.s" version:20071231 by D. R. G. Mitchell (can be found in https://www.felmi-zfe.at/cms/wp-content/uploads/dm-scripts/5869/FFT-MASKS-Examples.s)


It requires the user to open the desired STEM images which they wish to carry out the FFT filtering.

When running the script, it will automatically apply FFT to all open images.
Then the user needs to:
1) assign the desired destination folder to save inverse FFT images
2) insert a string that they wish to add at the end of the filename of inverse FFT images
3) select one of the FFT images and apply masks (could be spot, array, annular, or wedge in any combination)

Then the script will copy the manually applied masks to the rest of the FFT images, carrying out the "FFT-MASK-example" routine.
The routine includes batch-applying masked-FFT and inverse-FFT to all images.
The output of this script is a set of inverse-FFT images with spatial calibration information and a string added by the user at the end of their filename.

After generating inverse-FFT images, the user has the option to close all image windows except for the STEM images or leave them open.
This option is added for a case in which the user wishes to apply masked FFT filtering to the same images but with a different location of the mask.



***It should be noted that identical masks are applied to all images.
