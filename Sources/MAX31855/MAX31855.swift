//=== MAX31855.swift --------------------------------------------------------===//
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

class MAX31855{
   
    let spi_i: SPI_I
  
    init(spi:SPI_I){
        spi_i = spi
    }

    /**
        Reads a temperature from the thermocouple.
        @return temperature in degree Celsius
    */
    func readCelsius() -> (internalT:Double,thermocoupleT:Double)? {
        let data: [UInt16] = spi_i.read(count: 2)
        
        
        let fali = (data[1] & 0b111) | (data[0] & 0b1)
        if(fali != 0){
            return nil
        }
        
        
        var internalTemperature  = Double((data[1] & 0b0111_1111_1111_0000) >> 4) * 0.0625
        if (data[1] >> 15) & 0b1 == 1{
            internalTemperature -= 128
        }
        
        
        var thermocoupleTemperature = Double((data[0] & 0b0111_1111_1111_1100) >> 2) * 0.25
        if (data[0] >> 15) & 0b1 == 1 {
            thermocoupleTemperature -= 2048
        }
    
        return (internalTemperature,thermocoupleTemperature)
    }
    
    /**
        Reads a temperature in Kelvin.
        @return temperature in degree Kelvin
    */
    func readKelvin() -> (internalT:Double,thermocoupleT:Double)?{
        if let celcius = readCelsius(){
            return (Temperature.toKelvins(celsius:celcius.internalT),Temperature.toKelvins(celsius:celcius.thermocoupleT))
        }
        return nil
    }

    /**
        Reads a temperature in Fahrenheit.
        @return temperature in degree Fahrenheit
    */

    func readFahrenheit() -> (internalT:Double,thermocoupleT:Double)?{
        if let celcius = readCelsius(){
            return (Temperature.toFahrenheit(celsius:celcius.internalT),Temperature.toFahrenheit(celsius:celcius.thermocoupleT))
        }
        return nil
    }
    
}

