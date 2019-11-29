#include <errno.h>
#include <string.h>
#include <time.h>
#include <applibs/log.h>
#include "../../mcp9600.h"

extern "C" void __cxa_pure_virtual() {
  while (1)
    ;
}

float toFarenheit(float c) {
  float f;
  f = c * 1.8f + 32;
  return f;
}

int main(void) {
  bool quit = false;
  Log_Debug("Starting Thermometer\n");

  const struct timespec sleep1s = {1, 0};

  CMcp9600 tempSensor(0, MCP9600_ADDR);
  if (!tempSensor.mcp9600_begin()) {
    Log_Debug("Temp Sensor Failed to start!\n");
    quit = true;
  }

  while (!quit) {
    float temperature = tempSensor.getTemperature();
    Log_Debug("Raw Temperature(C): %f\n", temperature);
    Log_Debug("Tempreture(F): %f\n", toFarenheit(temperature));
    nanosleep(&sleep1s, nullptr);
  }

  return 0;
}