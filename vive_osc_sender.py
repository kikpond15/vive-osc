import openvr
import time
import math
from pythonosc import udp_client

# OSC送信先
client = udp_client.SimpleUDPClient("127.0.0.1", 9000)

vr = openvr.init(openvr.VRApplication_Other)
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

# トラッカーに連番を割り当てるための辞書
tracker_index_map = {}
tracker_counter = [0]

def get_tracker_id(device_i):
    """デバイスインデックスをトラッカー連番（0, 1, 2...）に変換"""
    if device_i not in tracker_index_map:
        tracker_index_map[device_i] = tracker_counter[0]
        tracker_counter[0] += 1
        print(f"[New Tracker] device={device_i} → tracker_id={tracker_index_map[device_i]}")
    return tracker_index_map[device_i]

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
            result, state = vr.getControllerState(i)
            if result:
                trigger = state.rAxis[1].x
                grip    = bool(state.ulButtonPressed & (1 << openvr.k_EButton_Grip))
                menu    = bool(state.ulButtonPressed & (1 << openvr.k_EButton_ApplicationMenu))
                client.send_message(f"/controller/{side}/trigger", trigger)
                client.send_message(f"/controller/{side}/grip",    int(grip))
                client.send_message(f"/controller/{side}/menu",    int(menu))

                client.send_message(f"/controller/{side}/trigger", trigger)
                client.send_message(f"/controller/{side}/grip",    int(grip))
                client.send_message(f"/controller/{side}/menu",    int(menu))

        # VIVEトラッカー
        elif device_class == openvr.TrackedDeviceClass_GenericTracker:
            tid = get_tracker_id(i)
            client.send_message(f"/tracker/{tid}/pos", [x, y, z])
            client.send_message(f"/tracker/{tid}/rot", [pitch, yaw, roll])

    time.sleep(1/60)