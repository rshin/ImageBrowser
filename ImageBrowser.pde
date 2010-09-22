import processing.opengl.*;
import javax.media.opengl.*;
import TUIO.*;

TuioProcessing tuioClient;
int width = 1280;
int height = 800;
double offset = 0;
double desiredOffset = 0;

Object cursorLock;

TuioCursor firstCursor;
TuioCursor secondCursor;

double scrollBasisFirstCursorX;
double scrollBasisFirstCursorY;

boolean isZooming;
boolean isZoomedIn;
boolean isPanning;

void setup() {
  size(width, height, OPENGL);
  hint(ENABLE_OPENGL_4X_SMOOTH);
  
  noStroke();
  frameRate(120);  
  
  tuioClient = new TuioProcessing(this);
  cursorLock = tuioClient;
  
  String imageNames[] = new File(dataPath("")).list(new FilenameFilter() {
    public boolean accept(File dir, String name) {
      return name.matches("(?i).*?\\.(jpe?g|png)$");
    }
  });
  for (String fn : imageNames) {
    images.add(new Image(fn));
  }
  
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
    if (isPanning && !isZoomedIn && !isZooming) {
      if (!isZoomedIn) {
        double dx = (firstCursor.getX() - scrollBasisFirstCursorX) * width;
        offset -= dx;
        scrollBasisFirstCursorX = firstCursor.getX();
        scrollBasisFirstCursorY = firstCursor.getY();
      }
    } else if (!isPanning && !isZoomedIn && !isZooming) {
      // Animate the snapback
      if (desiredOffset != offset) {
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
      if ((!isZooming && !isZoomedIn && !isPanning) ||
          (!isZooming && isZoomedIn && isPanning)) {
        isZooming = true;
        isPanning = false;
      }
      secondCursor = tcur;
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
      }
    } else if (firstCursor != null && firstCursor == tcur) {
      if (!isZooming && !isZoomedIn && !isPanning) {
        //initial state
      } else if ((!isZooming && !isZoomedIn && isPanning) ||
                 (!isZooming && !isZoomedIn && !isPanning)) {
        isPanning = false;
        float xspeed = tcur.getXSpeed();
        println("X Speed: " + xspeed);
        if (xspeed > 20) {
          println("Snapping left");
          snapToLeft();
          // Going fast
        } else if (xspeed < -20) {
          println("Snapping right");
          snapToRight();
        } else {
          println("Snapping offset");
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
