/*
For using MCP9600 with the Azure Sphere
*/

#include "mcp9600.h" 

CMcp9600::CMcp9600(I2C_InterfaceId id, I2C_DeviceAddress address) 
	: _id(id)
	, _address(address)
{

}
// Private:
/*
Write 8 bits to the I2C Address
*/
bool CMcp9600::write8(int fd, I2C_DeviceAddress address, uint8_t reg, uint8_t value)
{
	uint8_t valueToWrite[2];
	valueToWrite[0] = reg;
	valueToWrite[1] = value;

	ssize_t transferredBytes = I2CMaster_Write(fd, address, valueToWrite, sizeof(valueToWrite));
	if (!CMcp9600::CheckTransferSize("I2CMaster_Write", sizeof(valueToWrite), transferredBytes))
	{
		Log_Debug("Write8 Failed\n");
		return false;
	}
	return true;
}

/*
Read 8 bits from the I2C Address
*/
uint8_t CMcp9600::read8(int fd, I2C_DeviceAddress address, uint8_t reg)
{
	uint8_t value = 0xFF;
	ssize_t transferredBytes = I2CMaster_WriteThenRead(fd, address, &reg, sizeof(reg), &value, sizeof(value));
	if (!CMcp9600::CheckTransferSize("I2CMaster_Read", sizeof(reg) + sizeof(value), transferredBytes))
	{
		Log_Debug("Read8 Failed\n");
	}
	return value;
}


/*
Read 16 bits from the I2C Address
*/
uint16_t CMcp9600::read16(int fd, I2C_DeviceAddress address, uint8_t reg)
{
	uint8_t value[2];
	ssize_t transferredBytes = I2CMaster_WriteThenRead(fd, address, &reg, sizeof(reg), value, sizeof(value));
	if (!CMcp9600::CheckTransferSize("I2CMaster_Read", sizeof(reg) + sizeof(value), transferredBytes))
	{
		Log_Debug("Read16 Failed\n");
	}
	uint16_t result = 0x0000;
	result = static_cast<uint16_t>(result | (static_cast<uint16_t>(value[0]) << 8));
	result = static_cast<uint16_t>(result | static_cast<uint16_t>(value[1]));
	return result;
}

/*
Check bits transfered to and from I2C
*/
bool CMcp9600::CheckTransferSize(const char* desc, size_t expectedBytes, ssize_t actualBytes) {
	if (actualBytes < 0) {
		Log_Debug("ERROR: %s: errno=%d (%s)\n", desc, errno, strerror(errno));
		return false;
	}
	if (actualBytes != static_cast<ssize_t>(expectedBytes)) {
		Log_Debug("ERROR: %s: transferred %zd bytes; expected %zd\n", desc, actualBytes,
			expectedBytes);
		return false;
	}
	return true;
}

/*
Didn't do the Job
uint16_t CMcp9600::read16(int fd, I2C_DeviceAddress address, uint8_t reg)
{
	uint16_t value = 0xFFFF;
	ssize_t transferredBytes = I2CMaster_WriteThenRead(fd, address, &reg, sizeof(reg), reinterpret_cast<uint8_t *>(&value), sizeof(value));
	if (!CMcp9600::CheckTransferSize("I2CMaster_Read", sizeof(reg) + sizeof(value), transferredBytes))
	{
		Log_Debug("Read16 Failed\n");
	}
	return value;
}*/

/*
Open and configure the I2C master interface
*/
bool CMcp9600::mcp9600_begin() {
	_fd = I2CMaster_Open(_id);
	if (_fd < 0)
	{
		Log_Debug("ERROR: I2CMaster_Open: errno=%d (%s)\n", errno, strerror(errno), errno);
		return false;
	}
	int result = I2CMaster_SetBusSpeed(_fd, I2C_BUS_SPEED_STANDARD);
	if (result != 0) {
		Log_Debug("ERROR: I2CMaster_SetBusSpeed: errno=%d (%s)\n", errno, strerror(errno));
		return false;
	}
	result = I2CMaster_SetTimeout(_fd, 100);
	if (result != 0) {
		Log_Debug("ERROR: I2CMaster_SetTimeout: errno=%d (%s)\n", errno, strerror(errno));
		return false;
	}
	return true;
}


/*
Set the Thermocouple Type
*/
bool CMcp9600::setThermocoupleType(MCP9600_TYPE type)
{	
	uint8_t dataToWrite = type;
	if (!write8(_fd, _address, MCP9600_REG_SENSOR_CONFIG, dataToWrite))
	{
		return false;
	}
	return true; 
}

MCP9600_TYPE CMcp9600::getThermocoupleType()
{
	return  MCP9600_TYPE_K; 
}

/*
Set Filter Level
*/
bool CMcp9600::setFilterBits(uint8_t bits) {
	uint8_t previousData = read8(_fd, _address, MCP9600_REG_SENSOR_CONFIG);
	uint8_t dataToWrite = (previousData&0xf0)|bits;
	if (!write8(_fd, _address, MCP9600_REG_SENSOR_CONFIG, dataToWrite))
	{
		return false;
	}
	return true;
}

uint8_t CMcp9600::getFilterBits() {
	return 0x4;
}

/*
Set Analogue to Digital Converter Resolution
*/
bool CMcp9600::setAdcResolution(MCP9600_ADC_RES res)
{
	uint8_t reg = MCP9600_REG_DEVICE_CONFIG;
	uint8_t previousData = read8(_fd, _address, reg);
	uint8_t dataToWrite = previousData | static_cast<uint8_t>(res & 0x60);
	if (!write8(_fd, _address, reg, dataToWrite))
	{
		return false;
	}
	return true;
}

MCP9600_ADC_RES CMcp9600::getAdcResolution()
{
	return MCP9600_ADC_RES_18;
}


/*
Get Temperature using Hot Junction Themperature Register
*/
float CMcp9600::getTemperature()
{
	float result;
	uint8_t reg = MCP9600_REG_HOT_JUNCTION;
	uint16_t tempBits = read16(_fd, _address, reg);
	result = tempBits;
	result *= 0.0625f;
	return result;
}


CMcp9600::~CMcp9600()
{
	close(_fd);
}