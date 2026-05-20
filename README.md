# VIVE OSC Reference

HTC VIVEのコントローラー・トラッカーの座標・回転・ボタン入力をOSCで送信するシステムのリファレンスドキュメント。

---

## システム構成

```
SteamVR（HTC VIVE動作中）
    ↓ OpenVR API
Python スクリプト（vive_osc_sender.py）
    ↓ UDP / OSC（port: 9000）
受信アプリケーション（Processing / TouchDesigner / Max/MSP など）
```

### 動作環境

| 項目 | 内容 |
|---|---|
| OS | Windows 10/11 |
| Python | 3.11 以上 |
| 依存ライブラリ | `openvr`, `python-osc` |
| 送信プロトコル | UDP / OSC |
| 送信先IP | 127.0.0.1（デフォルト：localhost） |
| 送信先ポート | 9000（デフォルト） |
| 送信レート | 60Hz |

---

## OSCアドレス一覧

### コントローラー（左）

| アドレス | 型 | 値の範囲 | 内容 |
|---|---|---|---|
| `/controller/left/pos` | `[float, float, float]` | 実数（メートル） | 位置 x, y, z |
| `/controller/left/rot` | `[float, float, float]` | -180.0 〜 180.0（度） | 回転 Pitch, Yaw, Roll |
| `/controller/left/trigger` | `float` | 0.0 〜 1.0 | トリガー引き量 |
| `/controller/left/grip` | `int` | 0 or 1 | グリップボタン |
| `/controller/left/menu` | `int` | 0 or 1 | メニューボタン |

### コントローラー（右）

| アドレス | 型 | 値の範囲 | 内容 |
|---|---|---|---|
| `/controller/right/pos` | `[float, float, float]` | 実数（メートル） | 位置 x, y, z |
| `/controller/right/rot` | `[float, float, float]` | -180.0 〜 180.0（度） | 回転 Pitch, Yaw, Roll |
| `/controller/right/trigger` | `float` | 0.0 〜 1.0 | トリガー引き量 |
| `/controller/right/grip` | `int` | 0 or 1 | グリップボタン |
| `/controller/right/menu` | `int` | 0 or 1 | メニューボタン |

### VIVEトラッカー

| アドレス | 型 | 値の範囲 | 内容 |
|---|---|---|---|
| `/tracker/{id}/pos` | `[float, float, float]` | 実数（メートル） | 位置 x, y, z |
| `/tracker/{id}/rot` | `[float, float, float]` | -180.0 〜 180.0（度） | 回転 Pitch, Yaw, Roll |

> `{id}` はSteamVRが割り当てるデバイスインデックス番号（整数）。複数台接続時は番号が異なる。

---

## 座標系

SteamVR（OpenVR）の座標系に準拠。

```
Y軸 ↑
     |
     |____→ X軸
    /
   ↙ Z軸
```

| 軸 | 方向 |
|---|---|
| X | 右方向が正 |
| Y | 上方向が正 |
| Z | 手前方向が正 |
| 原点 | SteamVRルームセットアップ中心 |
| 単位 | メートル |

### 回転（オイラー角）

| 軸 | 内容 |
|---|---|
| Pitch | X軸回転（上下方向の傾き） |
| Yaw | Y軸回転（左右方向の向き） |
| Roll | Z軸回転（ひねり） |
| 単位 | 度（degrees） |

---

## Pythonスクリプト（vive_osc_sender.py）

```python
import openvr
import time
import math
from pythonosc import udp_client

# OSC送信先（受信アプリのIP・ポートに合わせて変更）
client = udp_client.SimpleUDPClient("127.0.0.1", 9000)

vr = openvr.init(openvr.VRApplication_Background)
poses = (openvr.TrackedDevicePose_t * openvr.k_unMaxTrackedDeviceCount)()

def get_position(matrix):
    x = matrix[0][3]
    y = matrix[1][3]
    z = matrix[2][3]
    return x, y, z

def get_euler(matrix):
    pitch = math.asin(-matrix[1][2])
    yaw   = math.atan2(matrix[0][2], matrix[2][2])
    roll  = math.atan2(matrix[1][0], matrix[1][1])
    return (
        math.degrees(pitch),
        math.degrees(yaw),
        math.degrees(roll)
    )

while True:
    vr.getDeviceToAbsoluteTrackingPose(
        openvr.TrackingUniverseStanding, 0, poses
    )

    for i in range(openvr.k_unMaxTrackedDeviceCount):
        if not poses[i].bPoseIsValid:
            continue

        device_class = vr.getTrackedDeviceClass(i)
        matrix = poses[i].mDeviceToAbsoluteTracking
        x, y, z = get_position(matrix)
        pitch, yaw, roll = get_euler(matrix)

        # コントローラー
        if device_class == openvr.TrackedDeviceClass_Controller:
            hand = vr.getControllerRoleForTrackedDeviceIndex(i)
            side = "left" if hand == openvr.TrackedControllerRole_LeftHand else "right"

            client.send_message(f"/controller/{side}/pos", [x, y, z])
            client.send_message(f"/controller/{side}/rot", [pitch, yaw, roll])

            result, state = vr.getControllerState(i)
            if result:
                trigger = state.rAxis[1].x
                grip    = bool(state.ulButtonPressed & (1 << openvr.k_EButton_Grip))
                menu    = bool(state.ulButtonPressed & (1 << openvr.k_EButton_ApplicationMenu))
                client.send_message(f"/controller/{side}/trigger", trigger)
                client.send_message(f"/controller/{side}/grip",    int(grip))
                client.send_message(f"/controller/{side}/menu",    int(menu))

        # VIVEトラッカー
        elif device_class == openvr.TrackedDeviceClass_GenericTracker:
            client.send_message(f"/tracker/{i}/pos", [x, y, z])
            client.send_message(f"/tracker/{i}/rot", [pitch, yaw, roll])

    time.sleep(1/60)
```

---

## 受信側の実装例

### Processing（oscP5ライブラリ）

```java
import oscP5.*;
import netP5.*;

OscP5 oscP5;
float lx, ly, lz;
float lPitch, lYaw, lRoll;

void setup() {
  size(800, 600);
  oscP5 = new OscP5(this, 9000); // ポート番号をPython側と合わせる
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/controller/left/pos")) {
    lx = msg.get(0).floatValue();
    ly = msg.get(1).floatValue();
    lz = msg.get(2).floatValue();
  }
  else if (msg.checkAddrPattern("/controller/left/rot")) {
    lPitch = msg.get(0).floatValue();
    lYaw   = msg.get(1).floatValue();
    lRoll  = msg.get(2).floatValue();
  }
}

void draw() {
  background(30);
  // lx, ly, lz, lPitch, lYaw, lRoll を使って描画
}
```

### TouchDesigner

1. **OSC In CHOP** を追加
2. `Network Port` を `9000` に設定
3. 受信されたチャンネルを確認：
   - `/controller/left/pos` → `[0]` `[1]` `[2]` で x, y, z
   - `/controller/left/rot` → `[0]` `[1]` `[2]` で Pitch, Yaw, Roll
   - `/controller/left/trigger` → スカラー値

### Max/MSP

```
[udpreceive 9000]
        |
[oscparse]
        |
[route /controller/left/pos /controller/left/rot ...]
```

---

## 起動手順

```powershell
# 1. SteamVRを起動してVIVEを接続

# 2. 仮想環境を有効化
cd C:\Users\kiklab\Projects\vive-osc
.venv\Scripts\activate

# 3. スクリプトを実行
python vive_osc_sender.py

# 4. 停止
Ctrl+C
```

---

## 別PCへの送信

受信側が別PCの場合は `vive_osc_sender.py` の送信先IPを変更する：

```python
# 変更前
client = udp_client.SimpleUDPClient("127.0.0.1", 9000)

# 変更後（受信PCのIPアドレスに変更）
client = udp_client.SimpleUDPClient("192.168.1.XX", 9000)
```

受信側PCのIPアドレスはPowerShellで確認：

```powershell
ipconfig
# IPv4 アドレスを確認
```

---

## 依存ライブラリ

```
openvr==2.12.1401
python-osc
```

インストール：

```powershell
pip install openvr python-osc
```

構成の記録：

```powershell
pip freeze > requirements.txt
```

再現：

```powershell
pip install -r requirements.txt
```
