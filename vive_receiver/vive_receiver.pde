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

void setup() {
  size(800, 600);
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
}

void draw() {
  background(30);

  // 左コントローラー（画面左半分）
  float lsx = map(lx, -2, 2, 0, width/2);
  float lsy = map(lz, -2, 2, 0, height);

  // 右コントローラー（画面右半分）
  float rsx = map(rx, -2, 2, width/2, width);
  float rsy = map(rz, -2, 2, 0, height);

  // 左：グリップで赤
  fill(lGrip == 1 ? color(255, 100, 100) : color(100, 200, 255));
  circle(lsx, lsy, 20 + lTrigger * 40);

  // 左：Yaw方向に線を引いて向きを表示
  stroke(100, 200, 255);
  float lAngle = radians(lYaw);
  line(lsx, lsy,
       lsx + cos(lAngle) * 40,
       lsy + sin(lAngle) * 40);

  // 右：グリップで赤
  noStroke();
  fill(rGrip == 1 ? color(255, 100, 100) : color(100, 255, 200));
  circle(rsx, rsy, 20 + rTrigger * 40);

  // 右：Yaw方向に線を引いて向きを表示
  stroke(100, 255, 200);
  float rAngle = radians(rYaw);
  line(rsx, rsy,
       rsx + cos(rAngle) * 40,
       rsy + sin(rAngle) * 40);

  // テキスト表示
  noStroke();
  fill(255);
  textSize(13);
  int tx = 20;
  text("=== LEFT ===",              tx, 30);
  text("pos:   " + fmt(lx) + ", " + fmt(ly) + ", " + fmt(lz), tx, 48);
  text("rot:   P=" + fmt(lPitch) + " Y=" + fmt(lYaw) + " R=" + fmt(lRoll), tx, 66);
  text("trig:  " + fmt(lTrigger) + "  grip: " + lGrip + "  menu: " + lMenu, tx, 84);

  text("=== RIGHT ===",             tx, 120);
  text("pos:   " + fmt(rx) + ", " + fmt(ry) + ", " + fmt(rz), tx, 138);
  text("rot:   P=" + fmt(rPitch) + " Y=" + fmt(rYaw) + " R=" + fmt(rRoll), tx, 156);
  text("trig:  " + fmt(rTrigger) + "  grip: " + rGrip + "  menu: " + rMenu, tx, 174);
}

String fmt(float v) {
  return nf(v, 1, 2);
}