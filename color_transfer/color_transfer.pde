PImage img;
PImage sortedImg;
PImage colorImg;
PImage sortedColorImg;
PImage finalImg;

void setup(){
  size(1200, 400);
  img = loadImage("hand.jpg");
  if(img.width > img.height){
    img.resize(400, 0);
  }else{
    img.resize(0, 400);
  }
  img.loadPixels();
  
  colorImg = loadImage("bonfire.jpg");
  if(img.width > img.height){
    img.resize(400, 0);
  }else{
    img.resize(0, 400);
  }
  colorImg.loadPixels();
    
  sortedImg = createImage(img.width, img.height, RGB);
  sortedColorImg = createImage(colorImg.width, colorImg.height, RGB);
  finalImg = createImage(img.width, img.height, RGB);
  
  sortedImg = img.get();
  sortedImg.loadPixels();
  
  sortedColorImg = colorImg.get();
  sortedColorImg.loadPixels();
  
  finalImg = img.get();
  finalImg.loadPixels();
  
  //int[] tempArray = new int[img.pixels.length];
  //topDownMergeSort(sortedImg.pixels, tempArray, img.pixels.length);
  //sortedImg.updatePixels();
  
  //int[] tempColorArray = new int[colorImg.pixels.length];
  //topDownMergeSort(sortedColorImg.pixels, tempColorArray, sortedColorImg.pixels.length);
  
  int sortType = 0;// 0 brightness, 1 hue
  quickSort(sortedColorImg.pixels, 0, sortedColorImg.pixels.length - 1, sortType);
  /*
  //sort each row
  System.out.printf("width:%d height:%d length:%d\n", sortedColorImg.width, sortedColorImg.height, sortedColorImg.pixels.length);
  for(int row = 0; row < sortedColorImg.height; row++){
    int lo = row * sortedColorImg.width;
    int hi = (row + 1) * sortedColorImg.width - 1;
    System.out.printf("row:%d lo:%d hi:%d\n", row, lo, hi);
    quickSort(sortedColorImg.pixels, lo, hi, 1);
  }
  */
  sortedColorImg.updatePixels();
  //colorizeB(finalImg.pixels, sortedColorImg.pixels, sortedColorImg.width);
  colorizeC(finalImg, sortedColorImg);
  sortedImg.updatePixels();
  
}

void draw(){
  background(0);
  image(img, 0, 0);
  image(finalImg, 400, 0);
  image(colorImg, 800, 0);
}

void colorizeA(int[] shape, int[] colors){
 // for each pixel in shape image, 
 // find closest pixel in sorted color array based on brightness
 // and replace with it
 for(int i = 0; i < shape.length; i++){
   float targetBrightness = brightness(color(shape[i]));
   int lo = 0, hi = colors.length - 1;
   int m = (lo + hi)/2;
   while(lo <= hi){
     m = (lo + hi)/2;
     float currentBrightness = brightness(color(colors[m]));
       if( currentBrightness < targetBrightness){
         lo = m + 1;
       }else if(currentBrightness > targetBrightness){
         hi = m - 1;
       }else{
         break; 
       }
   }
   shape[i] = colors[m];
 }
}

void colorizeB(int[] shape, int[] colors, int imageWidth){
 // for each pixel in shape image, 
 // find closest pixel in sorted color array based on brightness
 // then find the closest in hue within a range
 // and replace with it
 for(int i = 0; i < shape.length; i++){
   float targetBrightness = brightness(color(shape[i]));
   int lo = 0, hi = colors.length - 1;
   int m = (lo + hi)/2;
   while(lo <= hi){
     m = (lo + hi)/2;
     float currentBrightness = brightness(color(colors[m]));
       if( currentBrightness < targetBrightness){
         lo = m + 1;
       }else if(currentBrightness > targetBrightness){
         hi = m - 1;
       }else{
         break; 
       }
   }
   // find close hue
   float targetHue = hue(color(shape[i]));
   lo = (m / imageWidth) * imageWidth;
   hi = lo + imageWidth - 1;
   while(lo <= hi){
     m = (lo + hi)/2;
     float currentHue = hue(color(colors[m]));
       if( currentHue < targetHue){
         lo = m + 1;
       }else if(currentHue > targetHue){
         hi = m - 1;
       }else{
         break; 
       }
   }
   shape[i] = colors[m];
 }
}

void colorizeC(PImage shape, PImage colors){
  // sort image and keep track of original position
  // swap values with color image's pixels
  // change back to original position
  
  int[] originalIndexes = new int[shape.pixels.length];
  for(int i = 0; i < originalIndexes.length; i++){
    originalIndexes[i] = i; 
  }
  
  // fill xCoords and yCoords
  reversableQuicksort(shape.pixels, 0, shape.pixels.length -1, originalIndexes);
  //setup colors to copy
  colors.resize(shape.width, shape.height);
  
  // todo: try sorting rows by hue before reverting position
   /*
  //sort each row
  System.out.printf("width:%d height:%d length:%d\n", sortedColorImg.width, sortedColorImg.height, sortedColorImg.pixels.length);
  for(int row = 0; row < sortedColorImg.height; row++){
    int lo = row * sortedColorImg.width;
    int hi = (row + 1) * sortedColorImg.width - 1;
    System.out.printf("row:%d lo:%d hi:%d\n", row, lo, hi);
    quickSort(sortedColorImg.pixels, lo, hi, 1);
  }
  */
  
  
  
  // revert pixel positions
  for(int i = 0; i < shape.pixels.length; i++){
    shape.pixels[originalIndexes[i]] = colors.pixels[i];
  }
  
}

// Quick sort algorithm from https://en.wikipedia.org/wiki/Quicksort
void quickSort(int[] A, int lo, int hi, int flag){
  if(lo < hi){
    int p = partition(A, lo, hi, flag);
    quickSort(A, lo, p - 1, flag);
    quickSort(A, p + 1, hi, flag);
  }
}

int partition(int[] A, int lo, int hi, int flag){
  float pivot = flag == 0 ? brightness(color(A[hi])) : hue(color(A[hi]));
  int i = lo - 1;
  for(int j = lo; j < hi; j++){
    if((flag == 0 && brightness(color(A[j])) < pivot) || (flag == 1 && hue(color(A[j])) < pivot)){
      i = i + 1;
      int temp = A[i];
      A[i] = A[j];
      A[j] = temp;
    }
  }
  if((flag == 0 && brightness(color(A[hi])) < brightness(color(A[i + 1]))) ||
     (flag == 1 && hue(color(A[hi])) < hue(color(A[i + 1]))) ){
     int temp = A[i + 1];
     A[i + 1] = A[hi];
     A[hi] = temp;
  }
  return i + 1;
}

// quicksort that saves original positions
void reversableQuicksort(int[] A, int lo, int hi, int[] indexes){
  if(lo < hi){
    int p = reversablePartition(A, lo, hi, indexes);
    reversableQuicksort(A, lo, p - 1, indexes);
    reversableQuicksort(A, p + 1, hi, indexes);
  }
}

int reversablePartition(int[] A, int lo, int hi, int[] indexes){
  float pivot = brightness(color(A[hi]));
  int i = lo - 1;
  for(int j = lo; j < hi; j++){
    if(brightness(color(A[j])) < pivot){
      i = i + 1;
      swap(A, i, j);
      swap(indexes, i, j);
    }
  }
  if(brightness(color(A[hi])) < brightness(color(A[i + 1]))){
     swap(A, i+1, hi);
     swap(indexes, i+1, hi);
  }
  return i + 1;
}

void swap(int[] arr, int a, int b){
  int temp = arr[a];
  arr[a] = arr[b];
  arr[b] = temp;
}