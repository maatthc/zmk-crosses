/*
 * Copyright (c) 2024 ZMK Contributors
 *
 * SPDX-License-Identifier: MIT
 */

#include <string.h>
#include <zephyr/kernel.h>
#include <zephyr/usb/class/usb_hid.h>
#include <zephyr/usb/usb_device.h>
#include <zmk/event_manager.h>
#include <zmk/events/layer_state_changed.h>
#include <zmk/keymap.h>

#define RAW_EPSIZE 32
#define PAYLOAD_MARK 0x90
#define PAYLOAD_BEGIN 24

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

static const struct device *hid_dev;
static bool usb_ready = false;

static void send_layer_report(uint8_t layer) {
  if (hid_dev == NULL || !usb_ready) {
    return;
  }

  uint8_t report[RAW_EPSIZE];
  memset(report, 0x00, RAW_EPSIZE);
  report[PAYLOAD_BEGIN] = PAYLOAD_MARK;
  report[PAYLOAD_BEGIN + 1] = layer;

  int ret = hid_int_ep_write(hid_dev, report, RAW_EPSIZE, NULL);
  if (ret < 0 && ret != -EAGAIN) {
    LOG_ERR("Failed to send layer report: %d", ret);
  }
}

static int layer_status_hid_init(const struct device *dev) {
  hid_dev = device_get_binding("HID_0");
  if (hid_dev == NULL) {
    LOG_WRN("USB HID device not available (may be using Bluetooth)");
    return 0;
  }

  k_sleep(K_MSEC(500));
  usb_ready = true;

  return 0;
}

static int layer_status_hid_event_listener(const zmk_event_t *eh) {
  const struct zmk_layer_state_changed *ev = as_zmk_layer_state_changed(eh);
  if (ev == NULL) {
    return -ENOTSUP;
  }

  uint8_t highest_layer = zmk_keymap_highest_layer_active();
  send_layer_report(highest_layer);

  return 0;
}

ZMK_LISTENER(layer_status_hid, layer_status_hid_event_listener);
ZMK_SUBSCRIPTION(layer_status_hid, zmk_layer_state_changed);

SYS_INIT(layer_status_hid_init, APPLICATION, CONFIG_APPLICATION_INIT_PRIORITY);
