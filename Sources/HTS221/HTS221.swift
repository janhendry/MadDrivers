//=== TSL2591.swift -------------------------------------------------------===//
//
// Copyright (c) MadMachine Limited
// Licensed under MIT License
//
// Authors: Jan Anstipp
// Created: 09/23/2022
//
// See https://madmachine.io for more information
//
//===----------------------------------------------------------------------===//

import SwiftIO

public class HTS221 {
    private let i2c: I2C
    private let serialBusAddress: SerialBusAddress
    lazy private var configuration: Configuration = readConfig()
    
    
    /// Initialize a TMP102 Driver.
    ///
    /// - Parameters:
    ///    - ic2: The I2C interface on the board.
    ///    - serialBusAddress: The serial bus address from the chip.
    public init(_ ic2: I2C,_ serialBusAddress: SerialBusAddress = .x48){
        self.i2c = ic2
        self.serialBusAddress = serialBusAddress
    }
    
    /// Read the temperature.
    /// - Returns: Temperature of the sensor.
    public func readCelcius() -> Double{
        if(configuration.operationMode == .SHUTDOWN){
            var config = configuration.getBytes()
            config[1] = config[1] | (1 << 7)
            
            write(config, to: .Configuration)
            sleep(ms: 26)
        }
        
        return Self.toTemp(configuration.resulution, read(.Temperature))
    }
    
    /// Read the configuration.
    /// - Returns:Configuration of the TMP102.
    public func readConfig() -> Configuration{
        let data = read(.Configuration)
        return Configuration((data[0],data[1]))
    }
    
    /// Set the configuration.
    /// - Parameter configuration:
    public func setConfig(_ configuration: Configuration) {
        write(configuration.getBytes(), to: .Configuration)
        self.configuration = configuration
    }
    
    /// Read the low temparture.
    ///
    /// If the temperature falls below the value, the ALT pin  is not active. Default temperature range is 10°C to 64°C.
    /// - Returns: Low Temperture  of the ALT Pin.
    public func readLowTemperature() -> Double {
        Self.toTemp(configuration.resulution, read(.TemperatureLOW))
    }
    
    /// Set the low temparture.
    ///
    /// If the temperature falls below the value, the ALT pin  is not active. Default temperature range is 10°C to 64°C.
    /// - Returns: Low Temperture  of the ALT Pin.
    public func setLowTemperature(_ lowTemp:Double) {
        write(Self.toData(configuration.resulution, lowTemp), to: .TemperatureLOW)
    }
    
    /// Read the hight temparture.
    ///
    /// If the temperature rises above the value, the ALT pin is active. Default hight temparture is 147°C.
    /// - Returns: Hight temparture for the ALT pin.
    public func readHightTemperature() -> Double{
        Self.toTemp(configuration.resulution,read(.TemperatureHIGH))
    }
    
    /// Set the hight temparture.
    ///
    /// If the temperature rises above the value, the ALT pin is active. Default hight temparture is 147°C.
    /// - Returns: Hight temparture for the CT pin.
    public func setHightTemperature(_ hightTemp: Double){
        write(Self.toData(configuration.resulution, hightTemp), to: .TemperatureHIGH)
    }
    
    /// Read the number of faults.
    /// - Returns: Number of faults.
    public func readNumberOfFaults() -> NumberOfFaults {
        readConfig().numberOfFaults
    }
    
    /// Set the number of faults.
    /// - Parameter numberOfFaults: Number of faults.
    public func setNumberOfFaults(_ numberOfFaults: NumberOfFaults) {
        configuration.numberOfFaults = numberOfFaults
        setConfig(configuration)
    }
    
    /// Read alert status.
    public func readAlert() -> Bool{
        read(.Configuration)[1].isBitSet(5)
    }
    
    /// Read the ALT output polarity.
    ///  - Returns: Output polarity of the ALT pin.
    public func readAlertOutputPolarity() -> AlertOutputPolarity {
        readConfig().alertOutputPolarity
    }
    
    /// Set the ALT output polarity.
    /// - Parameter alertOutputPolarity: Output polarity of the ALT pin.
    public func setAlertOutputPolarity(_ alertOutputPolarity: AlertOutputPolarity){
        configuration.alertOutputPolarity = alertOutputPolarity
        setConfig(configuration)
    }
    
    public func shutdown(){
        configuration.operationMode = .SHUTDOWN
        setConfig(configuration)
    }
    
    public func wakeup(){
        configuration.operationMode = .CONTINUOS
        setConfig(configuration)
    }
}

extension TMP102{
    
    func read(_ registerAddresse: RegisterAddress) -> [UInt8]{
        var buffer: [UInt8] = [0,0]
        i2c.writeRead(registerAddresse.rawValue, into: &buffer, address: serialBusAddress.rawValue)
        return buffer
    }
    
    func write(_ data: [UInt8],to registerAddresse: RegisterAddress) {
        i2c.write([registerAddresse.rawValue]+data, to: serialBusAddress.rawValue)
    }
    
    static func toTemp(_ resulution: Resulution, _ data: [UInt8]) -> Double{
        let dataInt16 = (Int16(data[0]) << 8) | Int16(data[1])
        let isPositiveTemp = dataInt16 >= 0
        
        switch(resulution, isPositiveTemp){
        case (.r_12Bit,true): return Double(dataInt16 >> 4) / 8
        case (.r_12Bit,false): return Double(dataInt16 >> 4 | 0b1 << 15) / 8
        case (.r_13Bit,true): return Double(dataInt16 >> 3) / 16
        case (.r_13Bit,false): return Double(dataInt16 >> 3 | 0b1 << 15) / 16
        }
    }
    
    static func toData(_ resulution: Resulution, _ temp: Double) -> [UInt8]{
        let isPositiveTemp = temp >= 0
        var data:Int16 = 0
        
        switch(resulution, isPositiveTemp){
        case (.r_12Bit,true): data = Int16(temp * 8) << 4
        case (.r_12Bit,false): data = (Int16(temp * 8) << 4) | 0b1 << 15
        case (.r_13Bit,true): data = Int16(temp * 16) << 3
        case (.r_13Bit,false): data = (Int16(temp * 16) << 3) | 0b1 << 15
        }
        
        let uIntData = UInt16(bitPattern: data)
        return [UInt8( uIntData >> 8), UInt8(uIntData & 0x00ff) ]
    }
    
    enum RegisterAddress: UInt8{
        case Temperature = 0
        case Configuration = 1
        case TemperatureLOW = 2
        case TemperatureHIGH = 3
    }
    
    /// Serial bus address of the TMP102
    ///
    /// Like all I2C-compatible devices, the ADT7410 has a 7-bit serial address. The five MSBs of this address for the ADT7410 are set to 10010. Pin A1 set the two LSBs.
    public enum SerialBusAddress: UInt8{
        case x48 = 0x48
        case x49 = 0x49
        case x4A = 0x4A
        case x4B = 0x4B
    }
}

extension UInt8{
    func isBitSet(_ index: Int) -> Bool{
        (self & (1 << index)) != 0
    }
}
