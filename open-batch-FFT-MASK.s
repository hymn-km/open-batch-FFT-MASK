// $BACKGROUND$
Number ContinueBackgroundDialog(string message, number floating)
{
Number sema = NewSemaPhore()
If (floating) floatingModelessDialog(message,"Continue",sema)
else ModelessDialog(message,"Continue",sema)
Try GrabSemaphore(sema)
Catch return 0
return 1
}
// Digital Micrograph script to carry out FFT filtering using the manually applied masks to all currently open images.


// Author: Hyemin Kim ( hyemin.kim2@mail.mcgill.ca )
// June 27th, 2022  


/* This script is a batch-adaptation of "FFT-Mask-Example.s" which is a demonstration script written by Dr. Dave Mitchell.

The user inputs the script requires are: 
1) open STEM images (the direction of the interface should be the same)
2) a destination folder for inverse FFT images
3) a string to add at the end of filenames of inverse FFT images
4) masks

The output of this script is the inverse-FFT images which will be automatically saved at the selected destination folder.
Their filenames are in the format of: STEMImageName_IFFT_string.dm4


Description:
Before runnng the script, the user must open the STEM images that they desire to process.
The script first asks the user to select the destination folder to save inverse-FFT images.
Another prompt pops up to for a string to add at the end of the file name of the inverse-FFT images (e.g. 100, 101, 111...).
It applies the FFT to all open STEM images and allows the user to select desired masks.
Selected masks are then copied to the rest of open images and FFT-MASK-Example routine is applied.
The inverse-FFT images are then saved as *.dm4 files at the previously chosen destination folder.
Finally, the last prompt pops up, asking the user to whether close all open images except for the STEM images or not.

It should be noted that identical masks are applied to all images.
.
.
.
.

**************** Prior to running the script, the user must open the STEM images that they wish to apply FFT filtering using the masks ****************
.
.
.
.

References:
Background dialogs are adapted from "How to run a script in the background, allowing user interaction - 06.s" in the E-book version of "Digital Micrograph Scripting Handbook" by Dr. Bernhard Schaffer
Opening all image files from a selected folder is derived from Gatan's example script, "Process all DM files in a folder"
Creating a TagList of images is modified from "How to perform a task on all open images - 03.s" in the E-book version of "Digital Micrograph Scripting Handbook" by Dr. Bernhard Schaffer
Copying annotations is adapted from "copy all annotations.s" by Dr. Bernhard Schaffer, found in https://www.felmi-zfe.at/cms/wp-content/uploads/dm-scripts/5941/copy-all-annotations.s
FFT-MASK routine is altered from "FFT-Mask-Example.s" by Dr. Dave Mitchell, found in http://dmscripting.com/
Transferring the spatial calibration is based on "Transfer Calibration.s" by Dr. Dave Mitchell, found in https://www.felmi-zfe.at/cms/wp-content/uploads/dm-scripts/5386/Transfer_Calibration_DM.s
Closing all open images is derived from "Close all Open Images.s" by Dr. Dave Mitchell, found in https://www.felmi-zfe.at/cms/wp-content/uploads/dm-scripts/5131/Close_All_Open_Images_DM.s
*/ 




/* IL_Crate() creates a TagList of all open images */
TagGroup IL_Create()
	{
	TagGroup img_list = NewTagList()
	Image  img
	img.GetFrontImage()
	While(img.ImageIsValid())
		{
		 img_list.TagGroupInsertTagAsLong(Infinity(),img.ImageGetID())
		 img := FindNextImage(img)		
		}
	return img_list
	}

/* IL_Size() returns the size of the image list. */
Number IL_Size(TagGroup img_list)
	{
	return TagGroupCountTags(img_list)
	}

/* IL_GetID() returns the ID of the image stored at list position list_pos. It returns 0 for invalid positions */
Number IL_GetID(TagGroup img_list, Number list_pos)
	{
	Number ID
	If (img_list.TagGroupGetIndexedTagAsLong(list_pos, ID)) Return ID
	Else Return 0
	}

/* IL_GetImage() gives the image stored at list position list_pos. It returns 1 on success and 0 on failure */
Number IL_GetImage(TagGroup img_list, Number list_pos, Image &img)
	{
	Number ID
	ID = IL_GetID(img_list, list_pos)
	If (ID) If (GetImageFromID(img, ID)) Return 1
	Else Return 0
	}

/* IL_FFT() returns the list of FFT images only */
TagGroup IL_FFT(TagGroup img_list)
{
	number count, img_list_size, tg_entry
	image img
	TagGroup img_list_filtered
	img_list_size = IL_Size(img_list)
	if (img_list_size == 0 ) return img_list
	img_list_filtered = NewTagList()
	for (count=0 ; count < img_list_size; count++)
	{
		if (IL_GetImage(img_list, count, img))
		
		{
			string name = img.GetName()
			string fft = "FFT"
			if ( fft == left(name, len(fft)) )
			{
			
			 img_list.TagGroupGetIndexedTagAsNumber(count, tg_entry)
			 img_list_filtered.TagGroupInsertTagAsNumber(infinity(), tg_entry)
			 
			}
		}
	}
	return img_list_filtered
}



// MAIN SCRIPT starts here

// Prompt to get the directory for the destination folder to save the inverse-FFT images
string path
if (GetDirectoryDialog("Select destination folder for inverse-FFT images", "", path))
result("\n Selected path is :"+path)

// Prompt to add a string at the end of the file name of the inverse-FFT images (this is for the ease of filing for the user; this could be the direction of the interface they may be looking e.g. 100, 111, 101 ...)
string username
if (GetString("Insert the desired suffix for inverse-FFT images", username, username))
result("\n Selected suffix is :"+username)

/* Create a TagList containing all open STEM images */
TagGroup STEM_list
number STEM_list_size

STEM_list = IL_Create()
STEM_list_size = IL_Size(STEM_list) // Get a size of the TagList of STEM images

/* Apply FFT filter to all open STEM images */ 
image img
img.GetFrontImage()
while (img.ImageisValid())
{ 
	compleximage img_FFT := realFFT(img)
	img_FFT.showimage()
	img:= FindNextImage(img)
}


// Declare variables for TagLists
TagGroup FFT_STEM_list = IL_Create()
TagGroup FFT_list = IL_FFT(FFT_STEM_list)
number FFT_list_size = IL_Size(FFT_list)
number FFT_STEM_list_size = IL_Size(FFT_STEM_list)


// Prompt to choose the source image for mask selection 
image img_mask
GetOneImagewithPrompt("Select the source image for mask","Mask Source Image",img_mask) // Prompt for the user to select one image
showimage(img_mask) // Display the selected image
imagedisplay img_mask_disp=img_mask.ImageGetImageDisplay(0)

// Continue-dialog to check if the mask has been selected
If (!ContinueBackgroundDialog("Please press Continue if mask has been selected.",0))
Exit(-1)

number hasmask_source
compleximage mask_source=createmaskfromannotations(img_mask_disp, 5, 0, hasmask_source)

If(hasmask_source==0)
{
	showalert("There are no masks applied to this FFT!",0)
	exit(0)
	
	}

string imgname_mask_source = getname(img_mask)
setname(mask_source, "Mask"+imgname_mask_source)

// Declare variables
image source, destination
number SIndex, dIndex, displayOption
number ANcount, count
component Sroot, SimgC, Droot, DimgC

// Get the source image for mask
source := img_mask

// root Component of ImageDocument SOURCE
Sroot = ImageDocumentGetRootComponent(ImageGetOrCreateImageDocument(source))
 
// sIndex'th contained image Component in ImageDocument SOURCE 
SimgC = Sroot.ComponentGetNthChildOfType(20, sIndex)   


// For-loop to copy the selected mask
for (number a = 0; a < FFT_list_size; a++)
{
if (!IL_GetImage(FFT_list, a, img)) result("\n Unexpected error: image not found")
Else {

selectImage(img)
// Get the original STEM image
image stemimage, sourceimage
number b = FFT_list_size - a - 1
if(!IL_GetImage(STEM_list, b, stemimage)) result("\n Unexpected error: image not found")
Else {
sourceimage:=stemimage
}

string imgname=getname(sourceimage)

// Get the destination FFT image
destination:=img

// Get root component of Image Document DESTINATION
Droot = ImageDocumentGetRootComponent(ImageGetOrCreateImageDocument(destination))

// Get dIndex'th contained image component in Image Document DESTINATION
DimgC = Droot.ComponentGetNthChildOfType(20, dIndex)
ANcount = ComponentCountChildren(SimgC)

// Copy all annotations
if (ANcount>0)
 for(count=0;count<ANcount;count++)
 ComponentAddChildAtEnd(DimgC, ComponentClone(SimgC.ComponentGetChild(count), 0))

/* Apply FFT-MASK-Example routine */
// Get the FFT image with masks applied
image front:=destination
//string imgname=getname(front)
imagedisplay imgdisp=front.imageGetImageDisplay(0)

// Get the size of the FFT image (for transferring spatial calibration)
number xsize, ysize
getsize(front, xsize, ysize)

number hasmask
compleximage mask=CreateMaskFromAnnotations(imgdisp, 5, 0, hasmask)

setname(mask, "Mask of "+imgname)
showimage(mask)

// Multiply the FFT by the mask
compleximage maskedfft=mask*front
converttopackedcomplex(maskedfft)

// Carry out the inverse FFT and display the filtered image
image invfft=packedifft(maskedfft)
setname(invfft, imgname+"_IFFT")
showimage(invfft)

compleximage secondfft:=realfft(invfft)
converttopackedcomplex(secondfft)
showimage(secondfft)
imagedisplay secondfftdisp=secondfft.imageGetImageDisplay(0)
setname(secondfft, "Masked FFT of Filtered Image of "+imgname)

// For-loop to copy mask annotations
number p
number nocomps=imgdisp.componentcountchildren()
for(p=0; p<nocomps;p++)
{
// Get the next component and its type
component thiscomponent=imgdisp.componentgetchild(p)
number comptype=thiscomponent.componentGetType()

// Filter annotations to copy only masks
if (comptype==8 || comptype ==9 || comptype==15 || comptype==19)
{
component masktocopy=componentclone(thiscomponent,1)
secondfftdisp.componentaddchildatend(masktocopy)
masktocopy.componentsetselected(1)
}
}



/* 
 Transfer the spatial calibration 
 from the original STEM image (source)   
 to the inverse FFT image (target)     */

// Declare variables
image targetimage
number xscale, yscale, width, height
string units

// Get the size and original scales of the target image (inverse-FFT image)
targetimage:=invfft
getscale(sourceimage, xscale, yscale)
getsize(sourceimage, width, height)
units=getunitstring(sourceimage)

// Check to make sure that the source image is calibrated
if(units=="")
	{
		OKdialog("Your Source image is not calibrated")
		exit(0)
	}

// Compare the target and source images, and if differently binned, appropriate scaling is applied
number targetwidth, targetheight
getsize(targetimage, targetwidth, targetheight)

// Apply scaling
number scalex=((width/targetwidth)*xscale)
number scaley=((height/targetheight)*yscale)
setscale(targetimage, scalex, scaley)
setunitstring(targetimage, units)
showimage(targetimage)

// Save inverse FFT images with the appropriate spatial calibration as *.dm4 format
string invfft_name = ImageGetName(invfft) // Get the name of the inv-FFT image
string name

name = invfft_name+"_"+username
string filepath = path.PathConcatenate(name) // Get the path for the destination folder
invfft.SaveAsGatan(filepath) // Save as a DM image file

}
}



// Close all open images except for the STEM images without asking to save every file

If (!ContinueBackgroundDialog("Please press Continue if you wish to close all open images, excluding the STEM images.",0))
Exit(-1)

Else
	{
		Number kWINDOWTYPE_IMAGEWINDOW = 5
		number numberDocs = CountDocumentWindowsOfType(kWINDOWTYPE_IMAGEWINDOW)
		number i

		for( i = 0; i < numberDocs - STEM_list_size; ++ i ) // Closes all open image windows except for STEM images at the back
        { 
                ImageDocument imgDoc = GetImageDocument( 0 )
				image img:=getfrontimage()
				imagedocumentClose(imgdoc,0)	
        }
        
	}
	
