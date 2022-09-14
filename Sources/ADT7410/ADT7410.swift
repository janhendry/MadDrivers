//
//  File 2.swift
//  
//
//  Created by Jan Anstipp on 07.09.22.
//

import SwiftIO

public class ADT7410{
    
    private let i2c: I2C
    private let serialBusAddress: SerialBusAddress
    lazy private var configuration: Configuration = readConfig()
    
    init(_ ic2: I2C,_ serialBusAddress: SerialBusAddress = ._00){
        self.i2c = ic2
        self.serialBusAddress = serialBusAddress
    }
    
    // return Temp in Celcius
    func readCelcius() -> Double{
        toTemp(read(.TEMP_MSB,2))
    }
    
    func readStatus() -> UInt8{
        read(.STATUS)
    }
    
    func readId() -> UInt8{
        read(.ID)
    }
    
    func set0perationMode(_ mode: OperationMode){
        configuration.operationMode = mode
        write([configuration.getConfigByte()], to: .CONFIG)
    }
    
    func setNumberOfFaults(_ numberOfFaults: NumberOfFaults) {
        configuration.numberOfFaults = numberOfFaults
        write([configuration.getConfigByte()],to: .CONFIG)
    }

    func setCTOutputPolarity(_ ctOutputPolarity: CTOutputPolarity){
        configuration.ctOutputPolarity = ctOutputPolarity
        write([configuration.getConfigByte()],to: .CONFIG)
    }
    
    func setINTOutputPolarity(_ intOutputPolarity: INTOutputPolarity){
        configuration.intOutputPolarity = intOutputPolarity
        write([configuration.getConfigByte()],to: .CONFIG)
    }
    
    func setTemperatureDetectionMode(_ temperatureDetectionMode: TemperatureDetectionMode){
        configuration.temperatureDetectionMode = temperatureDetectionMode
        write([configuration.getConfigByte()],to: .CONFIG)
    }
    /**
     Default temp hight  64°C
     */
    func setSetPointHight(tempature: Double){
        write(toData(tempature), to: .SETPOINT_TEMP_HIGH_MSB)
    }
    
    /**
     Default temp low  10°C
     */
    func setSetPointLow(tempature: Double){
        write(toData(tempature), to: .SETPOINT_TEMP_LOW_MSB)
    }

    /**
     Default temp crit  147°C
     */
    func setSetpointCritical(tempature: Double){
        write(toData(tempature), to: .SETPOINT_TEMP_CRIT_MSB)
    }

    /**
     Default temp hyst 5°C
     */
    func setSetpointHyst(tempature: Double){
        write(toData(tempature), to: .SETPOINT_TEMP_CRIT_MSB)
    }
    
    /**
     Reset the settings to the default values. Will not reset the entire I2C bus.The ADT7410 does not respond to the I2C bus commands (do not acknowledge) during the default values upload for approximately 200 μs.
     */
    func reset(){
        write([], to: .RESET)
        sleep(ms: 1) // TODO sleep for 200 μs
    }
    
    func readConfig() -> Configuration{
        Configuration(read(.CONFIG))
    }
    
    func setConfig(_ configuration: Configuration) {
        write([configuration.getConfigByte()], to: .CONFIG)
        self.configuration = configuration
    }
}

extension ADT7410 {

    private func read(_ registerAddresse: RegisterAddress) -> UInt8{
        read(registerAddresse,1)[0]
    }
    
    private func read(_ registerAddresse: RegisterAddress,_ registerSize: Int) -> [UInt8]{
        i2c.writeRead(registerAddresse.rawValue, readCount: registerSize, address: serialBusAddress.rawValue)
    }
    
    private func write(_ data: [UInt8],to registerAddresse: RegisterAddress) {
        i2c.write(data, to: registerAddresse.rawValue)
    }
    
    private func toTemp(_ data: [UInt8]) -> Double{
        let dataInt16 = data.withUnsafeBytes { $0.load(as: Int16.self) }
        let isPositiveTemp = dataInt16 >= 0
        
        switch(configuration.resulution, isPositiveTemp){
        case (._13Bit,true): return Double(dataInt16 >> 3) / 16
        case (._13Bit,false): return Double(dataInt16 >> 3 | 0b1 << 15) / 16
        case (._16Bit,_ ): return Double(dataInt16) / 128
        }
    }

    private func toData(_ temp: Double) -> [UInt8]{
        let isPositiveTemp = temp >= 0
        var data:Int16 = 0
        
        switch(configuration.resulution, isPositiveTemp){
        case (._13Bit,true): data = Int16(temp * 16) << 3
        case (._13Bit,false): data = (Int16(temp * 16) << 3) | 0b1 << 15
        case (._16Bit,_): data = Int16(temp * 128.0)
        }
        
        return [UInt8(data >> 8), UInt8(data & 0x00ff)]
    }
    
    enum SerialBusAddress: UInt8{
        case _00 = 0b10010000
        case _01 = 0b10010010
        case _10 = 0b10010100
        case _11 = 0b10010110
    }

    enum RegisterAddress: UInt8{
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
        case ID                     = 0x0B  /// Manufacturer identification
        case RESET                  = 0x2F
    }
}
