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

public extension HTS221 {
    
    struct Configuration{
        
        /// The operation mode describes in which cycle the temperature is measured by the chip.
        public var operationMode: OperationMode = .CONTINUOS
        /// Describes which reset behavior the CT and INT pins have.
        public var temperatureDetectionMode: TemperatureDetectionMode = .COMPARATOR_MODE
        /// The active polarity of the ALT pin.
        public var alertOutputPolarity: AlertOutputPolarity = .ACTIVE_LOW
        /// The number of undertemperature/overtemperature faults that can occur before setting the ALT  pin.
        public var numberOfFaults: NumberOfFaults = .ONE
        /// The sensor store the temperature in 13 bit or 16 bit resulution.
        public var resulution: Resulution = .r_13Bit
        /// 
        public var conversionRate: ConversionRate = ._4hz
        
        /// Initialize default configuration of a TMP102.
        public init(){}
        
        /// Initialize configuration of a TMP102..
        init(_ configByte: (UInt8,UInt8)){
            setByte(configByte)
        }
        
        mutating func setByte(_ configBytes: (UInt8,UInt8)){
            operationMode = .init(rawValue: configBytes.0 & 0b1)!
            temperatureDetectionMode = .init(rawValue: configBytes.0 & 0b10)!
            alertOutputPolarity = .init(rawValue: configBytes.0 & 0b100)!
            numberOfFaults = .init(rawValue: configBytes.0 & 0b11000)!
            
            resulution = .init(rawValue: configBytes.1 & 0b10000)!
            conversionRate = .init(rawValue: configBytes.1 & 0b11000000)!
            
        }
        
        func getBytes() -> [UInt8]{
            [ operationMode.rawValue | temperatureDetectionMode.rawValue | alertOutputPolarity.rawValue | numberOfFaults.rawValue ,
              resulution.rawValue | conversionRate.rawValue ]
        }
    }
    
    
    /// The operation mode describes in which cycle the temperature is measured by the chip.
    enum OperationMode: UInt8{
        
        /// Performs an automatic conversion sequence.
        case CONTINUOS = 0b0
        
        /// Shutdown mode conserves maximum power by turning off all of the device's circuits except the serial port, reducing power consumption to typically less than 0.5A. The device shuts down when   the temperature conversion is completed.
        case SHUTDOWN = 0b1
    }
    
    /// Describes which reset behavior the ALT pin have.
    enum TemperatureDetectionMode: UInt8{
        /// In Comparator mode, the Alert pin is activated when the temperature equals or exceeds the T(HIGH) and remains active until the temperature falls below the T(LOW).
        case COMPARATOR_MODE = 0b0
        
        /// In Interrupt mode, the Alert pin is activated when the temperature exceeds T(HIGH) or goes below T(LOW) registers. The Alert pin is cleared when the host controller reads the temperature register.
        case INTERRUPT_MODE = 0b10
    }
    
    /// The active polarity of the alert pin.
    enum AlertOutputPolarity: UInt8{
        case ACTIVE_LOW = 0b0
        case ACTIVE_HIGH = 0b100
    }
    
    /// The number of undertemperature/overtemperature faults that can occur before setting the ALT pin. This helps to avoid false triggering due0b to temperature noise.
    enum NumberOfFaults: UInt8{
        case ONE = 0b0
        case TWO = 0b01000
        case THREE = 0b10000
        case FOUR = 0b11000
    }
    
    /// The sensor store the temperature in 11 bit or 12 bit resulution.
    enum Resulution: UInt8{
        /// Sign bit + 11 bits gives a temperature resolution of 0.125°C.
        case r_12Bit = 0b0
        /// Sign bit + 12 bits gives a temperature resolution of 0.0625°C.
        case r_13Bit = 0b1000
    }
    
    /// The conversion rate at which the sensor update the temperature
    enum ConversionRate : UInt8{
        case _0_25hz = 0b0
        case _1Hz = 0b1000000
        case _4hz = 0b10000000
        case _8hz = 0b11000000
    }
}
