PImage sampleImage;
boolean imageLoaded = false;
int clickCount = 0;

void setup() {
  size(720, 420);
  frameRate(30);

  sampleImage = loadImage("sample.png");
  imageLoaded = sampleImage != null;
}

void draw() {
  background(22, 27, 38);

  // ここから下は、現在のdraw()の残りのコード

  fill(245);
  textSize(24);
  text("Processing 4 + CheerpJ PoC", 24, 42);

  textSize(14);
  fill(190, 200, 215);
  text("JAVA2D / draw() / mouse / keyboard / data folder", 24, 68);

  noStroke();
  fill(63, 145, 220);
  ellipse(130 + sin(frameCount * 0.04) * 55, 160, 72, 72);

  fill(245, 184, 75);
  rect(230, 124, 110, 72, 12);

  fill(220, 100, 120);
  triangle(410, 198, 455, 115, 500, 198);

  fill(245);
  text("data/sample.png: " + (imageLoaded ? "LOADED" : "NOT LOADED"), 24, 258);
  text("mouse clicks: " + clickCount, 24, 284);
  text("frameCount: " + frameCount, 24, 310);
  text("Press any key or click the canvas.", 24, 350);

  if (imageLoaded) {
    image(sampleImage, 550, 112, 120, 120);
  }
}

void mousePressed() {
  clickCount++;
}

void keyPressed() {
  println("keyPressed: " + key);
}

static public void main(String[] passedArgs) {
  String sketchPathArg = (passedArgs != null && passedArgs.length > 0)
      ? passedArgs[0]
      : "--sketch-path=/app/works/demo/v1";

  PApplet.main(new String[] {
    sketchPathArg,
    "ProcessingSmokeTest"
  });
}