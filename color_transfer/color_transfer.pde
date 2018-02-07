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

  long startTime = System.currentTimeMillis();
  //colorizeA(finalImg, sortedColorImg); System.out.println("using colorizeA");
  //colorizeB(finalImg, sortedColorImg); System.out.println("using colorizeB");
  colorizeC(finalImg, sortedColorImg); System.out.println("using colorizeC");
  long endTime = System.currentTimeMillis();
  System.out.printf("Time taken: %dms\n", endTime - startTime);
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
      System.out.printf("resized width:%d height:%d factor:%.3f\n", scaledWidth, scaledHeight, scaleFactor);
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

public void colorizeA(PImage shapeSource, PImage colorSource) {
  // for each pixel in shape image,
  // find closest pixel in sorted color array based on brightness
  // and replace with it
  sortPixels(colorSource, false, null);
  for (int i = 0; i < shapeSource.pixels.length; i++) {
    float targetBrightness = brightness(color(shapeSource.pixels[i]));
    int lo = 0, hi = colorSource.pixels.length - 1;
    int m = (lo + hi) / 2;
    while (lo <= hi) {
      m = (lo + hi) / 2;
      float currentBrightness = brightness(color(colorSource.pixels[m]));
      if (currentBrightness < targetBrightness) {
        lo = m + 1;
      } else if (currentBrightness > targetBrightness) {
        hi = m - 1;
      } else {
        break;
      }
    }
    shapeSource.pixels[i] = colorSource.pixels[m];
  }

  shapeSource.updatePixels();
  isFinished = true;
  redraw();

  saveResult(shapeSource);
}

public void colorizeB(PImage shapeSource, PImage colorSource) {
  // for each pixel in shape image,
  // find closest pixel in sorted color array based on brightness
  // then find the closest in hue within a range
  // and replace with it
  sortPixels(colorSource, false, null);
  for (int i = 0; i < shapeSource.pixels.length; i++) {
    float targetBrightness = brightness(color(shapeSource.pixels[i]));
    int lo = 0, hi = colorSource.pixels.length - 1;
    int m = (lo + hi) / 2;
    while (lo <= hi) {
      m = (lo + hi) / 2;
      float currentBrightness = brightness(color(colorSource.pixels[m]));
      if (currentBrightness < targetBrightness) {
        lo = m + 1;
      } else if (currentBrightness > targetBrightness) {
        hi = m - 1;
      } else {
        break;
      }
    }
    // find close hue
    float targetHue = hue(color(shapeSource.pixels[i]));
    lo = (m / shapeSource.width) * shapeSource.width;
    hi = lo + shapeSource.width - 1;
    while (lo <= hi) {
      m = (lo + hi) / 2;
      float currentHue = hue(color(colorSource.pixels[m]));
      if (currentHue < targetHue) {
        lo = m + 1;
      } else if (currentHue > targetHue) {
        hi = m - 1;
      } else {
        break;
      }
    }
    shapeSource.pixels[i] = colorSource.pixels[m];
  }

  shapeSource.updatePixels();
  isFinished = true;
  redraw();

  saveResult(shapeSource);
}

public void colorizeC(PImage shapeSource, PImage colorSource) {
  // sort image and keep track of original position
  // swap values with color image's pixels
  // change back to original position
  int[] originalIndexes = sortPixels(shapeSource, true, null);
  sortPixels(colorSource, true, null);

  // apply colors to shape image
  for (int i = 0; i < shapeSource.pixels.length; i++) {
    shapeSource.pixels[originalIndexes[i]] = colorSource.pixels[i];
  }
  if (colorSource.pixels.length > shapeSource.pixels.length) {
    // make smaller before sorting
    colorSource.resize(shapeSource.width, shapeSource.height);
  }
  sortPixels(colorSource, true, null);
  if (colorSource.pixels.length <= shapeSource.pixels.length) {
    // make larger after sorting
    colorSource.resize(shapeSource.width, shapeSource.height);
  }

  // apply colors to shape image
  for (int i = 0; i < shapeSource.pixels.length; i++) {
    shapeSource.pixels[originalIndexes[i]] = colorSource.pixels[i];
  }


  shapeSource.updatePixels();
  isFinished = true;
  redraw();

  saveResult(shapeSource);
}

// sorts pixels by brightness and optionally, also sorts rows hue
// returns array of original indexes
int[] sortPixels(PImage img, boolean shouldSortByHue, int[] originalIndexes) {
  int pixelsLength = img.pixels.length;
  img.loadPixels();

  if (originalIndexes == null)
    originalIndexes = new int[pixelsLength];

  float[] values = new float[pixelsLength];
  int[] pixelsCopy = new int[pixelsLength];
  for (int i = 0; i < pixelsLength; i++) {
    originalIndexes[i] = i;
    pixelsCopy[i] = img.pixels[i];
    values[i] = brightness(color(img.pixels[i]));
  }

  quickSort(values, 0, pixelsLength, originalIndexes);

  // sort shapeSource pixels to get hue values later
  for (int i = 0; i < pixelsLength; i++) {
    img.pixels[i] = pixelsCopy[originalIndexes[i]];
  }

  if (!shouldSortByHue) return originalIndexes;

  for (int i = 0; i < values.length; i++) {
    values[i] = hue(color(img.pixels[i]));
  }

  // sort each row by hue
  int lo;
  for (int row = 0; row < img.height; row++) {
    lo = row * img.width;
    quickSort(values, lo, img.width, originalIndexes);
  }
  for (int i = 0; i < pixelsLength; i++) {
    img.pixels[i] = pixelsCopy[originalIndexes[i]];
  }

  return originalIndexes;
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