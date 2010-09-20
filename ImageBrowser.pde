import processing.opengl.*;
import javax.media.opengl.*;
import TUIO.*;

TuioProcessing tuioClient;
int width = 1280;
int height = 800;
double offset = 0;
double desiredOffset = 0;

Set<TuioCursor> cursors = new HashSet<TuioCursor>();
boolean isScrolling;
double scrollBasisCursorX;

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

void addTuioCursor(TuioCursor tcur) {
  synchronized(cursors) {
    cursors.add(tcur);
    updateScrollBasis();
  }
}

void removeTuioCursor(TuioCursor tcur) {
  synchronized(cursors) {
    cursors.remove(tcur);
    updateScrollBasis();
  }
}

void refresh(TuioTime bundleTime) {
  redraw();
}

void addTuioObject(TuioObject tobj) {}
void removeTuioObject(TuioObject tobj) {}
void updateTuioObject(TuioObject tobj) {}
void updateTuioCursor(TuioCursor tcur) {}