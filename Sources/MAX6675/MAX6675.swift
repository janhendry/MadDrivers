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

class MAX6675{
    let spi_i: SPI_I
  
    init(spi:SPI_I){
        spi_i = spi
        if(spi_i.getSpeed() > 10_000_000){
            spi_i.setSpeed(10_000_000)
        }
    }

    /**
        Reads a temperature from the thermocouple.
        @return temperature in degree Celsius
    */
    func readCelsius() -> Double?{
        let data: UInt16 = spi_i.read(count: 1)[0]
        
        if ((data & 0b100) != 0) {
            return nil
        }

        return Double(data >> 3) * 0.25
    }

    /**
        Reads a temperature in Kelvin.
        @return temperature in degree Kelvin
    */
    func readKelvin() -> Double?{
        if let celcius = readCelsius(){
            return Temperature.toKelvins(celsius:celcius)
        }
        return nil
    }

    /**
        Reads a temperature in Fahrenheit.
        @return temperature in degree Fahrenheit
    */

    func readFahrenheit() -> Double?{
        if let celcius = readCelsius(){
            return Temperature.toFahrenheit(celsius:celcius)
        }
        return nil
    }
    
}

