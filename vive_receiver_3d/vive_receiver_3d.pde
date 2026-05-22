import oscP5.*;
import netP5.*;

OscP5 oscP5;

// 左コントローラー
float lx, ly, lz;
float lPitch, lYaw, lRoll;
float lTrigger;
int lGrip, lMenu;

// 右コントローラー
float rx, ry, rz;
float rPitch, rYaw, rRoll;
float rTrigger;
int rGrip, rMenu;

// トラッカー
float t0x, t0y, t0z;
float t0Pitch, t0Yaw, t0Roll;

// カメラ操作用
float camRotX = -0.3;
float camRotY = 0.0;
float camZ = -600;
float scale = 200;// 1メートル = 200px

void setup() {
  size(800, 600, P3D);
  oscP5 = new OscP5(this, 9000);
}

void oscEvent(OscMessage msg) {
  // 左コントローラー
  if (msg.checkAddrPattern("/controller/left/pos")) {
    lx = msg.get(0).floatValue();
    ly = msg.get(1).floatValue();
    lz = msg.get(2).floatValue();
  } else if (msg.checkAddrPattern("/controller/left/rot")) {
    lPitch = msg.get(0).floatValue();
    lYaw   = msg.get(1).floatValue();
    lRoll  = msg.get(2).floatValue();
  } else if (msg.checkAddrPattern("/controller/left/trigger")) {
    lTrigger = msg.get(0).floatValue();
  } else if (msg.checkAddrPattern("/controller/left/grip")) {
    lGrip = msg.get(0).intValue();
  } else if (msg.checkAddrPattern("/controller/left/menu")) {
    lMenu = msg.get(0).intValue();
  }
  // 右コントローラー
  else if (msg.checkAddrPattern("/controller/right/pos")) {
    rx = msg.get(0).floatValue();
    ry = msg.get(1).floatValue();
    rz = msg.get(2).floatValue();
  } else if (msg.checkAddrPattern("/controller/right/rot")) {
    rPitch = msg.get(0).floatValue();
    rYaw   = msg.get(1).floatValue();
    rRoll  = msg.get(2).floatValue();
  } else if (msg.checkAddrPattern("/controller/right/trigger")) {
    rTrigger = msg.get(0).floatValue();
  } else if (msg.checkAddrPattern("/controller/right/grip")) {
    rGrip = msg.get(0).intValue();
  } else if (msg.checkAddrPattern("/controller/right/menu")) {
    rMenu = msg.get(0).intValue();
  }
  // トラッカー
  else if (msg.checkAddrPattern("/tracker/0/pos")) {
    t0x = msg.get(0).floatValue();
    t0y = msg.get(1).floatValue();
    t0z = msg.get(2).floatValue();
  } else if (msg.checkAddrPattern("/tracker/0/rot")) {
    t0Pitch = msg.get(0).floatValue();
    t0Yaw   = msg.get(1).floatValue();
    t0Roll  = msg.get(2).floatValue();
  }
}

void draw() {
  background(30);

  // マウスドラッグでカメラ回転
  if (mousePressed) {
    camRotY += (mouseX - pmouseX) * 0.01;
    camRotX += (mouseY - pmouseY) * 0.01;
  }

  // 3D空間の中心を画面中央に
  translate(width / 2, height / 2, camZ);
  rotateX(camRotX);
  rotateY(camRotY);

  // 床グリッド
  drawGrid();

  // 左コントローラー
  pushMatrix();
  translate(-lx * scale, -ly * scale, lz * scale);
  rotateY(radians(-lYaw));
  rotateX(radians(lPitch));
  rotateZ(radians(lRoll));
  drawController(
    lGrip == 1 ? color(255, 100, 100) : color(100, 200, 255),
    lTrigger
  );
  popMatrix();

  // 右コントローラー
  pushMatrix();
  translate(-rx * scale, -ry * scale, rz * scale);
  rotateY(radians(-rYaw));
  rotateX(radians(rPitch));
  rotateZ(radians(rRoll));
  drawController(
    rGrip == 1 ? color(255, 100, 100) : color(100, 255, 200),
    rTrigger
  );
  popMatrix();

  // トラッカー0
  pushMatrix();
  translate(-t0x * scale, -t0y * scale, t0z * scale);
  rotateY(radians(-t0Yaw));
  rotateX(radians(t0Pitch));
  rotateZ(radians(t0Roll));
  drawTracker(color(255, 200, 0));
  popMatrix();

  // HUD
  drawHUD();
}

void drawController(color c, float trigger) {
  fill(c);
  noStroke();
  box(20, 20, 40);

  stroke(255, 255, 0);
  strokeWeight(2);
  line(0, 0, 0, 0, 0, -60);
  noStroke();

  pushMatrix();
  translate(0, 0, -60);
  fill(255, 255, 0);
  sphere(5 + trigger * 15);
  popMatrix();
}

void drawTracker(color c) {
  fill(c);
  noStroke();
  box(40, 10, 40);

  stroke(255, 100, 0);
  strokeWeight(2);
  line(0, 0, 0, 0, -40, 0);
  noStroke();

  pushMatrix();
  translate(0, -40, 0);
  fill(255, 100, 0);
  sphere(6);
  popMatrix();
}

void drawGrid() {
  int gridSize = 4;
  int gridStep = 1;

  stroke(80);
  strokeWeight(1);
  for (int i = -gridSize; i <= gridSize; i += gridStep) {
    line(i * scale, 0, -gridSize * scale, i * scale, 0,  gridSize * scale);
    line(-gridSize * scale, 0, i * scale,  gridSize * scale, 0, i * scale);
  }

  strokeWeight(3);
  stroke(255, 0, 0); line(0, 0, 0, scale, 0, 0);    // X軸（赤）
  stroke(0, 255, 0); line(0, 0, 0, 0, -scale, 0);   // Y軸（緑）
  stroke(0, 0, 255); line(0, 0, 0, 0, 0, scale);    // Z軸（青）
}

void mouseWheel(MouseEvent event) {
  camZ += event.getCount() * 30;
  camZ = constrain(camZ, -2000, -100);  // ズーム範囲の制限
}

void drawHUD() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();

  fill(255);
  noStroke();
  textSize(13);
  int tx = 20;
  text("=== LEFT ===", tx, 30);
  text("pos: " + fmt(lx) + ", " + fmt(ly) + ", " + fmt(lz), tx, 48);
  text("rot: P=" + fmt(lPitch) + " Y=" + fmt(lYaw) + " R=" + fmt(lRoll), tx, 66);
  text("trig: " + fmt(lTrigger) + "  grip: " + lGrip + "  menu: " + lMenu, tx, 84);

  text("=== RIGHT ===", tx, 120);
  text("pos: " + fmt(rx) + ", " + fmt(ry) + ", " + fmt(rz), tx, 138);
  text("rot: P=" + fmt(rPitch) + " Y=" + fmt(rYaw) + " R=" + fmt(rRoll), tx, 156);
  text("trig: " + fmt(rTrigger) + "  grip: " + rGrip + "  menu: " + rMenu, tx, 174);

  text("=== TRACKER 0 ===", tx, 210);
  text("pos: " + fmt(t0x) + ", " + fmt(t0y) + ", " + fmt(t0z), tx, 228);
  text("rot: P=" + fmt(t0Pitch) + " Y=" + fmt(t0Yaw) + " R=" + fmt(t0Roll), tx, 246);

  text("[drag] rotate camera", tx, height - 20);
  hint(ENABLE_DEPTH_TEST);
}

String fmt(float v) {
  return nf(v, 1, 2);
}