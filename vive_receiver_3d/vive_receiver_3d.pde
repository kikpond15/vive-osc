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

// カメラ操作用
float camRotX = -0.3;
float camRotY = 0.0;
float scale = 200;  // 1メートル = 200px

void setup() {
  size(800, 600, P3D);  // P3Dモードに変更
  oscP5 = new OscP5(this, 9000);
}

void oscEvent(OscMessage msg) {
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
  } else if (msg.checkAddrPattern("/controller/right/pos")) {
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
}

void draw() {
  background(30);

  // カメラをマウスドラッグで操作
  if (mousePressed) {
    camRotY += (mouseX - pmouseX) * 0.01;
    camRotX += (mouseY - pmouseY) * 0.01;
  }

  // 3D空間の中心を画面中央に
  translate(width / 2, height / 2, 0);
  rotateX(camRotX);
  rotateY(camRotY);

  // 床グリッドを描画（4m x 4m）
  drawGrid();

  // 左コントローラー
  pushMatrix();
  // SteamVR座標 → Processing座標（Y軸を反転）
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

  // HUDテキスト（3D変換をリセットして2D表示）
  drawHUD();
}

void drawController(color c, float trigger) {
  // 本体
  fill(c);
  noStroke();
  box(20, 20, 40);

  // 向きを示す矢印
  stroke(255, 255, 0);
  strokeWeight(2);
  line(0, 0, 0, 0, 0, -60);  // Z負方向（前方）
  noStroke();

  // トリガー量で先端の球が大きくなる
  pushMatrix();
  translate(0, 0, -60);
  fill(255, 255, 0);
  sphere(5 + trigger * 15);
  popMatrix();
}

void drawGrid() {
  int gridSize = 4;   // 4m
  int gridStep = 1;   // 1m間隔

  stroke(80);
  strokeWeight(1);
  for (int i = -gridSize; i <= gridSize; i += gridStep) {
    // X方向のライン
    line(i * scale, 0, -gridSize * scale,
         i * scale, 0,  gridSize * scale);
    // Z方向のライン
    line(-gridSize * scale, 0, i * scale,
          gridSize * scale, 0, i * scale);
  }

  // 原点マーク
  strokeWeight(3);
  stroke(255, 0, 0);   line(0, 0, 0, scale, 0, 0);   // X軸（赤）
  stroke(0, 255, 0);   line(0, 0, 0, 0, -scale, 0);  // Y軸（緑）
  stroke(0, 0, 255);   line(0, 0, 0, 0, 0, scale);   // Z軸（青）
}

void drawHUD() {
  // 3D変換をリセットしてHUDを2Dで描画
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
  text("trig: " + fmt(lTrigger) + "  grip: " + lGrip, tx, 84);

  text("=== RIGHT ===", tx, 120);
  text("pos: " + fmt(rx) + ", " + fmt(ry) + ", " + fmt(rz), tx, 138);
  text("rot: P=" + fmt(rPitch) + " Y=" + fmt(rYaw) + " R=" + fmt(rRoll), tx, 156);
  text("trig: " + fmt(rTrigger) + "  grip: " + rGrip, tx, 174);

  text("[drag] rotate camera", tx, height - 20);
  hint(ENABLE_DEPTH_TEST);
}

String fmt(float v) {
  return nf(v, 1, 2);
}