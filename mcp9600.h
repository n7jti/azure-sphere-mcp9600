/* Copyright (c) 2019 Alan Ludwig. All rights reserved.
   Licensed under the MIT License.  See License.txt */

#pragma once

#include <inttypes.h>
#include <stdint.h>
#include <stdbool.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

#define I2C_STRUCTS_VERSION 0
#include <applibs\i2c.h>
#include <applibs\log.h>

// Constants from MCP9600 datasheet:
// http://ww1.microchip.com/downloads/en/DeviceDoc/MCP9600-Family-Data-Sheet-20005426E.pdf

// cSpell:ignore HYST, TALERT, DEVICEID

constexpr uint8_t MCP9600_ADDR = 0x67;
constexpr uint8_t MCP9600_REG_HOT_JUNCTION = 0x00;
constexpr uint8_t MCP9600_REG_TEMP_DELTA = 0x01;
constexpr uint8_t MCP9600_REG_COLD_JUNCTION = 0x02;
constexpr uint8_t MCP9600_REG_RAW_ADC = 0x03;
constexpr uint8_t MCP9600_REG_STATUS = 0x04;
constexpr uint8_t MCP9600_REG_SENSOR_CONFIG = 0x05;
constexpr uint8_t MCP9600_REG_DEVICE_CONFIG = 0x06;
constexpr uint8_t MCP9600_REG_ALERT_1_CONFIG = 0x08;
constexpr uint8_t MCP9600_REG_ALERT_2_CONFIG = 0x09;
constexpr uint8_t MCP9600_REG_ALERT_3_CONFIG = 0x0A;
constexpr uint8_t MCP9600_REG_ALERT_4_CONFIG = 0x0B;
constexpr uint8_t MCP9600_REG_ALERT_1_HYST = 0x0C;
constexpr uint8_t MCP9600_REG_ALERT_2_HYST = 0x0D;
constexpr uint8_t MCP9600_REG_ALERT_3_HYST = 0x0E;
constexpr uint8_t MCP9600_REG_ALERT_4_HYST = 0x0F;
constexpr uint8_t MCP9600_REG_TALERT_1 = 0x10;
constexpr uint8_t MCP9600_REG_TALERT_2 = 0x11;
constexpr uint8_t MCP9600_REG_TALERT_3 = 0x12;
constexpr uint8_t MCP9600_REG_TALERT_4 = 0x13;
constexpr uint8_t MCP9600_REG_DEVICEID = 0x20;

enum MCP9600_TYPE : uint8_t {
  MCP9600_TYPE_K = 0x0 << 4,
  MCP9600_TYPE_J = 0x1 << 4,
  MCP9600_TYPE_T = 0x2 << 4,
  MCP9600_TYPE_N = 0x3 << 4,
  MCP9600_TYPE_S = 0x4 << 4,
  MCP9600_TYPE_E = 0x5 << 4,
  MCP9600_TYPE_B = 0x6 << 4,
  MCP9600_TYPE_R = 0x7 << 4
};

enum MCP9600_ADC_RES {
  MCP9600_ADC_RES_18 = 0 << 5,
  MCP9600_ADC_RES_16 = 1 << 5,
  MCP9600_ADC_RES_14 = 2 << 5,
  MCP9600_ADC_RES_12 = 3 << 5
};

class CMcp9600 {
public:
  CMcp9600(I2C_InterfaceId id, I2C_DeviceAddress address);
  bool mcp9600_begin();
  bool setThermocoupleType(MCP9600_TYPE type);
  MCP9600_TYPE getThermocoupleType() const;
  bool setFilterCoefficients(uint8_t bits);
  uint8_t getFilterCoefficients() const;
  bool setAdcResolution(MCP9600_ADC_RES res);
  MCP9600_ADC_RES getAdcResolution() const;
  float getTemperature() const;
  ~CMcp9600();

private:
  I2C_InterfaceId _id;
  I2C_DeviceAddress _address;
  int _fd;

  static bool CheckTransferSize(const char *desc, size_t expectedBytes,
                                ssize_t actualBytes);
  static bool write8(int fd, I2C_DeviceAddress address, uint8_t reg,
                     uint8_t value);
  static uint8_t read8(int fd, I2C_DeviceAddress address, uint8_t reg);
  static uint16_t read16(int fd, I2C_DeviceAddress address, uint8_t reg);
};