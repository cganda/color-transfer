import java.awt.*; //<>//
import java.awt.image.*;
import javax.imageio.*;
import java.io.*;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.text.SimpleDateFormat;
import java.util.Date;


PImage shapeImg;
PImage sortedImg;
PImage colorImg;
PImage sortedColorImg;
PImage finalImg;
String shapeSourceName;
String colorSourceName;
String saveFileExtension;

boolean isFinished;

enum imageSourceType {
  SHAPE, COLOR
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
  noLoop();
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

  int[] colorIndexes = new int[sortedColorImg.pixels.length];
  float[] colorBrightnessValues = new float[sortedColorImg.pixels.length];
  int[] colorCopy = new int[sortedColorImg.pixels.length];
  for (int i = 0; i < sortedColorImg.pixels.length; i++) {
    colorIndexes[i] = i;
    colorCopy[i] = sortedColorImg.pixels[i];
    colorBrightnessValues[i] = brightness(color(sortedColorImg.pixels[i]));
  }
  reversibleQuicksort(colorBrightnessValues, 0, colorBrightnessValues.length - 1, colorIndexes);

  for (int i = 0; i < sortedColorImg.pixels.length; i++) {
    sortedColorImg.pixels[i] = colorCopy[colorIndexes[i]];
  }
  sortedColorImg.updatePixels();

  long startTime = System.currentTimeMillis();
  //colorizeB(finalImg.pixels, sortedColorImg.pixels, sortedColorImg.width);
  colorizeC(finalImg, sortedColorImg);
  long endTime = System.currentTimeMillis();
  System.out.printf("Time taken: %dms", endTime - startTime);
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
    if (type == imageSourceType.SHAPE) {
      saveFileExtension = m.group(1).toLowerCase();
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
      redraw();

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
  int pixelsLength = shapeSource.pixels.length;
  shapeSource.loadPixels();
  pallet.loadPixels();

  int[] originalIndexes = new int[pixelsLength];
  float[] shapeBrightnessValues = new float[pixelsLength];
  int[] shapeCopy = new int[pixelsLength];
  for (int i = 0; i < pixelsLength; i++) {
    originalIndexes[i] = i;
    shapeCopy[i] = shapeSource.pixels[i];
    shapeBrightnessValues[i] = brightness(color(shapeSource.pixels[i]));
  }

  reversibleQuicksort(shapeBrightnessValues, 0, pixelsLength - 1, originalIndexes);
  // sort shapeSource pixels to get hue values later
  for (int i = 0; i < pixelsLength; i++) {
    shapeSource.pixels[i] = shapeCopy[originalIndexes[i]];
  }

  // fill originalIndexes
  //setup pallet to copy
  if (pallet.pixels.length > pixelsLength) {
    // make smaller before sorting
    pallet.resize(shapeSource.width, shapeSource.height);
  }
  //sort each row by hue
  int lo, hi;
  int[] colorIndexes = new int[pallet.pixels.length];
  int[] colorCopy = new int[pallet.pixels.length];
  float[] colorHueValues = new float[pallet.pixels.length];
  for (int i = 0; i < colorHueValues.length; i++) {
    colorIndexes[i] = i;
    colorCopy[i] = pallet.pixels[i];
    colorHueValues[i] = hue(color(pallet.pixels[i]));
  }
  for (int row = 0; row < pallet.height; row++) {
    lo = row * pallet.width;
    hi = (row + 1) * pallet.width - 1;
    reversibleQuicksort(colorHueValues, lo, hi, colorIndexes);
  }
  for (int i = 0; i < pallet.pixels.length; i++) {
    pallet.pixels[i] = colorCopy[colorIndexes[i]];
  }

  if (pallet.pixels.length <= pixelsLength) {
    // make larger after sorting
    pallet.resize(shapeSource.width, shapeSource.height);
  }

  pallet.updatePixels();
  
  // sort shape rows by hue
  float[] shapeHueValues = new float[shapeSource.pixels.length];
  for (int i = 0; i < shapeHueValues.length; i++) {
    shapeHueValues[i] = hue(color(shapeSource.pixels[i]));
  }
  if (shapeHueValues.length != shapeSource.pixels.length) {
    System.out.printf("lengths do not match: %dvs%d", shapeHueValues.length, shapeSource.pixels.length);
  }
  for (int row = 0; row < shapeSource.height; row++) {
    lo = row * shapeSource.width;
    hi = (row + 1) * shapeSource.width - 1;
    reversibleQuicksort(shapeHueValues, lo, hi, originalIndexes);
  }

  // revert pixel positions
  for (int i = 0; i < pixelsLength; i++) {
    shapeSource.pixels[originalIndexes[i]] = pallet.pixels[i];
  }

  shapeSource.updatePixels();
  isFinished = true;
  redraw();

  saveResult(shapeSource);
}

// Quick sort algorithm from https://en.wikipedia.org/wiki/Quicksort
// quicksort that saves original positions
void reversibleQuicksort(float[] A, int lo, int hi, int[] indexes) {
  if (hi >= A.length) {
    System.out.printf("hi is too big %d >= %d \n", hi, A.length);
    return;
  }
  if (lo < hi) {
    int p = reversiblePartition(A, lo, hi, indexes);
    reversibleQuicksort(A, lo, p - 1, indexes);
    reversibleQuicksort(A, p + 1, hi, indexes);
  }
}

int reversiblePartition(float[] A, int lo, int hi, int[] indexes) {
  float pivot = A[hi];
  int i = lo - 1;
  for (int j = lo; j < hi; j++) {
    if (A[j] < pivot) {
      i = i + 1;
      swap(A, i, j);
      if (indexes != null) {
        swap(indexes, i, j);
      }
    }
  }
  if (A[hi] < A[i + 1]) {
    swap(A, i+1, hi);
    if (indexes != null) {
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

void swap(float[] arr, int a, int b) {
  float temp = arr[a];
  arr[a] = arr[b];
  arr[b] = temp;
}

void saveResult(PImage imageToSave) {
  try {
    SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd'T'HHmmss");
    String resultName = "result-" + format.format(new Date()) + "." + saveFileExtension;
    System.out.println("Saving to " + dataPath(resultName));
    imageToSave.save(dataPath(resultName));
  }
  catch(Exception ex) {
    System.out.println("Error saving result");
    ex.printStackTrace();
  }
}