import processing.opengl.*;
import javax.media.opengl.*;
import TUIO.*;

TuioProcessing tuioClient;
int width = 800;
int height = 600;
double offset = 0;
double desiredOffset = 0;

Object cursorLock = new Object();

TuioCursor firstCursor;
TuioCursor secondCursor;

double scrollBasisFirstCursorX;
double scrollBasisFirstCursorY;

boolean isZooming;
boolean isZoomedIn;
boolean isPanning;

TuioPoint firstCursorLastPos;
TuioPoint secondCursorLastPos;

Image mainVisibleImage;

void setup() {
  size(width, height, OPENGL);
  hint(ENABLE_OPENGL_4X_SMOOTH);
  
  noStroke();
  frameRate(120);  
  
  tuioClient = new TuioProcessing(this);
  
  String imageNames[] = new File(dataPath("")).list(new FilenameFilter() {
    public boolean accept(File dir, String name) {
      return name.matches("(?i).*?\\.(jpe?g|png)$");
    }
  });
  for (String fn : imageNames) {
    images.add(new Image(fn));
  }
  mainVisibleImage = images.get(0);
  
  stripWidth = images.size() * width + (images.size() - 1) * gap;
  //println("strip width: " + stripWidth);
  
  // Enable V-sync
  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
  GL gl = pgl.beginGL();
  gl.setSwapInterval(1);
  pgl.endGL();
  
  isZooming = false;
  isZoomedIn = false;
  isPanning = false;
}

float time = 0;

void draw() {
  if (millis() - time  > 1000) {
    println("Zooming: " + isZooming + "\tZoomedIn: " + isZoomedIn + "\tPanning: " + isPanning);
    time = millis();
  }
  // Clear screen
  background(0);
  
  // Re-calculate offset
  synchronized(cursorLock) {
    if (isPanning && !isZooming) {
      if (!isZoomedIn) {
        double dx = (firstCursor.getX() - scrollBasisFirstCursorX) * width;
        offset -= dx;
      } else {
        double dx = (firstCursor.getX() - scrollBasisFirstCursorX) * width;
        double dy = (firstCursor.getY() - scrollBasisFirstCursorY) * height;
        mainVisibleImage.addToLimits(-dx, -dy);
      }
      scrollBasisFirstCursorX = firstCursor.getX();
      scrollBasisFirstCursorY = firstCursor.getY();
    } else if (!isPanning && isZooming) {
      isZoomedIn = mainVisibleImage.zoomUsingCursors(firstCursor, firstCursorLastPos, secondCursor, secondCursorLastPos);
      
      firstCursorLastPos = firstCursor.getPosition();
      secondCursorLastPos = secondCursor.getPosition();
    } else if (!isPanning && !isZoomedIn && !isZooming) {
      // Animate the snapback
      if (abs((float) desiredOffset - (float) offset) > 1) {
        offset += (desiredOffset - offset) / 10;
      }
    }  
  }
  
  // Draw image strip
  drawStrip();
  
  // Draw touch points
  fill(255, 255 * 0.6);  
  synchronized(cursorLock) {
    if (firstCursor != null) {
      ellipse(firstCursor.getScreenX(width), firstCursor.getScreenY(height), 50, 50);  
    }
    if (secondCursor != null) {
      ellipse(secondCursor.getScreenX(width), secondCursor.getScreenY(height), 50, 50);
    }
  }
}

void addTuioCursor(TuioCursor tcur) {
  synchronized(cursorLock) {
    if (firstCursor == null && secondCursor == null) {
      if (!isZooming && !isZoomedIn && !isPanning) {
        // initial state
      } else if (!isZooming && isZoomedIn && !isPanning) {
        isPanning = true;
      }
      firstCursor = tcur; 
      scrollBasisFirstCursorX = tcur.getX();
      scrollBasisFirstCursorY = tcur.getY();
    } else if (secondCursor == null) {
      secondCursor = tcur;
      if ((!isZooming && !isZoomedIn && !isPanning) ||
          (!isZooming && isZoomedIn && isPanning)) {
        isPanning = false;
        isZooming = true;
        
        firstCursorLastPos = firstCursor.getPosition();
        secondCursorLastPos = secondCursor.getPosition();
      }
    }
  }
}

void removeTuioCursor(TuioCursor tcur) {
  synchronized(cursorLock) {
    if (firstCursor != null && secondCursor != null) {
      boolean removedCursor = false;
      if (firstCursor == tcur) {
        removedCursor = true;
        firstCursor = secondCursor;
        secondCursor = null;
      } else if (secondCursor == tcur) {
        removedCursor = true;
        secondCursor = null;
      }
      
      if (removedCursor) {
         if (isZooming && !isZoomedIn && !isPanning) {
           isZooming = false;
         } else if (isZooming && isZoomedIn && !isPanning) {
           isZooming = false;
           isPanning = true;
         }
         scrollBasisFirstCursorX = firstCursor.getX();
         scrollBasisFirstCursorY = firstCursor.getY();
      }
    } else if (firstCursor != null && firstCursor == tcur) {
      if (!isZooming && !isZoomedIn && !isPanning) {
        //initial state
      } else if ((!isZooming && !isZoomedIn && isPanning) ||
                 (!isZooming && !isZoomedIn && !isPanning)) {
        isPanning = false;
        float xspeed = tcur.getXSpeed();        
        // float xspeed = (tcur.getX() - tcur.getPath().get(tcur.getPath().size() - 5).getX()) / (tcur.getTuioTime().getTotalMilliseconds() - tcur.getPath().get(tcur.getPath().size() - 5).getTuioTime().getTotalMilliseconds());
        // println("x: " + tcur.getX() + " x': " + tcur.getPath().get(tcur.getPath().size() - 5).getX() + " t: " + tcur.getTuioTime().getTotalMilliseconds() + " t': " + tcur.getPath().get(tcur.getPath().size() - 5).getTuioTime().getTotalMilliseconds());
        println("X Speed: " + xspeed);
        if (xspeed > 20) {
          println("Snapping right: " + offset);
          double origOffset = offset + width * (-tcur.getPath().get(0).getX() + tcur.getX());
          snapToRight(origOffset);
          // Going fast
        } else if (xspeed < -20) {
          println("Snapping left: " + offset);
          double origOffset = offset + width * (-tcur.getPath().get(0).getX() + tcur.getX());
          snapToLeft(origOffset);
        } else {
          // println("Snapping offset");
          snapOffsetToClosest();
        }
      } else if (!isZooming && isZoomedIn && isPanning) {
        isPanning = false;
      }
      firstCursor = null;
    }
  }
}

void updateTuioCursor(TuioCursor tcur) {
  synchronized(cursorLock) {
    if (firstCursor == tcur && secondCursor == null && !isZooming && !isZoomedIn && !isPanning) {
      if (tcur.getPosition().getDistance(tcur.getPath().get(0)) > 0.05) {
        isPanning = true;
      }
    }
  }
}

void refresh(TuioTime bundleTime) {
  //redraw();
}

void addTuioObject(TuioObject tobj) {}
void removeTuioObject(TuioObject tobj) {}
void updateTuioObject(TuioObject tobj) {}
