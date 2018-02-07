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
}

public void setup() {
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

public void draw() {
  background(0);

  if (shapeSourceName != null && shapeImg != null)
    image(shapeImg, 0, 0);
  if (isFinished && finalImg != null)
    image(finalImg, 400, 0);
  if (colorSourceName != null && colorImg != null)
    image(colorImg, 800, 0);
}

public void selectImage(imageSourceType type) {
  if (type == imageSourceType.SHAPE) {
    selectInput("Select shape image", "shapeImageSelected");
  } else if (type == imageSourceType.COLOR) {
    selectInput("Select color image", "colorImageSelected");
  }
}

public void processImages() {
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
  quickSort(colorBrightnessValues, 0, colorBrightnessValues.length, colorIndexes);

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

public void shapeImageSelected(File selection) {
  imageSelected(selection, imageSourceType.SHAPE);
}

public void colorImageSelected(File selection) {
  imageSelected(selection, imageSourceType.COLOR);
}

public void imageSelected(File selection, imageSourceType type) {
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

      System.out.printf("image width:%d height:%d\n", imgWidth, imgHeight);

      PImage tempImage = new PImage(bimg);

      double scaleFactor = 400.0f / Math.max(imgWidth, imgHeight);
      int scaledWidth = (int) (scaleFactor * imgWidth);
      int scaledHeight = (int) (scaleFactor * imgHeight);
      System.out.printf("resized width:%d height%d factor:%.3f\n", scaledWidth, scaledHeight, scaleFactor);
      PImage resized = createImage(scaledWidth, scaledHeight, RGB);
      resized.copy(tempImage, 0, 0, imgWidth, imgHeight, 0, 0, scaledWidth, scaledHeight);

      if (type == imageSourceType.SHAPE) {
        shapeImg = resized;
        shapeSourceName = name;
      } else if (type == imageSourceType.COLOR) {
        colorImg = resized;
        colorSourceName = name;
      }
      redraw();

      if (colorSourceName != null && shapeSourceName != null) {
        processImages();
      }
    } 
    catch (IOException ex) {
      ex.printStackTrace();
      selectImage(type); // try again
    }
  }
}

public void colorizeA(int[] shape, int[] colors) {
  // for each pixel in shape image,
  // find closest pixel in sorted color array based on brightness
  // and replace with it
  for (int i = 0; i < shape.length; i++) {
    float targetBrightness = brightness(color(shape[i]));
    int lo = 0, hi = colors.length - 1;
    int m = (lo + hi) / 2;
    while (lo <= hi) {
      m = (lo + hi) / 2;
      float currentBrightness = brightness(color(colors[m]));
      if (currentBrightness < targetBrightness) {
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

public void colorizeB(int[] shape, int[] colors, int imageWidth) {
  // for each pixel in shape image,
  // find closest pixel in sorted color array based on brightness
  // then find the closest in hue within a range
  // and replace with it
  for (int i = 0; i < shape.length; i++) {
    float targetBrightness = brightness(color(shape[i]));
    int lo = 0, hi = colors.length - 1;
    int m = (lo + hi) / 2;
    while (lo <= hi) {
      m = (lo + hi) / 2;
      float currentBrightness = brightness(color(colors[m]));
      if (currentBrightness < targetBrightness) {
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
      m = (lo + hi) / 2;
      float currentHue = hue(color(colors[m]));
      if (currentHue < targetHue) {
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

public void colorizeC(PImage shapeSource, PImage pallet) {
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

  quickSort(shapeBrightnessValues, 0, pixelsLength, originalIndexes);
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
    quickSort(colorHueValues, lo, pallet.width, colorIndexes);
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
  float[] shapeHueValues = new float[shapeSource.pixels.length]; //todo: reuse brightness array?
  for (int i = 0; i < shapeHueValues.length; i++) {
    shapeHueValues[i] = hue(color(shapeSource.pixels[i]));
  }
  if (shapeHueValues.length != shapeSource.pixels.length) {
    System.out.printf("lengths do not match: %dvs%d", shapeHueValues.length, shapeSource.pixels.length);
  }
  for (int row = 0; row < shapeSource.height; row++) {
    lo = row * shapeSource.width;
    quickSort(shapeHueValues, lo, shapeSource.width, originalIndexes);
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

// modified from algorithm by Darel Rex Finley found on http://alienryderflex.com/quicksort/
// iterative without stack
static final int MAX_LEVELS = 300;

public static void quickSort(float[] arr, int startIndex, int size, int[] indexes) {
  float piv;
  int i = 0, L, R, swap;
  int[] beg = new int[MAX_LEVELS];
  int[] end = new int[MAX_LEVELS];
  beg[0] = startIndex;
  end[0] = startIndex + size;
  int tempIndex;
  while (i >= 0) {
    L = beg[i];
    R = end[i] - 1;
    if (L < R) {
      tempIndex = indexes[L];
      piv = arr[L];
      boolean didSwap = false;
      while (L < R) {
        while (arr[R] >= piv && L < R) R--;
        if (L < R) {
          didSwap = true;
          indexes[L] = indexes[R];
          arr[L++] = arr[R];
        }
        while (arr[L] <= piv && L < R) L++;
        if (L < R) {
          didSwap = true;
          indexes[R] = indexes[L];
          arr[R--] = arr[L];
        }
      }
      if (didSwap)
        indexes[L] = tempIndex;
      arr[L] = piv;
      beg[i + 1] = L + 1;
      end[i + 1] = end[i];
      end[i++] = L;
      if (end[i] - beg[i] > end[i - 1] - beg[i - 1]) {
        swap = beg[i];
        beg[i] = beg[i - 1];
        beg[i - 1] = swap;
        swap = end[i];
        end[i] = end[i - 1];
        end[i - 1] = swap;
      }
    } else {
      i--;
    }
  }
}

public void saveResult(PImage imageToSave) {
  try {
    SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd'T'HHmmss");
    String resultName = "result-" + format.format(new Date()) + "." + saveFileExtension;
    System.out.println("Saving to " + dataPath(resultName));
    imageToSave.save(dataPath(resultName));
  } 
  catch (Exception ex) {
    System.out.println("Error saving result");
    ex.printStackTrace();
  }
}