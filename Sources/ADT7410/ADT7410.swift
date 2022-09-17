//=== ADT7410.swift -------------------------------------------------------===//
//
// Copyright (c) MadMachine Limited
// Licensed under MIT License
//
// Authors: Jan Anstipp
// Created: 16/09/2022
//
// See https://madmachine.io for more information
//
//===----------------------------------------------------------------------===//

import SwiftIO

public class ADT7410{
    
    private let i2c: I2C
    private let serialBusAddress: SerialBusAddress
    lazy private var configuration: Configuration = readConfig()
    
    public init(_ ic2: I2C,_ serialBusAddress: SerialBusAddress = ._00){
        self.i2c = ic2
        self.serialBusAddress = serialBusAddress
    }
    
    /**
     Read the temperature from the sensor.
     */
    public func readCelcius() -> Double{
        toTemp(read(.TEMP_MSB,2))
    }
    
    /**
     Read the status from the sensor.
     */
    public func readStatus() -> Status{
        Status(read(.STATUS))
    }
    
    /**
     Read the temparture range for the INT pin. If the temperature falls below the min value or rises above the max value, the INT pin is triggered. Default temperature range is 10°C to 64°C.
     */
    public func readIntTemperatureRange() -> (minTemp: Double,maxTemp: Double) {
        (toTemp(read(.SETPOINT_TEMP_LOW_MSB,2)), toTemp(read(.SETPOINT_TEMP_HIGH_MSB,2)))
    }

    /**
     Write the critical temparture for the CT pin. If the temperature rises above the value, the CT pin is triggered. Default critical temparture is 147°C.
     */
    public func readCTCriticalTemperature() -> Double{
        toTemp(read(.SETPOINT_TEMP_CRIT_MSB,2))
    }

    /**
     Write the temperature hysteresis value for the THIGH, TLOW, and TCRIT temperature limits. The value is subtracted from the THIGH and TCRIT values and added to the TLOW value to implement hysteresis.  Default temperature hyst is 5°C.
     */
    public func readHyst() -> UInt8{
        read(.SETPOINT_TEMP_HYST)
    }
    
    /**
     Read the config from the sensor.
     */
    public func readConfig() -> Configuration{
        Configuration(read(.CONFIG))
    }
    
    /**
     Read the 8-bit id Register. The manufacturer ID in Bit 3 to Bit 7 and the silicon revision in Bit 0 to Bit 2.
     */
    public func readId() -> ChipID{
        ChipID(read(.ID))
    }
    
    /**
     Write the operation mode in the configuration register.
     */
    public func set0perationMode(_ mode: OperationMode){
        configuration.operationMode = mode
        write([configuration.getByte()], to: .CONFIG)
    }
    
    /**
     Write the number of faults in the configuration register.
     */
    public func setNumberOfFaults(_ numberOfFaults: NumberOfFaults) {
        configuration.numberOfFaults = numberOfFaults
        write([configuration.getByte()],to: .CONFIG)
    }

    /**
     Write the CT output polarity in the configuration register.
     */
    public func setCTOutputPolarity(_ ctOutputPolarity: CTOutputPolarity){
        configuration.ctOutputPolarity = ctOutputPolarity
        write([configuration.getByte()],to: .CONFIG)
    }
    
    /**
     Write the INT output polarity in the configuration register.
     */
    public func setINTOutputPolarity(_ intOutputPolarity: INTOutputPolarity){
        configuration.intOutputPolarity = intOutputPolarity
        write([configuration.getByte()],to: .CONFIG)
    }
    
    /**
     Write the temperature detection mode in the configuration register.
     */
    public func setTemperatureDetectionMode(_ temperatureDetectionMode: TemperatureDetectionMode){
        configuration.temperatureDetectionMode = temperatureDetectionMode
        write([configuration.getByte()],to: .CONFIG)
    }
    
    /**
     Write the temparture range for the INT pin. If the temperature falls below the min value or rises above the max value, the INT pin is triggered. Default temperature range is 10°C to 64°C.
     */
    public func setIntTemperatureRange(min minTemp: Double, max maxTemp: Double ){
        write(toData(minTemp), to: .SETPOINT_TEMP_LOW_MSB)
        write(toData(maxTemp), to: .SETPOINT_TEMP_HIGH_MSB)
    }

    /**
     Write the critical temparture for the CT pin. If the temperature rises above the value, the CT pin is triggered. Default critical temparture is 147°C.
     */
    public func setCTCriticalTemperature(tempature: Double){
        write(toData(tempature), to: .SETPOINT_TEMP_CRIT_MSB)
    }

    /**
     Write the temperature hysteresis value for the THIGH, TLOW, and TCRIT temperature limits. The value is subtracted from the THIGH and TCRIT values and added to the TLOW value to implement hysteresis. allowed values are from 0°C-15°C and default temperature hyst is 5°C.
     */
    public func setHyst(tempature: UInt8){
        write([tempature], to: .SETPOINT_TEMP_HYST)
    }
    
    /**
     Write the configuration to the sensor.
     */
    public func setConfig(_ configuration: Configuration) {
        write([configuration.getByte()], to: .CONFIG)
        self.configuration = configuration
    }
    
    /**
     Reset the settings to the default values. Will not reset the entire I2C bus.The ADT7410 does not respond to the I2C bus commands (do not acknowledge) during the default values upload for approximately 200 μs.
     */
    public func reset(){
        write([], to: .RESET)
        sleep(ms: 1) // TODO sleep for 200 μs
    }
}

extension ADT7410 {

    func read(_ registerAddresse: RegisterAddress) -> UInt8{
        read(registerAddresse,1)[0]
    }
    
    func read(_ registerAddresse: RegisterAddress,_ registerSize: Int) -> [UInt8]{
        i2c.writeRead(registerAddresse.rawValue, readCount: registerSize, address: serialBusAddress.rawValue)
    }
    
    func write(_ data: [UInt8],to registerAddresse: RegisterAddress) {
        i2c.write([registerAddresse.rawValue]+data, to: serialBusAddress.rawValue)
    }
    
    func toTemp(_ data: [UInt8]) -> Double{
        let dataInt16 = (Int16(data[0]) << 8) | Int16(data[1])
        let isPositiveTemp = dataInt16 >= 0
        
        switch(configuration.resulution, isPositiveTemp){
        case (._13Bit,true): return Double(dataInt16 >> 3) / 16
        case (._13Bit,false): return Double(dataInt16 >> 3 | 0b1 << 15) / 16
        case (._16Bit,_ ): return Double(dataInt16) / 128
        }
    }

    func toData(_ temp: Double) -> [UInt8]{
        let isPositiveTemp = temp >= 0
        var data:Int16 = 0
        
        switch(configuration.resulution, isPositiveTemp){
        case (._13Bit,true): data = Int16(temp * 16) << 3
        case (._13Bit,false): data = (Int16(temp * 16) << 3) | 0b1 << 15
        case (._16Bit,_): data = Int16(temp * 128.0)
        }
        
        return [UInt8(data >> 8), UInt8(data & 0x00ff)]
    }
    
    public enum SerialBusAddress: UInt8{
        case _00 = 0x48
        case _01 = 0x49
        case _10 = 0x4A
        case _11 = 0x4B
    }

    public enum RegisterAddress: UInt8{
        case TEMP_MSB               = 0x00
        case TEMP_LSB               = 0x01
        case STATUS                 = 0x02
        case CONFIG                 = 0x03
        case SETPOINT_TEMP_HIGH_MSB = 0x04
        case SETPOINT_TEMP_HIGH_LSB = 0x05
        case SETPOINT_TEMP_LOW_MSB  = 0x06
        case SETPOINT_TEMP_LOW_LSB  = 0x07
        case SETPOINT_TEMP_CRIT_MSB = 0x08
        case SETPOINT_TEMP_CRIT_TSB = 0x09
        case SETPOINT_TEMP_HYST     = 0x0A
        case ID                     = 0x0B
        case RESET                  = 0x2F
    }
    
    /**
     Manufacturer ID in Bit 3 to Bit 7 and the silicon revision in Bit 0 to Bit 2.
     */
    public struct ChipID{
        let manufacturerID: UInt8
        let revision: UInt8
    
        init(_ byte: UInt8){
            manufacturerID = byte >> 3
            revision = byte & 0b111
        }
    }
    
    /**
     Status of the overtemperaure and undertemperature interrupts. It also reflects the status of a temperature conversion operation.
     */
    public struct Status{
        let isTLowInterrupt: Bool
        let isTHightInterrupt: Bool
        let isTCritInterrupt: Bool
        let isWriteTemperaure: Bool
        
        init(_ byte: UInt8){
            isTLowInterrupt = byte.isBitSet(4)
            isTHightInterrupt = byte.isBitSet(5)
            isTCritInterrupt = byte.isBitSet(6)
            isWriteTemperaure = byte.isBitSet(7)
        }
    }
}
