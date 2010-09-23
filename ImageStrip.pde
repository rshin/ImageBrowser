int stripWidth;
int gap = 50;

class Image {
  PImage pimg;
  String filename;
  
  // Distance from top left corner, in pixels, required to display the image centered
  double offsetLeft;
  double offsetTop;
  
  double scaledWidth;
  double scaledHeight;
  
  double zoomFactor;
  double imgOffsetLeft;
  double imgOffsetTop;

  Image(String filename) {
    this.filename = filename;    
    pimg = loadImage(filename);
    // Try to scale height to fit
    if (pimg.width / ((double) pimg.height / height) <= width) {
      scaledWidth = pimg.width / ((double) pimg.height / height);
      scaledHeight = height;
      
      offsetLeft = (width - scaledWidth) / 2;
      offsetTop = 0;
    } else {
      scaledWidth = width;
      scaledHeight = pimg.height / ((double) pimg.width / width);
      
      offsetLeft = 0;
      offsetTop = (height - scaledHeight) / 2;
    }
    
    pimg.resize((int) (scaledWidth * 1.5), (int) (scaledHeight * 1.5));
    
    println("w: " + scaledWidth + " h: " + scaledHeight + " l: " + offsetLeft + " t: " + offsetTop);
    
    // Force-draw the image to load it into VRAM (?)
    image(pimg, 0, 0, 0.1, 0.1);

    zoomFactor = 1.0;
    imgOffsetLeft = imgOffsetTop = 0.0;
  }

  void draw(int x, int leftLimit, int rightLimit) {
    float imgX = (float) (x + offsetLeft - imgOffsetLeft - leftLimit - scaledWidth * (zoomFactor - 1.0) / 2);
    float imgY = (float) (offsetTop - imgOffsetTop - scaledHeight * (zoomFactor - 1.0) / 2);
    float imgWidth = (float) (scaledWidth + scaledWidth * (zoomFactor - 1.0));
    float imgHeight = (float) (scaledHeight + scaledHeight * (zoomFactor - 1.0));
    image(pimg, imgX, imgY, imgWidth, imgHeight);
  }
}

List<Image> images = new ArrayList<Image>();

int offsetOfIndex(int i) {
  return i * (gap + width);
}

void drawStrip() {
  // The array index at which the first image is located
  int firstImageIndex = (int) offset / (width + gap);
  if (firstImageIndex < 0) return;

  // Number of pixels from left end of strip to the beginning of this image
  int firstImageOffset = offsetOfIndex(firstImageIndex);

  // Draw the first image, if necessary
  if (firstImageIndex < images.size() && offset <= firstImageOffset + width) {
    images.get(firstImageIndex).draw(0, (int) offset - firstImageOffset, width);
  }

  // Draw the gap (i.e., don't do anything)

  // Draw the second image, if necessary
  int secondImageIndex = firstImageIndex + 1;
  int secondImageOffset = offsetOfIndex(secondImageIndex);
  if (secondImageIndex < images.size() && secondImageOffset - offset < width) {
    images.get(secondImageIndex).draw(secondImageOffset - (int) offset, 0, (int) offset + width - secondImageOffset);
  }
}

void snapToLeft(double origOffset) {
  int index = (int) Math.round(origOffset / (width + gap));
  if (index > 0) {
    index -= 1;
  }
  desiredOffset = offsetOfIndex(index);
  println("Index: " + index + "\tOffset" + origOffset + "\tDOffset" + desiredOffset);
}

void snapToRight(double origOffset) {
  int index = (int) Math.round(origOffset / (width + gap));
  if (index < images.size() - 1) {
    index += 1;
  }
  desiredOffset = offsetOfIndex(index);
  println("Index: " + index + "\tOffset" + origOffset + "\tDOffset" + desiredOffset);
}

void snapOffsetToClosest() {
  int index = (int) offset / (width + gap);
  // The extremes
  if (index < 0) {
    desiredOffset = 0;
    return;
  } else if (index >= images.size() - 1) {
    desiredOffset = offsetOfIndex(images.size() - 1);
    return;
  }
  
  double leftOffset = offsetOfIndex(index);
  double rightOffset = offsetOfIndex(index + 1);
  double mid = (leftOffset + rightOffset) / 2;
  
  if (offset < mid) desiredOffset = leftOffset;
  else desiredOffset = rightOffset;
}
