//
//  File.swift
//  
//
//  Created by Jan Anstipp on 07.09.22.
//

import SwiftIO

public extension ADT7410 {
    
    struct Configuration{
    
        var numberOfFaults: NumberOfFaults = .ONE
        var ctOutputPolarity: CTOutputPolarity = .ACTIVE_LOW
        var intOutputPolarity: INTOutputPolarity = .ACTIVE_LOW
        var temperatureDetectionMode: TemperatureDetectionMode = .COMPARATOR_MODE
        var operationMode: OperationMode = .CONTINUOS
        var resulution: Resulution = ._13Bit
        
        init(){}
        
        init(_ configByte: UInt8){
            setConfigByte(configByte)
        }
        
        mutating func setConfigByte(_ configByte: UInt8){
            numberOfFaults = .init(rawValue: configByte & 0b11)!
            ctOutputPolarity = .init(rawValue: configByte & 0b100)!
            intOutputPolarity = .init(rawValue: configByte & 0b1000)!
            temperatureDetectionMode = .init(rawValue: configByte & 0b10000)!
            operationMode = .init(rawValue: configByte & 0b1100000)!
            resulution = .init(rawValue: configByte & 0b10000000)!
        }
        
        func getConfigByte() -> UInt8{
            return ( numberOfFaults.rawValue |
                     ctOutputPolarity.rawValue |
                     intOutputPolarity.rawValue |
                     temperatureDetectionMode.rawValue |
                     operationMode.rawValue |
                     resulution.rawValue )
        }
    }
    
    /**
     The number of undertemperature/overtemperature faults that can occur before setting the INT and CT pins. This helps to avoid false triggering due0b to temperature noise.
     */
    enum NumberOfFaults: UInt8{
        case ONE = 0b0
        case TWO = 0b1
        case THREE = 0b10
        case FOUR = 0b11
    }

    enum CTOutputPolarity: UInt8{
        case ACTIVE_LOW = 0b0
        case ACTIVE_HIGH = 0b100
    }
    
    enum INTOutputPolarity: UInt8{
        case ACTIVE_LOW = 0b0
        case ACTIVE_HIGH = 0b1000
    }
    
    enum TemperatureDetectionMode: UInt8{
        case COMPARATOR_MODE = 0b0
        case INTERRUPT_MODE = 0b10000
    }
    
    enum OperationMode: UInt8{
        
        case CONTINUOS = 0b0        /// When one conversion is finished, the ADT7410 starts another.
        
        /**
         One shot mode:
         When one-shot mode is enabled, the ADT7410 immediately completes a conversion and then goes into shutdown mode. The one-shot mode is useful when one of the circuit design priorities is to reduce power consumption.
         After writing to the operation mode bits, wait at least 240 ms before reading back the temperature from the temperature value register. This delay ensures that the ADT7410 has adequate time to power up and complete a conversion.
         */
        case ONE_SHOT = 0b100000    /// Conversion time is typically 240 ms.
        
        /**
         Sps mode:
         The ADT7410 measures/update the temperature once every second.  This operational mode reduces the average current consumption.
         */
        case SPS = 0b1000000        /// The ADT7410 measures/update the temperature once every second.
        
        /**
         Shutdown mode:
         The entire IC is shut down and no further conversions are initiated until the ADT7410 is taken out of shutdown mode.The conversion result from the last conversion prior to shutdown can still be read from the ADT7410 even when it is in shutdown mode. The ADT7410 typically takes 1 ms (with a 0.1 μF decoupling capacitor) to come out of shutdown mode.  When the part is taken out of shutdown mode, the internal clock is started and a conversion is initiated.
         */
        case SHUTDOWN = 0b1100000   /// All circuitry except interface circuitry is powered down.
    }
    
    enum Resulution: UInt8{
        case _13Bit = 0b0           /// Sign bit + 12 bits gives a temperature resolution of 0.0625°C.
        case _16Bit = 0b10000000    /// Sign bit + 15 bits gives a temperature resolution of 0.0078°C.
    }
}
