import java.awt.*; //<>//
import java.awt.image.*;
import javax.imageio.*;
import java.io.*;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

PImage img;
PImage sortedImg;
PImage colorImg;
PImage sortedColorImg;
PImage finalImg;
String shapeSourceName;
String colorSourceName;

boolean isSelecting;

enum imageSourceType {
  SHAPE, COLOR
};

void setup() {
  size(1200, 400);
  img = null;
  colorImg = null;
  finalImg = null;
  shapeSourceName = null;
  colorSourceName = null;
  isSelecting = false;


  selectImage(imageSourceType.SHAPE);
  selectImage(imageSourceType.COLOR);

  processImages();
}

void draw() {
  background(0);
  if (img != null)
    image(img, 0, 0);
  if (finalImg != null)
    image(finalImg, 400, 0);
  if (colorImg != null)
    image(colorImg, 800, 0);
}

void selectImage(imageSourceType type) {
  if (type == imageSourceType.SHAPE) {
    while (!(shapeSourceName != null)) {
      if (!isSelecting) {
        isSelecting = true;
        selectInput("Select shape image", "shapeImageSelected");
      }
      System.out.print("w"); // doesn't work without this
    }
    System.out.println("out of while loop");
  } else if (type == imageSourceType.COLOR) {
    while (!(colorSourceName != null)) {
      if (!isSelecting) {
        isSelecting = true;
        selectInput("Select color image", "colorImageSelected");
      }
      System.out.print("w"); // doesn't work without this
    }
    System.out.println("out of while loop");
  }
}

void processImages() {
  //img = loadImage(shapeSourceName);
  if (img.width > img.height) {
    img.resize(400, 0);
  } else {
    img.resize(0, 400);
  }
  img.loadPixels();

  //colorImg = loadImage(colorSourceName);
  if (colorImg.width > colorImg.height) {
    colorImg.resize(400, 0);
  } else {
    colorImg.resize(0, 400);
  }
  colorImg.loadPixels();

  sortedImg = createImage(img.width, img.height, RGB);
  sortedColorImg = createImage(colorImg.width, colorImg.height, RGB);
  finalImg = createImage(img.width, img.height, RGB);

  sortedColorImg = colorImg.get();
  sortedColorImg.loadPixels();

  finalImg = img.get();
  finalImg.loadPixels();

  int sortType = 0;// 0 brightness, 1 hue
  quickSort(sortedColorImg.pixels, 0, sortedColorImg.pixels.length - 1, sortType);

  sortedColorImg.updatePixels();
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
        img = new PImage(bimg);
        img.updatePixels();

        isSelecting = false;
        shapeSourceName = name;
        System.out.printf("shapeSourceName:%s isSelecting:%b\n", shapeSourceName, isSelecting);
      } else if (type == imageSourceType.COLOR) {
        colorImg = new PImage(bimg);
        colorImg.updatePixels();

        isSelecting = false;

        colorSourceName = name;
        System.out.printf("colorSourceName:%s isSelecting:%b\n", colorSourceName, isSelecting);
      }
    }
    catch(IOException ex) {
      ex.printStackTrace();
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

void colorizeC(PImage shape, PImage colors) {
  // sort image and keep track of original position
  // swap values with color image's pixels
  // change back to original position

  int[] originalIndexes = new int[shape.pixels.length];
  for (int i = 0; i < originalIndexes.length; i++) {
    originalIndexes[i] = i;
  }

  // fill xCoords and yCoords
  reversableQuicksort(shape.pixels, 0, shape.pixels.length -1, 0, originalIndexes);
  //setup colors to copy
  colors.resize(shape.width, shape.height);

  //sort each row by hue
  for (int row = 0; row < colors.height; row++) {
    int lo = row * colors.width;
    int hi = (row + 1) * colors.width - 1;
    quickSort(colors.pixels, lo, hi, 1);
  }

  for (int row = 0; row < shape.height; row++) {
    int lo = row * shape.width;
    int hi = (row + 1) * shape.width - 1;
    reversableQuicksort(shape.pixels, lo, hi, 1, originalIndexes);
  }

  // revert pixel positions
  for (int i = 0; i < shape.pixels.length; i++) {
    shape.pixels[originalIndexes[i]] = colors.pixels[i];
  }
}

// Quick sort algorithm from https://en.wikipedia.org/wiki/Quicksort
void quickSort(int[] A, int lo, int hi, int flag) {
  if (lo < hi) {
    int p = partition(A, lo, hi, flag);
    quickSort(A, lo, p - 1, flag);
    quickSort(A, p + 1, hi, flag);
  }
}

int partition(int[] A, int lo, int hi, int flag) {
  float pivot = flag == 0 ? brightness(color(A[hi])) : hue(color(A[hi]));
  int i = lo - 1;
  for (int j = lo; j < hi; j++) {
    if ((flag == 0 && brightness(color(A[j])) < pivot) || (flag == 1 && hue(color(A[j])) < pivot)) {
      i = i + 1;
      int temp = A[i];
      A[i] = A[j];
      A[j] = temp;
    }
  }
  if ((flag == 0 && brightness(color(A[hi])) < brightness(color(A[i + 1]))) ||
    (flag == 1 && hue(color(A[hi])) < hue(color(A[i + 1]))) ) {
    int temp = A[i + 1];
    A[i + 1] = A[hi];
    A[hi] = temp;
  }
  return i + 1;
}

// quicksort that saves original positions
void reversableQuicksort(int[] A, int lo, int hi, int flag, int[] indexes) {
  if (lo < hi) {
    int p = reversablePartition(A, lo, hi, flag, indexes);
    reversableQuicksort(A, lo, p - 1, flag, indexes);
    reversableQuicksort(A, p + 1, hi, flag, indexes);
  }
}

int reversablePartition(int[] A, int lo, int hi, int flag, int[] indexes) {
  float pivot = flag == 0 ? brightness(color(A[hi])) : hue(color(A[hi]));
  int i = lo - 1;
  for (int j = lo; j < hi; j++) {
    if ((flag == 0 && brightness(color(A[j])) < pivot) ||
      (flag == 1 && hue(color(A[j])) < pivot)
      ) {
      i = i + 1;
      swap(A, i, j);
      swap(indexes, i, j);
    }
  }
  if ((flag == 0 && brightness(color(A[hi])) < brightness(color(A[i + 1]))) ||
    (flag == 1 && hue(color(A[hi])) < hue(color(A[i + 1])))
    ) {
    swap(A, i+1, hi);
    swap(indexes, i+1, hi);
  }
  return i + 1;
}

void swap(int[] arr, int a, int b) {
  int temp = arr[a];
  arr[a] = arr[b];
  arr[b] = temp;
}