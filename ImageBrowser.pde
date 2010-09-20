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

Set<TuioCursor> cursors = new HashSet<TuioCursor>();
double scrollBasisCursorX;

boolean isZooming;
boolean isZoomedIn;
boolean isPanning;

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
  
  stripWidth = images.size() * width + (images.size() - 1) * gap;
  println("strip width: " + stripWidth);
  
  // Enable V-sync
  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
  GL gl = pgl.beginGL();
  gl.setSwapInterval(1);
  pgl.endGL();
}

void draw() {
  // Clear screen
  background(0);
  
  // Re-calculate offset
  synchronized(cursors) {
    if (isScrolling) {
      TuioCursor c = cursors.iterator().next();
      double dx = (c.getX() - scrollBasisCursorX) * width;
      offset -= dx;
      scrollBasisCursorX = c.getX();
      // println("cx: " + c.getX() + " bx: " + scrollBasisCursor.getX() +  "dx: " + dx);
    }
  }
  
  if (!isScrolling) {
    // Animate the snapback
    if (desiredOffset != offset) {
      offset += (desiredOffset - offset) / 10;
    }
  }
  
  // Draw image strip
  drawStrip();
  
  // Draw touch points
  fill(255, 255 * 0.6);  
  synchronized(cursors) {
    for (TuioCursor tcur : cursors) {
      ellipse(tcur.getScreenX(width), tcur.getScreenY(height), 50, 50);
    }
  }
}


void updateScrollBasis() {
  if (cursors.size() == 1) {
      isScrolling = true;
      scrollBasisCursorX = cursors.iterator().next().getX();
    } else {
      isScrolling = false;
      snapOffsetToClosest();
  }
}

void updateState() {
  if (isPanning) {
    if (firstCursor == null && secondCursor == null) {
      isPanning = false;
    }
  } else if (isZooming) {
    if (secondCursor == null) {
      isZooming = false;
      isPanning = true;
    }
  } else {
    if (firstCursor != null && secondCursor != null) {
      isZooming = true;
    }
  }
}

void addTuioCursor(TuioCursor tcur) {
  synchronized(cursorLock) {
    if (!firstCursor) tcur = firstCursor;
    else if (!secondCursor) tcur = secondCursor;

    updateState();
  }
}

void removeTuioCursor(TuioCursor tcur) {
  synchronized(cursorLock) {
    if (firstCursor == tcur) {
      firstCursor = secondCursor;
      secondCursor = null;
    } else if (secondCursor == tcur) secondCursor = null;

    updateState();
  }
}

void updateTuioCursor(TuioCursor tcur) {
  if (firstCursor == tcur && secondCursor == null && !isZooming && !isPanning) {
    if (tcur.getPosition().getDistance(tcur.getPath().get(0)) > 0.01) {
      isPanning = true;
    }
  }
}

void refresh(TuioTime bundleTime) {
  redraw();
}

void addTuioObject(TuioObject tobj) {}
void removeTuioObject(TuioObject tobj) {}
void updateTuioObject(TuioObject tobj) {}