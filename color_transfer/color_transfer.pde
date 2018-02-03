import java.awt.*; //<>//
import java.awt.image.*;
import javax.imageio.*;
import java.io.*;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

PImage shapeImg;
PImage sortedImg;
PImage colorImg;
PImage sortedColorImg;
PImage finalImg;
String shapeSourceName;
String colorSourceName;

boolean isFinished;

enum imageSourceType {
  SHAPE, COLOR
};
enum sortType {
  BRIGHTNESS, HUE
};

void setup() {
  size(1200, 400);
  shapeImg = null;
  colorImg = null;
  finalImg = null;
  shapeSourceName = null;
  colorSourceName = null;
  isFinished = false;

  selectImage(imageSourceType.SHAPE);
  selectImage(imageSourceType.COLOR);
}

void draw() {
  background(0);

  if (shapeSourceName != null && shapeImg != null)
    image(shapeImg, 0, 0);
  if (isFinished && finalImg != null)
    image(finalImg, 400, 0);
  if (colorSourceName != null && colorImg != null)
    image(colorImg, 800, 0);
}

void selectImage(imageSourceType type) {
  if (type == imageSourceType.SHAPE) {
    selectInput("Select shape image", "shapeImageSelected");
  } else if (type == imageSourceType.COLOR) {
    selectInput("Select color image", "colorImageSelected");
  }
}

void processImages() {
  if (shapeImg.width > shapeImg.height) {
    shapeImg.resize(400, 0);
  } else {
    shapeImg.resize(0, 400);
  }

  if (colorImg.width > colorImg.height) {
    colorImg.resize(400, 0);
  } else {
    colorImg.resize(0, 400);
  }

  sortedColorImg = createImage(colorImg.width, colorImg.height, RGB);
  sortedColorImg = colorImg.get();
  sortedColorImg.loadPixels();

  finalImg = createImage(shapeImg.width, shapeImg.height, RGB);
  finalImg = shapeImg.get();
  finalImg.loadPixels();

  reversibleQuicksort(sortedColorImg.pixels, 0, sortedColorImg.pixels.length/2, sortType.BRIGHTNESS, null);
  sortedColorImg.updatePixels(); //<>//

  //colorizeB(finalImg.pixels, sortedColorImg.pixels, sortedColorImg.width);
  colorizeC(finalImg, sortedColorImg);
}
void shapeImageSelected(File selection) {
  imageSelected(selection, imageSourceType.SHAPE);
}
void colorImageSelected(File selection) {
  imageSelected(selection, imageSourceType.COLOR);
}

void imageSelected(File selection, imageSourceType type) {
  if (selection != null) {
    String name = selection.getName();
    System.out.printf("name: %s\ngetAbsolutePath: %s\n", name, selection.getAbsolutePath());

    Pattern p = Pattern.compile(".*[.](gif|png|jpeg|jpg|bmp|GIF|PNG|JPEG|JPG|BMP)$");
    Matcher m = p.matcher(name);
    if (!m.matches()) {
      System.out.println("Not an image file");
      selectImage(type); // try again
      return;
    }

    BufferedImage bimg;
    int imgWidth;
    int imgHeight;
    try {
      bimg = ImageIO.read(selection);

      imgWidth = bimg.getWidth();
      imgHeight = bimg.getHeight();

      System.out.printf("image width:%d height:%d", imgWidth, imgHeight);

      if (type == imageSourceType.SHAPE) {
        shapeImg = new PImage(bimg);
        shapeSourceName = name;
      } else if (type == imageSourceType.COLOR) {
        colorImg = new PImage(bimg);
        colorSourceName = name;
      }

      if (colorSourceName != null && shapeSourceName != null) {
        processImages();
      }
    }
    catch(IOException ex) {
      ex.printStackTrace();
      selectImage(type); // try again
    }
  }
}

void colorizeA(int[] shape, int[] colors) {
  // for each pixel in shape image, 
  // find closest pixel in sorted color array based on brightness
  // and replace with it
  for (int i = 0; i < shape.length; i++) {
    float targetBrightness = brightness(color(shape[i]));
    int lo = 0, hi = colors.length - 1;
    int m = (lo + hi)/2;
    while (lo <= hi) {
      m = (lo + hi)/2;
      float currentBrightness = brightness(color(colors[m]));
      if ( currentBrightness < targetBrightness) {
        lo = m + 1;
      } else if (currentBrightness > targetBrightness) {
        hi = m - 1;
      } else {
        break;
      }
    }
    shape[i] = colors[m];
  }
}

void colorizeB(int[] shape, int[] colors, int imageWidth) {
  // for each pixel in shape image, 
  // find closest pixel in sorted color array based on brightness
  // then find the closest in hue within a range
  // and replace with it
  for (int i = 0; i < shape.length; i++) {
    float targetBrightness = brightness(color(shape[i]));
    int lo = 0, hi = colors.length - 1;
    int m = (lo + hi)/2;
    while (lo <= hi) {
      m = (lo + hi)/2;
      float currentBrightness = brightness(color(colors[m]));
      if ( currentBrightness < targetBrightness) {
        lo = m + 1;
      } else if (currentBrightness > targetBrightness) {
        hi = m - 1;
      } else {
        break;
      }
    }
    // find close hue
    float targetHue = hue(color(shape[i]));
    lo = (m / imageWidth) * imageWidth;
    hi = lo + imageWidth - 1;
    while (lo <= hi) {
      m = (lo + hi)/2;
      float currentHue = hue(color(colors[m]));
      if ( currentHue < targetHue) {
        lo = m + 1;
      } else if (currentHue > targetHue) {
        hi = m - 1;
      } else {
        break;
      }
    }
    shape[i] = colors[m];
  }
}

void colorizeC(PImage shapeSource, PImage pallet) {
  // sort image and keep track of original position
  // swap values with color image's pixels
  // change back to original position
  shapeSource.loadPixels();
  pallet.loadPixels();

  int[] originalIndexes = new int[shapeSource.pixels.length];
  for (int i = 0; i < originalIndexes.length; i++) {
    originalIndexes[i] = i;
  }

  // fill originalIndexes
  reversibleQuicksort(shapeSource.pixels, 0, shapeSource.pixels.length -1, sortType.BRIGHTNESS, originalIndexes);
  //setup pallet to copy
  pallet.resize(shapeSource.width, shapeSource.height);

  //sort each row by hue
  for (int row = 0; row < pallet.height; row++) {
    int lo = row * pallet.width;
    int hi = (row + 1) * pallet.width - 1;
    reversibleQuicksort(pallet.pixels, lo, hi, sortType.HUE, null);
  }
  pallet.updatePixels();

  for (int row = 0; row < shapeSource.height; row++) {
    int lo = row * shapeSource.width;
    int hi = (row + 1) * shapeSource.width - 1;
    reversibleQuicksort(shapeSource.pixels, lo, hi, sortType.HUE, originalIndexes);
  }

  // revert pixel positions
  for (int i = 0; i < shapeSource.pixels.length; i++) {
    shapeSource.pixels[originalIndexes[i]] = pallet.pixels[i];
  }
  shapeSource.updatePixels();
  isFinished = true;
}

// Quick sort algorithm from https://en.wikipedia.org/wiki/Quicksort
// quicksort that saves original positions
void reversibleQuicksort(int[] A, int lo, int hi, sortType type, int[] indexes) {
  if(hi >= A.length){
   System.out.printf("hi is too big %d >= %d \n", hi, A.length);
   return;
  }
  if (lo < hi) {
    int p = reversiblePartition(A, lo, hi, type, indexes);
    reversibleQuicksort(A, lo, p - 1, type, indexes);
    reversibleQuicksort(A, p + 1, hi, type, indexes);
  }
}

int reversiblePartition(int[] A, int lo, int hi, sortType type, int[] indexes) {
  float pivot = type == sortType.BRIGHTNESS ? brightness(color(A[hi])) : hue(color(A[hi]));
  int i = lo - 1;
  for (int j = lo; j < hi; j++) {
    if ((type == sortType.BRIGHTNESS && brightness(color(A[j])) < pivot) ||
      (type == sortType.HUE && hue(color(A[j])) < pivot)
      ) {
      i = i + 1;
      swap(A, i, j);
      if(indexes != null){
        swap(indexes, i, j);
      }
    }
  }
  if ((type == sortType.BRIGHTNESS && brightness(color(A[hi])) < brightness(color(A[i + 1]))) ||
    (type == sortType.HUE && hue(color(A[hi])) < hue(color(A[i + 1])))
    ) {
    swap(A, i+1, hi);
    if(indexes != null){
      swap(indexes, i+1, hi);
    }
  }
  return i + 1;
}

void swap(int[] arr, int a, int b) {
  int temp = arr[a];
  arr[a] = arr[b];
  arr[b] = temp;
}