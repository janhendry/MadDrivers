//=== MAX6675.swift --------------------------------------------------------===//
//
// Copyright (c) MadMachine Limited
// Licensed under MIT License
//
// Authors: Jan Anstipp
// Created: 06/16/2022
//
// See https://madmachine.io for more information
//
//===----------------------------------------------------------------------===//

import SwiftIO

let themocoupleInputBit: UInt8 = 0b100

public class MAX6675{
    let spi: SPI
    
    
    public init(spi:SPI){
        self.spi = spi
    }
    
    /// Reads a temperature from the thermocouple. if the input of the themocouple is open, nul is returned.
    /// - Returns: Temperature in degree Celsius. if the input of the themocouple is open, nul is returned
    public func readCelsius() -> Double?{
        var buffer: [UInt8] = [0,0]
        spi.read(into: &buffer)
        
        if (buffer[1] & themocoupleInputBit) == themocoupleInputBit {
            print("Fail: themocouple input is open")
            return nil
        }
        
        return toTemparture(buffer)
    }
    
    /// Checks if the themocouple input of pins T+ and T- is open.
    /// - Returns: Is themocouple input open.
    public func isThemocoupleInputOpen() -> Bool{
        var buffer: [UInt8] = [0,0]
        spi.read(into: &buffer)
        
        return (buffer[1] & themocoupleInputBit) == themocoupleInputBit
    }
    
}


extension MAX6675{
    func toTemparture(_ data: [UInt8]) -> Double{
        let uint16 = UInt16(data[0]) << 5 | UInt16(data[1]) >> 3
        return Double(uint16) * 0.25
    }
}


