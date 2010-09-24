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

  double zoomFactor = 1.0;
  double topLeftX = 0, topLeftY = 0;
  double bottomRightX = width, bottomRightY = height;

  Image(String filename) {
    this.filename = filename;    
    pimg = loadImage(filename);
    // Try to scale height to fit
    if (pimg.width / ((double) pimg.height / height) <= width) {
      scaledWidth = pimg.width / ((double) pimg.height / height);
      scaledHeight = height;

      offsetLeft = (width - scaledWidth) / 2;
      offsetTop = 0;
    } 
    else {
      scaledWidth = width;
      scaledHeight = pimg.height / ((double) pimg.width / width);

      offsetLeft = 0;
      offsetTop = (height - scaledHeight) / 2;
    }

    pimg.resize((int) (scaledWidth * 2), (int) (scaledHeight * 2));

    println("w: " + scaledWidth + " h: " + scaledHeight + " l: " + offsetLeft + " t: " + offsetTop);

    // Force-draw the image to load it into VRAM (?)
    image(pimg, 0, 0, 0.1, 0.1);
  }

  void draw(int x, int leftLimit, int rightLimit) {
    float imgX = (float) (x + offsetLeft - leftLimit - topLeftX * width / (bottomRightX - topLeftX));
    float imgY = (float) (offsetTop - topLeftY * height / (bottomRightY - topLeftY));
    float imgWidth = (float) (scaledWidth * width / (bottomRightX - topLeftX)); // scaledWidth / (min((float) bottomRightX, (float) (width - offsetLeft)) - topLeftX));
    float imgHeight = (float) (scaledHeight * height / (bottomRightY - topLeftY)); // scaledHeight / (min((float) bottomRightY, (float) (height - offsetTop)) - topLeftY));
    // println("imgX: " + imgX + " imgY: " + imgY + " w: " + (imgWidth) + " h: " + (imgHeight) + " tlX: " + topLeftX + " tlY: " + topLeftY + " brX: " + bottomRightX + " brY: " + bottomRightY);
    image(pimg, imgX, imgY, imgWidth, imgHeight);
  }

  boolean zoomUsingCursors(TuioPoint first, TuioPoint prevFirst, TuioPoint second, TuioPoint prevSecond) {
    double cursorDistance = first.getDistance(second);
    double prevCursorDistance = prevFirst.getDistance(prevSecond);

    zoomFactor *= cursorDistance / prevCursorDistance;
    if (1.0 <= zoomFactor) {
      double prevCenterX = (prevFirst.getX() + prevSecond.getX()) / 2, prevCenterY = (prevFirst.getY() + prevSecond.getY()) / 2;
      double centerX = (first.getX() + second.getX()) / 2, centerY = (first.getY() + second.getY()) / 2;

      // Ensure that center of touches stays in same location relative to image
      double prevCenterXinFrame = topLeftX + (bottomRightX - topLeftX) * prevCenterX; 
      double prevCenterYinFrame = topLeftY + (bottomRightY - topLeftY) * prevCenterY;
      
//      topLeftX = centerX - width / 2; topLeftY = centerY - height / 2;
      bottomRightX = topLeftX + width / zoomFactor; bottomRightY = topLeftY + height / zoomFactor;
      
      double centerXinFrame = topLeftX + (bottomRightX - topLeftX) * centerX;
      double centerYinFrame = topLeftY + (bottomRightY - topLeftY) * centerY;
            
      topLeftX -= centerXinFrame - prevCenterXinFrame; topLeftY -= centerYinFrame - prevCenterYinFrame;
      bottomRightX -= centerXinFrame - prevCenterXinFrame; bottomRightY -= centerYinFrame - prevCenterYinFrame;

      clampLimits();
      // println("pcX: " + prevCenterX + " cX: " + centerX + " tlX: " + topLeftX + " tlY: " + topLeftY + " brX: " + bottomRightX + " brY: " + bottomRightY);
    } else {
      zoomFactor = 1.0;
    }
    return abs((float) zoomFactor - 1.0) > 0.05;
  }
  
  void addToLimits(double dx, double dy) {
    topLeftX += dx; topLeftY += dy;
    bottomRightX += dx; bottomRightY += dy;
    clampLimits();
  }
  
  void clampLimits() {
    if (topLeftX < 0) {
//        println("topLeftX < 0");
      bottomRightX += -topLeftX; 
      topLeftX = 0;
    }
    if (topLeftY < 0) {
//        println("topLeftY < 0");
      bottomRightY += -topLeftY; 
      topLeftY = 0;
    }
    if (bottomRightX > width) {
//        println("bottomRightX > width");
      topLeftX -= bottomRightX - width; 
      bottomRightX = width;
    }
    if (bottomRightY > height) {
//        println("bottomRightY > height");
      topLeftY -= bottomRightY - height; 
      bottomRightY = height;
    }
  }
}

List<Image> images = new ArrayList<Image>();

int offsetOfIndex(int i) {
  return i * (gap + width);
}

void drawStrip() {
  int firstImageVisibleWidth = 0, secondImageVisibleWidth = 0;

  // The array index at which the first image is located
  int firstImageIndex = (int) offset / (width + gap);
  if (firstImageIndex < 0) return;

  // Number of pixels from left end of strip to the beginning of this image
  int firstImageOffset = offsetOfIndex(firstImageIndex);

  // Draw the first image, if necessary
  if (firstImageIndex < images.size() && offset <= firstImageOffset + width) {
    images.get(firstImageIndex).draw(0, (int) offset - firstImageOffset, width);
    firstImageVisibleWidth = width - (int) (offset - firstImageOffset);
  }

  // Draw the gap (i.e., don't do anything)

  // Draw the second image, if necessary
  int secondImageIndex = firstImageIndex + 1;
  int secondImageOffset = offsetOfIndex(secondImageIndex);
  if (secondImageIndex < images.size() && secondImageOffset - offset < width) {
    images.get(secondImageIndex).draw(secondImageOffset - (int) offset, 0, (int) offset + width - secondImageOffset);
    secondImageVisibleWidth = (int) offset + width - secondImageOffset;
  }

  // Update the main visible image (whichever is taking up the most space)
  if (firstImageVisibleWidth > secondImageVisibleWidth)
    mainVisibleImage = images.get(firstImageIndex);
  else
    mainVisibleImage = images.get(secondImageIndex);
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
  } 
  else if (index >= images.size() - 1) {
    desiredOffset = offsetOfIndex(images.size() - 1);
    return;
  }

  double leftOffset = offsetOfIndex(index);
  double rightOffset = offsetOfIndex(index + 1);
  double mid = (leftOffset + rightOffset) / 2;

  if (offset < mid) desiredOffset = leftOffset;
  else desiredOffset = rightOffset;
}

